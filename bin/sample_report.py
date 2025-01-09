#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json
import yaml
from datetime import datetime


parser = argparse.ArgumentParser(description="Script options", argument_default=None)
parser.add_argument("--sample_id", help="sample ID")
parser.add_argument("--run_name", help="run name")
parser.add_argument("--compo", help="composition json")
parser.add_argument("--cutadapt", help="cutadat_mqc json")
parser.add_argument("--clustering", help="either dada_mqc or vsearch_mqc json")
parser.add_argument("--blast", help="blast_filtered json")
parser.add_argument("--consensus", help="consensus json")
parser.add_argument("--versions", help="versions yaml")
parser.add_argument("--fastp_input", nargs='?', const=False, help="FastP JSON pre-trimming")
parser.add_argument("--fastp_trim", nargs='?', const=False, help="FastP JSON post-trimming")
parser.add_argument("--output")
args = parser.parse_args()


def parse_json(handle):
    "boilerplate jsonparsing and return as dict"
    with open(handle, "r") as fi:
        return json.load(fi)


def main(sample_id, run_name, compo, cutadapt, clustering, blast, consensus, versions, fastp_input, fastp_trim, output):
    cutadapt_dict = parse_json(cutadapt) if cutadapt else {}
    cluster_dict = parse_json(clustering)  # cannot be null
    blast_dict = parse_json(blast) if blast else {}
    consensus_dict = parse_json(consensus) if consensus else {}
    compo_dict = parse_json(compo) if compo else {}
    fastp_dict = parse_json(fastp_input) if fastp_input else {}
    fastp_trim_dict = parse_json(fastp_trim) if fastp_trim else {}

    with open(versions, "r") as fi:
        versions_dict = yaml.safe_load(fi)

    out = {
        "sample": sample_id,
        "run_name": run_name,
        "run_date": datetime.now().strftime('%Y-%m-%d'),
        "composition": compo_dict.get(sample_id, {}),
        "fastp": fastp_dict,
        "cutadapt": cutadapt_dict.get("data", {}).get(sample_id, {}),
        "fastp_trimmed": fastp_trim_dict,
        "clustering": cluster_dict.get("data", {}).get(sample_id, {}),
        "blast": blast_dict,
        "consensus": consensus_dict,
        "versions": versions_dict,
    }

    outfil = {k: v for k, v in out.items() if v}

    with open(output, "w") as fo:
        json.dump(outfil, fo, indent=4)


if __name__ == '__main__':
    main(args.sample_id,
         args.run_name,
         args.compo,
         args.cutadapt,
         args.clustering,
         args.blast,
         args.consensus,
         args.versions,
         args.fastp_input,
         args.fastp_trim,
         args.output)
