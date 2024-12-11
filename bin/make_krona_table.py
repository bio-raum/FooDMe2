#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Script to prune taxonomic assignments


import argparse
import taxidTools


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--table", help="path to compo table")
parser.add_argument("--tax", help="Taxonomy JSON")
parser.add_argument("--output", help="Path to output table")
args = parser.parse_args()


def main(table, tax, output):
    tax = taxidTools.read_json(tax)
    with open(table, "r") as fi, open(output, "w") as fo:
        next(fi)  # skip header
        for line in fi:
            try:
                lineage = taxidTools.Lineage(tax[line.split("\t")[2].strip()], ascending=False)
                lineage_string = "\t".join([node.name for node in lineage])
            except taxidTools.InvalidNodeError:
                lineage_string = "Undetermined"
            finally:
                fo.write(f"{line.split("\t")[5].strip()}\t{lineage_string}\n")


if __name__ == '__main__':
    main(args.table,
         args.tax,
         args.output)
