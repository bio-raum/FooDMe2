#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import pandas as pd
import json


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--json", help="Path to blast report as json with delta-bitscore values")
parser.add_argument("--output")
args = parser.parse_args()


HEADER = [
    "query",
    "size",
    "subject_taxid",
    "subject_name",
    "delta_bitscore",
    "keep",
    "bitscore",
    "alignment_length",
    "mismatch",
    "gaps"
]


def main(json_in, output):
    with open(json_in, "r") as fi:
        jd = json.load(fi)
    if not jd:
        df = pd.DataFrame(columns=HEADER)
    else:
        df = pd.read_json(json_in, orient="record")
        df = df[HEADER]
        df.sort_values("size", ascending=False)
    df.to_csv(output, sep="\t", index=False)


if __name__ == '__main__':
    main(args.json, args.output)
