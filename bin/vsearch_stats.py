#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json
import gzip
from Bio import SeqIO


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--sample_id", help="sample ID")
parser.add_argument("--fwd", help="Path to forward reads fastq")
parser.add_argument("--merged", help="Path to merged reads fastq")
parser.add_argument("--filtered", help="Path to filtered reads fasta")
parser.add_argument("--nonchimera", help="Path to non-chimeric reads fasta")
parser.add_argument("--output")
args = parser.parse_args()


def main(sample_id, fwd, merged, filtered, nonchimera, output):
    # Total reads
    total_reads = 0
    with gzip.open(fwd, "rt") as handle:
        for _ in SeqIO.parse(handle, "fastq"):
            total_reads += 1

    # Merged reads
    merged_reads = 0
    with open(merged, "r") as handle:
        for _ in SeqIO.parse(handle, "fastq"):
            merged_reads += 1

    # Filtered reads
    filtered_reads = 0
    with open(filtered, "r") as handle:
        for _ in SeqIO.parse(handle, "fasta"):
            filtered_reads += 1

    # Non-chimeric reads
    # this is after dereplication, parse headers to get read numbers
    non_chimeric = 0

    # If we do not perform chimera removal, we instead use the filtered file
    # which lacks the size= information; so we just add 1
    with open(nonchimera, "r") as handle:
        for record in SeqIO.parse(handle, "fasta"):
            if "size=" in record.id:
                non_chimeric += int(record.id.split(";size=")[1])
            else:
                non_chimeric += 1

    # JSON output
    d = {
        "passing": non_chimeric,
        "not_merged": total_reads - merged_reads,
        "filtered": merged_reads - filtered_reads,
        "chimeras": filtered_reads - non_chimeric
        }
    with open(output, "w") as fo:
        json.dump({sample_id: d}, fo)


if __name__ == '__main__':
    main(args.sample_id, args.fwd, args.merged, args.filtered, args.nonchimera, args.output)
