#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json
import re


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--sample_id", help="sample ID")
parser.add_argument("--before", help="Stats from before consensus building")
parser.add_argument("--after", help="Stats from after consensus building")
parser.add_argument("--output")
args = parser.parse_args()


def parse_samtools_stats(txt):

    results = {}

    with open(txt, 'r') as fi:
        lines = [line.rstrip() for line in fi]

    for line in lines:
        if line.startswith("SN"):
            elements = re.split(r'\t', line.strip())
            print(elements)
            results[elements[1].replace(":", "")] = elements[2]

    return results


def main(sample_id, before, after, output):

    results = {
        "chimeras": 0,
        "filtered": 0,
        "filtered_qual": 0,
        "no_merged": 0,
        "passing": 0
    }

    data_before = parse_samtools_stats(before)
    data_after = parse_samtools_stats(after)

    reads_before = int(data_before["sequences"])
    reads_after = int(data_after["sequences"])

    filtered = (reads_before - reads_after)

    if filtered > 0:
        results["filtered"] = filtered

    results["passing"] = reads_after

    with open(output, "w") as fo:
        json.dump({sample_id: results}, fo)


if __name__ == '__main__':
    main(args.sample_id, args.before, args.after, args.output)
