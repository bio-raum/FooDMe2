#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import numpy as np
import xml.etree.ElementTree as ET


BLASTCOLS = ["qseqid", "sseqid", "evalue", "pident", "bitscore", "sacc", "staxid", "length", "mismatch", "gaps", "sscinames", "qcov_hsp"]  # qcvo_hsp not in report


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--xml", help="path to BLAST XML")
parser.add_argument("--output", help="Name of output file")
parser.add_argument("--qcov_hsp", help="Name of output file")


args = parser.parse_args()


def is_overlap(starts, stops):
    """given starts and stops vectors of length 2, checks if the two ranges they define overlap"""
    a1, a2 = sorted([starts[0], stops[0]])
    b1, b2 = sorted([starts[1], stops[1]])
    return a1 < b2 and b1 < a2


def gap_length(starts, stops):
    """given starts and stops vectors of length 2, calculate gap length"""
    a1, a2 = sorted([starts[0], stops[0]])
    b1, b2 = sorted([starts[1], stops[1]])
    # touch or overlap
    if a2 >= b1 and b2 >= a1:
        return 0
    if a2 < b1:
        return b1 - a2
    else:  # b2 < a1
        return a1 - b2


def hsp_to_list(e, sinfo):
    return [
        sinfo["qseqid"],
        sinfo["sseqid"],
        float(e.find('.//ns:evalue', ns).text),
        round(100 * int(e.find('.//ns:identity', ns).text) / int(e.find('.//ns:align-len', ns).text), 3),  # in percent!
        round(float(e.find('.//ns:bit-score', ns).text), 0),
        sinfo["sacc"],
        sinfo["staxid"],
        int(e.find('.//ns:align-len', ns).text),
        int(e.find('.//ns:align-len', ns).text) - int(e.find('.//ns:identity', ns).text) - int(e.find('.//ns:gaps', ns).text),
        int(e.find('.//ns:gaps', ns).text),
        sinfo["sscinames"],
        round(100 * int(e.find('.//ns:align-len', ns).text) / sinfo["qsize"], 2)  # in percent !
    ]


def nomerging(hsps, sinfo):
    """Return list of hits in Blast output format"""
    out = []
    for e in hsps:
        out.append(hsp_to_list(e, sinfo))
    return out


def merging(hsps, sinfo, qfrom, qto):
    """Merging HSP pair"""
    a = hsp_to_list(hsps[0], sinfo)
    b = hsp_to_list(hsps[1], sinfo)
    
    a_score, b_score = [int(e.find('.//ns:score', ns).text) for e in hsps]

    # Recalculate metrics
    bitscore = round(( (a_score + b_score) * sinfo["lambd"] - np.log(sinfo["kappa"]) ) / np.log(2), 0)
    evalue = sinfo["qsize"] * sinfo["dbsize"] / 2**bitscore
    length = a[7] + b[7]
    gaps = a[9] + b[9] + gap_length(qfrom, qto)
    mismatch = a[8] + b[8]
    pident = round((a[3] + b[3]) / 2, 3)
    qcov_hsp = a[-1] + b[-1]

    return [
        sinfo["qseqid"],
        sinfo["sseqid"],
        evalue,
        pident,
        bitscore,
        sinfo["sacc"],
        sinfo["staxid"],
        length,
        mismatch,
        gaps,
        sinfo["sscinames"],
        qcov_hsp,
    ]


def main(xml, output, qcov_hsp):
    tree = ET.parse(xml)
    root= tree.getroot()

    hits = []

    # Namespace
    global ns
    ns = {'ns': 'http://www.ncbi.nlm.nih.gov'}

    # Getting search info form query level
    for blast_output in root.findall('.//ns:BlastOutput2', ns):
        qseqid = blast_output.find('.//ns:query-title', ns).text
        qsize = int(blast_output.find('.//ns:query-len', ns).text)
        kappa = float(blast_output.find('.//ns:kappa', ns).text)
        lambd = float(blast_output.find('.//ns:lambda', ns).text)
        dbsize = int(blast_output.find('.//ns:db-len', ns).text)

        # within each query, iterating over subjects
        for hit in blast_output.findall('.//ns:Hit', ns):
            sinfo={
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

            # Check number of HSP - if more than 2 HSP something is not right and the risk is to overestimate bitscore on subject
            if len(hsps) != 2:
                hits.extend(nomerging(hsps, sinfo))
                continue

            # Need to perform some sanity checks before merging HSPs - probably overkill in most cases:
            # Subject and query must be on same strand
            qstrands = [e.text for e in hit.findall('.//ns:hit-strand', ns)]
            sstrands = [e.text for e in hit.findall('.//ns:query-strand', ns)]
            if len(set(qstrands)) > 1 or len(set(sstrands)) > 1:
                hits.extend(nomerging(hsps, sinfo))
                continue

            # Be sure the HSPs do not overlap
            qfrom = [int(e.text) for e in hit.findall('.//ns:query-from', ns)]
            qto = [int(e.text) for e in hit.findall('.//ns:query-to', ns)]
            sfrom = [int(e.text) for e in hit.findall('.//ns:hit-from', ns)]
            sto = [int(e.text) for e in hit.findall('.//ns:hit-to', ns)]
            if is_overlap(qfrom, qto) or is_overlap(sfrom, sto):
                hits.extend(nomerging(hsps, sinfo))
                continue

            # Merging
            hits.append(merging(hsps, sinfo, qfrom, qto))
    
    # Dump to text
    with open(output, "w") as fi:
        for e in hits:
            if e[-1]>= int(qcov_hsp):
                fi.write("\t".join([str(v) for v in e[:-1]]))
                fi.write("\n")


if __name__ == '__main__':
    main(args.xml, args.output, args.qcov_hsp)
