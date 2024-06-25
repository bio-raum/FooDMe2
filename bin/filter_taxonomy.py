#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Script to prune taxonomic assignments

import argparse
import taxidTools


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--nodes", help="path to nodes.dmp")
parser.add_argument("--rankedlineage", help="path to rankedlineage.dmp")
parser.add_argument("--merged", help="path to merged.dmp")
parser.add_argument("--taxid", help="TaxID of a Node marking the branch to keep")
parser.add_argument("--json", help="Path to JSON Taxonomy output")
args = parser.parse_args()


def main(nodes, lineage, merged, taxid, out):
    tax = taxidTools.read_taxdump(nodes, lineage, merged)
    tax.prune(taxid)
    tax.write(out)


if __name__ == '__main__':
    main(args.nodes,
         args.rankedlineage,
         args.merged,
         args.taxid,
         args.json)
