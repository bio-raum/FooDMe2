#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Script to prune taxonomic assignments

import argparse
from Bio import SeqIO

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--fasta", help="path to fasta file")
parser.add_argument("--coverage", help="Coverage from samtools")
parser.add_argument("--output", help="path to output file")

args = parser.parse_args()


def main(fasta, coverage, output):

    # Collect the meandeth per sequence
    sizes = {}
    with open(coverage, 'r') as fi:
        cov = [line.rstrip() for line in fi]

    title = cov.pop(0)
    header = title[1:].split("\t")

    for c in cov:
        elements = c.split("\t")
        data = {}
        for idx, h in enumerate(header):
            data[h] = elements[idx]
        sizes[data["rname"]] = round(float(data["meandepth"]))

    valid = []

    for record in SeqIO.parse(fasta, "fasta"):
        # We skip entries that have too many Ns
        size = sizes[record.id]
        record.id = f"{record.id};size={size}"
        record.description = ""
        if size > 0:
            valid.append(record)

    with open(output, "w") as output_handle:
        SeqIO.write(valid, output_handle, "fasta")


if __name__ == '__main__':
    main(args.fasta,
         args.coverage,
         args.output)
