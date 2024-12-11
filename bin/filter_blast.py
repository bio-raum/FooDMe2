#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json
from os import stat
import pandas as pd


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--report", help="path to BLAST report")
parser.add_argument("--output", help="Path to output table")
parser.add_argument("--bit_diff", type=int, default=4,
                    help="Maximum bitscore difference to best hit to keep a hit")
args = parser.parse_args()


def main(report, output, bit_diff):
    header = [
        "query",
        "subject",
        "evalue",
        "identity",
        "bitscore",
        "subject_acc",
        "subject_taxid",
        "alignment_length",
        "mismatch",
        "gaps",
        "subject_name"
    ]

    if stat(report).st_size == 0:
        json_out = {}
    else:
        df = pd.read_csv(report, sep="\t", names=header)
        if not df.empty:
            df[["query", "size"]] = df["query"].str.split(";size=", n=1, expand=True)
            df["delta_bitscore"] = df.groupby("query")["bitscore"].transform("max") - df["bitscore"]
            df["keep"] = df.apply(lambda x: x["delta_bitscore"] <= bit_diff, axis=1)
        json_out = json.loads(df.to_json(orient="records"))
    with open(output, "w") as fo:
        json.dump(json_out, fo, indent=4)


if __name__ == '__main__':
    main(args.report, args.output, args.bit_diff)
