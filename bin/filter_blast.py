#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import argparse
from os import stat
import pandas as pd

parser=argparse.ArgumentParser(description="Script options")
parser.add_argument("--report")
parser.add_argument("--output")
parser.add_argument("--bit_diff", type=int)
args=parser.parse_args()

bit_diff = args.bit_diff if args.bit_diff else 4

str = "\t"
header = [ "query","subject","evalue","identity","bitscore","subject_acc","subject_taxid","alignment_length","mismatch","gaps","subject_name" ]

if stat(args.report).st_size == 0:
    with open(args.output,"w") as fout:
        fout.write(
            str.join(header)
        )
else:
    df = pd.read_csv(args.report, sep="\t", names = header )
    if df.empty:
        df.to_csv(args.output, sep="\t", header=True, index=False)
    else:
        sd = dict(tuple(df.groupby("query")))
        dfout = pd.DataFrame()
        for key, val in sd.items():
            dfout = pd.concat(
                [dfout, val[val["bitscore"] >= max(val["bitscore"]) - bit_diff]]
            )
        dfout["query"] = dfout["query"].str.split(";").str[0]
        dfout.to_csv(args.output, sep="\t", header=True, index=False) 