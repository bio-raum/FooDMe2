#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys


sys.stderr = open(snakemake.log[0], "w")


def main(taxids, blocklist, output):
    with open(taxids, 'r') as fi:
        taxs = set([line.strip() for line in fi.readlines()])

    with open(blocklist, 'r') as bl:
        blocks = set([line.split('#')[0].strip() for line in bl.readlines()])

    listout = taxs.difference(blocks)

    with open(output, 'w') as fo:
        for tax in listout:
            fo.write(f"{tax}\n")


if __name__ == '__main__':
    main(snakemake.input["taxids"],
         snakemake.input["blocklist"],
         snakemake.output['mask'])
