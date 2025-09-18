#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Script to prune taxonomic assignments


import argparse
import taxidTools
import json

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--report", help="path to summary json")
parser.add_argument("--tax", help="Taxonomy JSON")
parser.add_argument("--output", help="Path to output table")
args = parser.parse_args()


def main(report, tax, output):
    tax = taxidTools.read_json(tax)

    with open(report) as fd, open(output, "w") as fo:
        jdata = json.load(fd)
        composition = jdata["composition"]

        for entry in composition:
            try:
                taxon = entry["taxid"]
                lineage = taxidTools.Lineage(tax[taxon], ascending=False)
                lineage_string = "\t".join([node.name for node in lineage])
            except taxidTools.InvalidNodeError:
                lineage_string = "Undetermined"
            finally:
                abundance = entry["proportion"]
                fo.write(f"{abundance}\t{lineage_string}\n")


if __name__ == '__main__':
    main(args.report,
         args.tax,
         args.output)
