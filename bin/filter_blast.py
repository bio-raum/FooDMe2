#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys


sys.stderr = open(snakemake.log[0], "w")


from os import stat
import pandas as pd


def main(report, filtered, bit_diff):
    if stat(report).st_size == 0:
        with open(filtered, "w") as fout:
            fout.write(
                "query\tsubject\tevalue\tidentity\tbitscore\tsubject_acc\t"
                "subject_taxid\talignment_length\tmismatch\tgaps\tsubject_name"
            )
    else:
        df = pd.read_csv(report, sep="\t", header=0)
        if df.empty:
            df.to_csv(filtered, sep="\t", header=True, index=False)
        else:
            sd = dict(tuple(df.groupby("query")))
            dfout = pd.DataFrame()
            for key, val in sd.items():
                dfout = pd.concat(
                    [dfout, val[val["bitscore"] >= max(val["bitscore"]) - bit_diff]]
                )
            dfout["query"] = dfout["query"].str.split(";").str[0]
            dfout.to_csv(filtered, sep="\t", header=True, index=False)


if __name__ == '__main__':
    main(snakemake.input['report'],
        snakemake.output['filtered'],
        snakemake.params['bit_diff'])
