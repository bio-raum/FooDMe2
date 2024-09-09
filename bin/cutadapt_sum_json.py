#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--forward")
parser.add_argument("--reverse")
parser.add_argument("--output")
args = parser.parse_args()


def main(fwd, rev, output):

    with open(fwd) as fjson:
        fwd_data = json.load(fjson)

    with open(rev) as rjson:
        rev_data = json.load(rjson)

    data = {}

    data["read_count"] = fwd_data["read_counts"]["input"]
    data["filtered_count"] = rev_data["read_counts"]["output"]

    with open(output, "w") as sj:
        json.dump(data, sj)


if __name__ == '__main__':
    main(args.forward, args.reverse, args.output)