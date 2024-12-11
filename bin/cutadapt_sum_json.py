#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json


parser = argparse.ArgumentParser(description="Script options", argument_default=None)
parser.add_argument("--sample")
parser.add_argument("--forward")
parser.add_argument("--reverse")
parser.add_argument("--output")
args = parser.parse_args()


def main(sample, fwd, rev, output):

    matrix = {
        "id": "Cutadapt",
        "section_name": "Cutadapt",
        "description": "Cutadapt is a tool to find and remove adapter sequences, primers, poly-A tails and other types of unwanted sequence from your high-throughput sequencing reads. DOI: 10.14806/ej.17.1.200.",
        "plot_type": "bargraph",
        "pconfig": {
            "id": "cutadapt",
            "col1_header": "Sample",
            "title": "Cutadapt: Filtered reads"
        },
        "data": {}
    }

    reads_in = 0
    reads_out = 0

    if fwd:
        with open(fwd) as fjson:
            fwd_data = json.load(fjson)

    if rev:
        with open(rev) as rjson:
            rev_data = json.load(rjson)

    data = {}

    reads_in = 0
    reads_out = 0

    if rev:
        reads_in = fwd_data["read_counts"]["input"]
        reads_out = rev_data["read_counts"]["output"]
    else:
        reads_in = fwd_data["read_counts"]["input"]
        reads_out = fwd_data["read_counts"]["output"]

    passing = reads_out
    failed = reads_in-reads_out

    data = {"Reads passing filters": passing, "Filtered reads (uncategorized)": failed}

    matrix["data"][sample] = data

    with open(output, "w") as sj:
        json.dump(matrix, sj)


if __name__ == '__main__':
    main(args.sample, args.forward, args.reverse, args.output)
