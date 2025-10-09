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


# We remove any leading and trailing stretchs with too many Ns
def clean_seq(seq):

    tail = seq[-10:-1]
    tail_n = tail.count("N")
    if tail_n > 0:
        tail_n_freq = round((tail_n / len(tail)), 2)
        if tail_n_freq > 0.5:
            seq = seq[:-10]

    head = seq[:10]
    head_n = head.count("N")
    if head_n > 0:
        head_n_freq = round((head_n / len(head)), 2)
        if head_n_freq > 0.5:
            seq = seq[10:-1]

    return seq.strip("N")


def main(fasta, cutoff, output):

    valid = []
    for record in SeqIO.parse(fasta, "fasta"):
        record.seq = record.seq.strip("N")
        seq = clean_seq(record.seq)
        record.seq = seq
        n_count = record.seq.count("N")
        seq_len = len(record.seq)

        n_freq = 0 if (n_count == 0) else float((n_count / seq_len))
        # We skip entries that have too many Ns
        if (n_freq < cutoff):
            valid.append(record)

    with open(output, "w") as output_handle:
        SeqIO.write(valid, output_handle, "fasta")


if __name__ == '__main__':
    main(args.fasta,
         args.cutoff,
         args.output)
