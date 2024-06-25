#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json
import taxidTools
from collections import Counter, defaultdict


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--blast", help="Path pre-filtered BLAST report as JSON")
parser.add_argument("--taxonomy", help="A JSON Taxonomy exported by taxidTool")
parser.add_argument("--min_consensus", help="Consensus level in the ]0.5,1] interval", type=float)
parser.add_argument("--output", help="Path to output table")
args = parser.parse_args()


def main(blast_report, taxonomy, min_consensus, output):
    if min_consensus <= 0.5 or min_consensus > 1:
        raise ValueError("'min_consensus' must be in the interval (0.5 , 1]")

    tax = taxidTools.read_json(taxonomy)

    with open(blast_report) as fi:
        blast_dict = json.load(fi)

    # Group by query ID and get list of all taxid where "keep" is True
    otus = {}
    for d in blast_dict:
        if d["keep"]:
            otus.setdefault(d["query"], []).append(d["Taxid"])
    otus = [{"queryID": k, "tax_list": v} for k, v in otus.items()]

    for d in otus:
        try:
            # Usual case, maybe some taxa missing
            consensus = tax.consensus(d["tax_list"], min_consensus, ignore_missing=True)
            rank = consensus.rank
            name = consensus.name
            taxid = consensus.taxid
        except ValueError:
            # All taxa missing or empty taxid_list
            consensus = "Undetermined"
            taxid = "Undetermined"
            rank = "Undetermined"
            name = "Undetermined"
        finally:
            d["consensus"] = consensus
            d["rank"] = rank
            d["name"] = name
            d["taxid"] = taxid
        
        # (freq, name) tuple to sort
        freqs = [{
            "name": tax.getName(k),
            "taxid": k,
            "freq": v/len(d["tax_list"])
            } for k, v in Counter(d["tax_list"]).items()
            ]
        
        d["tax_list"] = sorted(freqs, reverse=True)
    
    with open(output, "w") as fo:
        json.dump(fo, otus)


if __name__ == '__main__':
    main(
        args.blast,
        args.taxonomy,
        args.min_consensus,
        args.output
    )
