#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--taxids", help="path to BLAST mask")
parser.add_argument("--blocklist", help="Path to blocklist")
parser.add_argument("--output", help="Name of output file")

args = parser.parse_args()


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
    main(args.taxids, args.blocklist, args.output)
