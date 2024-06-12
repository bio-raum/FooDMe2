#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
from Bio import SeqIO

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--otu")
parser.add_argument("--filtered")
parser.add_argument("--consensus")
parser.add_argument("--output")
args = parser.parse_args()

def main(otu, filtered, consensus, output):

    results     = open(output + ".txt", "w")
    otu_list    = {}

    for record in SeqIO.parse(otu, "fasta"):

        # OTU_1;size=1245
        seqid = record.id.split(";")[0]
        size = record.id.split("=")[-1]

        otu_list[seqid] = { "size": size}

    

if __name__ == '__main__':
    main(args.otu, args.filtered, args.consensus, args.output)
