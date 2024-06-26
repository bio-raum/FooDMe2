#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import pandas as pd


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--json", help="Path to blast report as json with delta-bitscore values")
parser.add_argument("--output")
args = parser.parse_args()


def main(json_in, output):
    df = pd.read_json(json_in)
    df = df[[
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
        ]]
    df.sort_values("size")
    df.to_csv(output, sep="\t", index=False)


if __name__ == '__main__':
    main(args.json, args.output)
