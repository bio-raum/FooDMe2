#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
from os import stat
import pandas as pd


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--report", help="path to BLAST report")
parser.add_argument("--output", help="Path to output table")
parser.add_argument("--bit_diff", type=int, default=4,
                    help="Maximum bitscore difference to best hit to keep a hit")
args = parser.parse_args()


def main(report, output, bit_diff):
    str = "\t"
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
        with open(output, "w") as fout:
            fout.write(
                str.join(header)
            )
    else:
        df = pd.read_csv(report, sep="\t", names=header)
        if df.empty:
            df.to_csv(output, sep="\t", header=True, index=False)
        else:
            sd = dict(tuple(df.groupby("query")))
            dfout = pd.DataFrame()
            for key, val in sd.items():
                dfout = pd.concat(
                    [dfout, val[val["bitscore"] >= max(val["bitscore"]) - bit_diff]]
                )
            dfout["query"] = dfout["query"].str.split(";").str[0]
            dfout.to_csv(output, sep="\t", header=True, index=False)


if __name__ == '__main__':
    main(args.report, args.output, args.bit_diff)
