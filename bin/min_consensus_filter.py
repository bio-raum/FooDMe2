#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json
import taxidTools
from collections import Counter


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--blast", help="Path to pre-filtered BLAST report as JSON")
parser.add_argument("--otus", help="Path to OTUs fasta")
parser.add_argument("--taxonomy", help="A JSON Taxonomy exported by taxidTool")
parser.add_argument("--min_consensus", help="Consensus level in the ]0.5,1] interval", type=float)
parser.add_argument("--output", help="Path to output table")
args = parser.parse_args()


def parse_headers(otus_fasta):
    """Generator for sequence ID and size from OTU fasta file
    '>SeqID;size=xxx' yields (SeqID, xxx)"""
    with open(otus_fasta) as fi:
        for line in fi:
            if line[0] == ">":
                parsed = line[1:].split(";size=")
                yield parsed[0], parsed[1].strip()


def get_support(taxid, tax_list, taxonomy):
    support = 0
    for record in tax_list:
        if (record["taxid"] == taxid) or (taxonomy.isDescendantOf(record["taxid"], taxid)):
            support += record["freq"]
    return support


def main(blast_report, otus_fasta, taxonomy, min_consensus, output):
    if min_consensus <= 0.5 or min_consensus > 1:
        raise ValueError("'min_consensus' must be in the interval (0.5 , 1]")

    tax = taxidTools.read_json(taxonomy)

    with open(blast_report) as fi:
        blast_dict = json.load(fi)

    # Group by query ID and get list of all taxid where "keep" is True
    otus = {}
    sizes = {}

    for d in blast_dict:
        if d["keep"]:
            otus.setdefault(d["query"], []).append(str(d["subject_taxid"]))
            sizes.setdefault(d["query"], d["size"])
    # Add missing ids (no BLAST hits) from OTU fasta
    for id, size in parse_headers(otus_fasta):
        otus.setdefault(id, [])
        sizes.setdefault(id, size)
    # Reformat to list
    otus = [{"query": k, "tax_list": v} for k, v in otus.items()]

    # add sized to dict
    for e in otus:
        e["size"] = sizes[e["query"]]

    for d in otus:

        # (freq, name) tuple to sort
        freqs = [{
            "name": tax.getName(k),
            "taxid": k,
            "freq": v/len(d["tax_list"])
            } for k, v in Counter(d["tax_list"]).items()
            ]

        try:
            # Usual case, maybe some taxa missing
            consensus = tax.consensus(d["tax_list"], min_consensus, ignore_missing=True)
            rank = consensus.rank
            name = consensus.name
            taxid = consensus.taxid
            support = get_support(consensus.taxid, freqs, tax)
        except ValueError:
            # All taxa missing or empty taxid_list: Value Error
            consensus = "Undetermined"
            taxid = "Undetermined"
            rank = "Undetermined"
            name = "Undetermined"
            support = 1.
        finally:
            d["rank"] = rank
            d["name"] = name
            d["taxid"] = taxid
            d["support"] = support
            d["tax_list"] = freqs

    with open(output, "w") as fo:
        json.dump(otus, fo, indent=4)


if __name__ == '__main__':
    main(
        args.blast,
        args.otus,
        args.taxonomy,
        args.min_consensus,
        args.output
    )
