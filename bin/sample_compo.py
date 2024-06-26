#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json
import pandas as pd


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--json", help="Path to blast report as json with delta-bitscore values")
parser.add_argument("--output")
args = parser.parse_args()


def main(json_in, output):
    with open(json_in, "r") as fi:
        j = json.load(fi)

    size = {}
    rank, name = {}, {}
    total = 0
    for e in j:
        size.setdefault(e["taxid"], []).append(e["size"])
        rank.setdefault(e["taxid"], e["rank"])
        name.setdefault(e["taxid"], e["name"])
        total += int(e["size"])

    d = [{
            "name": name[id],
            "taxid": id,
            "rank": rank[id],
            "proportion": round(sum([float(i) for i in size[id]])/float(total), 4)
    } for id in size.keys()]

    df = pd.read_json(json.dumps(d), orient="record")
    df = df.sort_values("proportion")
    df.to_csv(output, sep="\t", index=False)


if __name__ == '__main__':
    main(args.json, args.output)
