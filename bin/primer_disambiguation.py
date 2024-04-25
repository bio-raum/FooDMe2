#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys


sys.stderr = open(snakemake.log[0], "w")


from Bio import SeqIO
from itertools import product


def extend_ambiguous_dna(seq):
    """return list of all possible sequences given an ambiguous DNA input"""
    d = {
        'A': 'A',
        'C': 'C',
        'G': 'G',
        'T': 'T',
        'M': ['A', 'C'],
        'R': ['A', 'G'],
        'W': ['A', 'T'],
        'S': ['C', 'G'],
        'Y': ['C', 'T'],
        'K': ['G', 'T'],
        'V': ['A', 'C', 'G'],
        'H': ['A', 'C', 'T'],
        'D': ['A', 'G', 'T'],
        'B': ['C', 'G', 'T'],
        'N': ['G', 'A', 'T', 'C']
    }
    return list(map("".join, product(*map(d.get, seq))))


def primers_to_fasta(name, seq_list):
    """return fasta string of primers with tracing newline"""
    fas = ""
    for i in range(len(seq_list)):
        fas += f">{name}[{i}]\n{seq_list[i]}\n"
    return fas


def main(fastain, fastaout):
    with open(fastain, "r") as fin, open(fastaout, "w") as fout:
        for record in SeqIO.parse(fin, "fasta"):
            explicit = extend_ambiguous_dna(record.seq)
            fasta = primers_to_fasta(record.id, explicit)
            fout.write(fasta)


if __name__ == '__main__':
    main(snakemake.params['primers'],
         snakemake.output['primers'])
