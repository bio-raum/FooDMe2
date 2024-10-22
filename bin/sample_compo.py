#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json
import pandas as pd


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--json", help="Path to blast report as json with delta-bitscore values")
parser.add_argument("--output_tsv")
parser.add_argument("--output_json")
args = parser.parse_args()


def main(json_in, output_tsv, output_json):
    with open(json_in, "r") as fi:
        j = json.load(fi)

    sample = json_in.split(".")[0]

    size = {}
    rank, name = {}, {}
    total = 0
    for e in j:
        size.setdefault(e["taxid"], []).append(e["size"])
        rank.setdefault(e["taxid"], e["rank"])
        name.setdefault(e["taxid"], e["name"])
        total += int(e["size"])

    d = [{
            "sample": sample,
            "name": name[id],
            "taxid": id,
            "reads": sum([int(i) for i in size[id]]),
            "rank": rank[id],
            "proportion": round(sum([float(i) for i in size[id]])/float(total), 4)
    } for id in size.keys()]

    df = pd.read_json(json.dumps(d), orient="record")
    df = df.sort_values("proportion", ascending=False)
    df.to_csv(output_tsv, sep="\t", index=False)

    aggd = {}
    for entry in d:
        aggd.setdefault(entry["sample"], []).append({k: v for k, v in entry.items() if k != "sample"})

    with open(output_json, "w") as fo:
        json.dump(aggd, fo, indent=4)


if __name__ == '__main__':
    main(args.json, args.output_tsv, args.output_json)
