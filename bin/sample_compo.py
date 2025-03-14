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

    size, cluster_names, rank, name = {}, {}, {}, {}
    total = 0

    # merging results over taxid called
    # iterate over cluster
    for cluster in j:
        size.setdefault(cluster["taxid"], []).append(cluster["size"])
        rank.setdefault(cluster["taxid"], cluster["rank"])
        name.setdefault(cluster["taxid"], cluster["name"])
        cluster_names.setdefault(cluster["taxid"], []).append(
            # appending hit freq for this specific taxid to the sequence ID
            f"{cluster['query']}[{round(cluster['support'], 2)}]"
        )
        total += int(cluster["size"])

    d = [{
        "sample": sample,
        "name": name[id],
        "taxid": id,
        "reads": sum([int(i) for i in size[id]]),
        "rank": rank[id],
        "proportion": round(sum([float(i) for i in size[id]]) / float(total), 4),
        "cluster_ids": "; ".join(cluster_names[id]),
    } for id in size.keys()]

    if d:
        df = pd.read_json(json.dumps(d), orient="record")
        df = df.sort_values("proportion", ascending=False)
    else:
        df = pd.DataFrame(columns=["sample", "name", "taxid", "reads", "rank", "proportion", "cluster_ids"])
    df.to_csv(output_tsv, sep="\t", index=False)

    aggd = {}
    for entry in d:
        aggd.setdefault(entry["sample"], []).append({k: v for k, v in entry.items() if k != "sample"})

    with open(output_json, "w") as fo:
        json.dump(aggd, fo, indent=4, sort_keys=True)


if __name__ == '__main__':
    main(args.json, args.output_tsv, args.output_json)
