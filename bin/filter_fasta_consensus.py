#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Script to prune taxonomic assignments

import argparse
from Bio import SeqIO

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--fasta", help="path to fasta file")
parser.add_argument("--cutoff", type=float, help="Cutoff for N content", default=0.1)
parser.add_argument("--output", help="path to output file")

args = parser.parse_args()


def main(fasta, cutoff, output):

    valid = []
    for record in SeqIO.parse(fasta, "fasta"):
        record.seq = record.seq.strip("N")
        n_count = record.seq.count("N")
        seq_len = len(record.seq)
        n_freq = 0 if (n_count == 0) else float((n_count/seq_len))
        # We skip entries that have too many Ns
        if (n_freq < cutoff):
            valid.append(record)

    with open(output, "w") as output_handle:
        SeqIO.write(valid, output_handle, "fasta")


if __name__ == '__main__':
    main(args.fasta,
         args.cutoff,
         args.output)
