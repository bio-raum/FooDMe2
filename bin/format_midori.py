#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
from Bio import SeqIO


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--fasta")
parser.add_argument("--output")
args = parser.parse_args()


def main(fasta, output):

    # Rather than trying to fix the Midori IDs, we create new ones.
    counter = 1000

    results = open(output + ".fasta", "w")
    taxmap = open(output + ".taxids", "w")
    lookup = open(output + ".idmap", "w")

    for record in SeqIO.parse(fasta, "fasta"):

        taxid = record.description.split("_")[-1]

        counter += 1

        accession = ".".join(record.description.split(".")[0:2])
        clean = f"{accession}_{counter}"

        taxmap.write(f"{clean}\t{taxid}\n")

        acc = record.description.split("#")[0]

        lookup.write(f"{acc}\t{clean}\n")

        record.id = clean
        record.description = clean

        SeqIO.write(record, results, "fasta")

    results.close()
    taxmap.close()
    lookup.close()


if __name__ == '__main__':
    main(args.fasta, args.output)
