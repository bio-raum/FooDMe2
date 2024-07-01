#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json
import gzip
from Bio import SeqIO


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--fwd", help="Path to forward reads fastq")
parser.add_argument("--merged", help="Path to merged reads fastq")
parser.add_argument("--filtered", help="Path to filtered reads fasta")
parser.add_argument("--nonchimera", help="Path to non-chimeric reads fasta")
parser.add_argument("--output")
args = parser.parse_args()


def main(fwd, merged, filtered, nonchimera, output):
    # Total reads
    total_reads = 0
    with gzip.open(fwd, "rt") as handle:
        for _ in SeqIO.parse(handle, "fastq"):
            total_reads += 1

    # Merged reads
    merged_reads = 0
    with open(merged, "r") as handle:
        for _ in SeqIO.parse(handle, "fastq"):
            merged_reads +=1

    # Filtered reads
    filtered_reads = 0
    with open(filtered, "r") as handle:
        for _ in SeqIO.parse(handle, "fasta"):
            filtered_reads += 1

    # Non-chimeric reads and OTU number
    # this is after dereplication, parse headers to get read numbers
    n_otus, non_chimeric = 0, 0
    with open(nonchimera, "r") as handle:
        for record in SeqIO.parse(handle, "fasta"):
            n_otus += 1
            non_chimeric += int(record.id.split(";size=")[1])

    # JSON output
    d = {
        "total_pairs": total_reads,
        "merged": merged_reads,
        "filtered": filtered_reads,
        "non_chimeric": non_chimeric,
        "otus": n_otus
        }
    with open(output, "w") as fo:
        json.dump(d, fo, indent=4)


if __name__ == '__main__':
    main(args.fwd, args.merged, args.filtered, args.nonchimera, args.output)
