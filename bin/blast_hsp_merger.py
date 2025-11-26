#!/usr/bin/env python3
# -*- coding: utf-8 -*-


"""
Script for merging HSPs per subject given a set of constriants such as amplicon size, standness and overlap.
1- Parse XML
2- Group HSP in merging sets
3- Merge HSP and recalculate metrics
4- Write as a usual BLAST result table

Heavy lifting is done in the group_hsps function to determine wich hits can be grouped.
Metrics recalculation is done in the merging function, only where merging occurs.
"""

from pathlib import Path
import argparse
import numpy as np
import xml.etree.ElementTree as ET


# Columns to output
BLASTCOLS = ["qseqid", "sseqid", "evalue", "pident", "bitscore", "sacc", "staxid", "length", "mismatch", "gaps", "sscinames"]


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--xml", help="path to BLAST XML")
parser.add_argument("--output", help="Name of output file")
parser.add_argument("--qcov_hsp", type=float, help="Minimal query coverage")
parser.add_argument("--min_amplicon_size", type=int, help="Minimal amplicon size")
parser.add_argument("--max_amplicon_size", type=int, help="MMaximal amplicon size")


args = parser.parse_args()


def inner_gaps(hsps):
    """calculate number of inter-HSP gaps for a group of non-overlapping HSPs"""
    sorted_hsps = sorted(hsps, key=lambda h: min(h["qstart"], h["qend"]))
    inner_gaps = 0
    for i in range(len(sorted_hsps) - 1):
        gap = sorted_hsps[i+1]["sstart"] - sorted_hsps[i]["send"]
        if gap > 0:
            inner_gaps += gap
    return inner_gaps


def parse_hsp(e, sinfo):
    """Parses XML into a python dict"""
    return {
        "qseqid": sinfo["qseqid"],
        "sseqid": sinfo["sseqid"],
        "sacc": sinfo["sacc"],
        "staxid": sinfo["staxid"],
        "score": int(e.find('.//ns:score', ns).text),
        "evalue": float(e.find('.//ns:evalue', ns).text),
        "pident": round(100 * int(e.find('.//ns:identity', ns).text) / int(e.find('.//ns:align-len', ns).text), 3),  # in percent!
        "bitscore": round(float(e.find('.//ns:bit-score', ns).text), 0),
        "length": int(e.find('.//ns:align-len', ns).text),
        "mismatch": int(e.find('.//ns:align-len', ns).text) - int(e.find('.//ns:identity', ns).text) - int(e.find('.//ns:gaps', ns).text),
        "gaps": int(e.find('.//ns:gaps', ns).text),
        "sscinames": sinfo["sscinames"],
        "qcov": round(100 * int(e.find('.//ns:align-len', ns).text) / sinfo["qsize"], 2),  # in percent !
        "qstart": int(e.find('.//ns:query-from', ns).text),
        "qend": int(e.find('.//ns:query-to', ns).text),
        "sstart": int(e.find('.//ns:hit-from', ns).text),
        "send": int(e.find('.//ns:hit-to', ns).text),
        "strand_q": e.find('.//ns:query-strand', ns).text,
        "strand_s": e.find('.//ns:hit-strand', ns).text,
    }


def merging(hsps, sinfo):
    """Merging HSP groups"""
    if len(hsps) == 1:
        return hsps[0]
    if len(hsps) == 0:
        return []

    # Recalculate metrics
    # E-value recalculation here assumes biological linkage of the alignemnts (realistic withing the amplicon_size bounds)
    # recalculation for non linked sequences should use summation or joint probability.
    length = sum(h["length"] for h in hsps)
    pident = sum(h["pident"] * h["length"] for h in hsps) / length
    score = sum(h["score"] for h in hsps)
    bitscore = (score * sinfo["lambd"] - np.log(sinfo["kappa"])) / np.log(2)
    evalue = sinfo["qsize"] * sinfo["dbsize"] / 2**bitscore
    gaps = sum(h["gaps"] for h in hsps) + inner_gaps(hsps)
    mismatch = sum(h["mismatch"] for h in hsps)
    qcov_hsp = sum(h["qcov"] for h in hsps)

    return {
        "qseqid": sinfo["qseqid"],
        "sseqid": sinfo["sseqid"],
        "sacc": sinfo["sacc"],
        "staxid": sinfo["staxid"],
        "score": score,
        "evalue": evalue,
        "pident": round(pident, 3),
        "bitscore": round(bitscore, 0),
        "length": length,
        "mismatch": mismatch,
        "gaps": gaps,
        "sscinames": sinfo["sscinames"],
        "qcov": round(qcov_hsp, 2),
    }


def group_hsps(hsps, min_amplicon_size, max_amplicon_size):
    """
    Find groups of biologically linked HSP to merge.
    HSPs grouping is based on strandness, (non-)overlap and distance constraints.
    hsps is a list of dict
    Return list of HSP groups as lists
    """
    # if no or only one HSP there is nothing to do
    if not hsps:
        return []

    # normalize query coordinates
    def q_min(h): return min(h["qstart"], h["qend"])
    def q_max(h): return max(h["qstart"], h["qend"])

    # Split by strand
    strand_groups = {}
    for h in hsps:
        key = (h["strand_q"], h["strand_s"])
        strand_groups.setdefault(key, []).append(h)

    all_groups = []

    for (strand_q, strand_s), strand_hsps in strand_groups.items():
        # sort by start pos
        strand_hsps.sort(key=lambda h: q_min(h))

        current_group = [strand_hsps[0]]

        # Track group's current outer span for efficient checks
        current_min = q_min(strand_hsps[0])
        current_max = q_max(strand_hsps[0])

        for hsp in strand_hsps[1:]:
            this_min = q_min(hsp)
            this_max = q_max(hsp)
            gap = this_min - current_max
            overlap = gap < 0

            # Compute hypothetical amplicon span if we add this HSP
            candidate_min = min(current_min, this_min)
            candidate_max = max(current_max, this_max)
            candidate_span = candidate_max - candidate_min

            # Decide whether adding is acceptable
            # It is probably overkill but it handles any number of HSPs by checking the min amplicon size only after another condition failed
            if not overlap and candidate_span <= max_amplicon_size:
                # Still within limits, keep adding
                current_group.append(hsp)
                current_max = candidate_max
            else:
                # Adding this HSP would break the span or overlap constraint, finalize
                final_span = current_max - current_min
                if final_span >= min_amplicon_size:
                    all_groups.append(current_group)

                # Start a new group
                current_group = [hsp]
                current_min = this_min
                current_max = this_max

        # Finalize last open group
        final_span = current_max - current_min
        if final_span >= min_amplicon_size:
            all_groups.append(current_group)

    return all_groups


def main(xml, output, qcov_hsp, min_amplicon_size, max_amplicon_size):
    # Failure to parse means the file is either empty or something is seriously wron. Break here.
    try:
        tree = ET.parse(xml)
    except ET.ParseError:
        Path(output).touch()
        return

    root = tree.getroot()

    hits = []

    # Namespace
    global ns
    ns = {'ns': 'http://www.ncbi.nlm.nih.gov'}

    # Getting search info from query level
    for blast_output in root.findall('.//ns:BlastOutput2', ns):
        qseqid = blast_output.find('.//ns:query-title', ns).text
        qsize = int(blast_output.find('.//ns:query-len', ns).text)
        kappa = float(blast_output.find('.//ns:kappa', ns).text)
        lambd = float(blast_output.find('.//ns:lambda', ns).text)
        dbsize = int(blast_output.find('.//ns:db-len', ns).text)

        # within each query, iterating over subjects
        for hit in blast_output.findall('.//ns:Hit', ns):
            sinfo = {
                "qseqid": qseqid,
                "qsize": qsize,
                "kappa": kappa,
                "lambd": lambd,
                "dbsize": dbsize,
                "sseqid": hit.find('.//ns:id', ns).text,
                "sacc": hit.find('.//ns:accession', ns).text,
                "staxid": hit.find('.//ns:taxid', ns).text,
                "sscinames": hit.find('.//ns:sciname', ns).text,
            }

            hsps = hit.findall('.//ns:Hsp', ns)

            parsed_hsps = [parse_hsp(e, sinfo) for e in hsps]

            groups = group_hsps(parsed_hsps, min_amplicon_size, max_amplicon_size)

            # Merge and append each group
            for g in groups:
                merged = merging(g, sinfo)
                hits.append(merged)

    # Dump to text
    with open(output, "w") as fi:
        for e in hits:
            if e["qcov"] >= qcov_hsp:
                fi.write("\t".join([str(e[key]) for key in BLASTCOLS]))
                fi.write("\n")


if __name__ == '__main__':
    main(args.xml, args.output, args.qcov_hsp, args.min_amplicon_size, args.max_amplicon_size)
