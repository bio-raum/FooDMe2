#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import taxidTools
from collections import Counter, defaultdict


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--blast", help="Path to BLAST report. SeqID and Taxid should come first and sixth repsectively")
parser.add_argument("--taxonomy", help="A JSON Taxonomy exported by taxidTool")
parser.add_argument("--min_consensus", help="Consensus level in the ]0.5,1] interval", type=float)
parser.add_argument("--output", help="Path to output table")
args = parser.parse_args()


def parse_blast(blast_file):
    """
    Parse a BLAST report and returns a dictionnary where Keys are query
    sequence names and values list of taxids for each hit.
    BLAST report must have the following formatting:
        '6 qseqid sseqid evalue pident bitscore sacc
        staxids sscinames scomnames stitle'
    """
    dictout = defaultdict()
    with open(blast_file, 'r') as fi:
        next(fi)  # Skip header
        for line in fi:
            ls = line.split()
            taxids = ls[6].split(";")  # split taxids if nescessary
            # extend taxids list for this OTU
            if ls[0] in dictout.keys():
                dictout[ls[0]].extend(taxids)
            # or inititate the list
            else:
                dictout[ls[0]] = taxids

    # Make sure everything is str formated
    dictout = {k: [str(e) for e in v] for k, v in dictout.items()}

    return dictout


def main(blast_report, taxonomy, min_consensus, output):
    if min_consensus <= 0.5 or min_consensus > 1:
        raise ValueError("'min_consensus' must be in the interval (0.5 , 1]")

    tax = taxidTools.read_json(taxonomy)
    otu_dict = parse_blast(blast_report)
    with open(output, 'w') as out:
        out.write("queryID\tConsensus\tRank\tTaxid\tDisambiguation\n")

        for queryID, taxid_list in otu_dict.items():
            try:
                # Usual case, maybe some taxa missing
                consensus = tax.consensus(taxid_list, min_consensus, ignore_missing=True)
                rank = consensus.rank
                name = consensus.name
                taxid = consensus.taxid
            except ValueError:
                # All taxa missing or empty taxid_list
                consensus = "Undetermined"
                taxid = "Undetermined"
                rank = "Undetermined"
                name = "Undetermined"

            # (freq, name) tuple to sort
            freqs = [((v/len(taxid_list)), tax.getName(k))
                     for k, v in Counter(taxid_list).items()]
            sorted_freqs = sorted(freqs, reverse=True)

            names = "; ".join([
                f"{f} ({round(n, 2)})"
                for (n, f) in sorted_freqs]
            )
            out.write(f"{queryID}\t{name}\t{rank}\t{taxid}\t{names}\n")


if __name__ == '__main__':
    main(
        args.blast,
        args.taxonomy,
        args.min_consensus,
        args.output
    )
