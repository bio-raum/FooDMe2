#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json
import pandas as pd


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--json", help="Path to blast report as json with delta-bitscore values")
parser.add_argument("--sample_id", help="sample name")
parser.add_argument("--output_tsv")
parser.add_argument("--output_json")
parser.add_argument("--tax_lookup", help="Path to tabular file with taxid and common english name columns")
args = parser.parse_args()

MISSING_ENTRY = "not_available"

def load_tax_lookup(tax_lookup_file):
    """Load taxid to common english name mapping from file"""
    tax_lookup = {}
    if tax_lookup_file:
        try:
            with open(tax_lookup_file, 'r', encoding="utf-8") as f:
                header = f.readline().rstrip('\r\n').split("\t")
                for line in f:
                    if line.strip():
                        parts = line.rstrip('\r\n').split('\t')
                        this_data = {}
                        for idx, h in enumerate(header):
                            this_data[h] = parts[idx]
                        
                        # we have already seen this tax id, only adding new translations
                        # but translations are optional, so check we have a translation column
                        if ("translation" in header) and (this_data["tax_id"] in tax_lookup):
                            existing_entry = tax_lookup[this_data["tax_id"]]
                            translations = existing_entry.get("translation", "")
                            if isinstance(translations, list):
                                tax_lookup[this_data["tax_id"]]["translation"].append(this_data["translation"])
                            else:
                                tax_lookup[this_data["tax_id"]]["translation"] = [ existing_entry["translation"], this_data["translation"] ]
                        else:
                            tax_lookup[this_data["tax_id"]] = this_data
        except Exception as e:
            print(f"Warning: Could not load tax lookup file {tax_lookup_file}: {e}")
    return tax_lookup


def main(json_in, sample, output_tsv, output_json, tax_lookup_file=None):
    # Load tax lookup dictionary
    tax_lookup = load_tax_lookup(tax_lookup_file)

    with open(json_in, "r", encoding="utf-8") as fi:
        j = json.load(fi)

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

    # Add common english name and translation if available
    for entry in d:
        taxid = entry["taxid"]
        if taxid in tax_lookup:
            entry["common_english"] = tax_lookup[taxid].get("common_name", MISSING_ENTRY)
            # Check if the translations are a string, or a list - then make it a string
            translations = tax_lookup[taxid].get("translations", MISSING_ENTRY)
            if isinstance(translations, list):
                taxa = tax_lookup[taxid]["translation"]
                clean_list = [x for x in taxa if len(x) > 0]
                entry["common_translated"] = "|".join(list(set(clean_list)))
            else:
                entry["common_translated"] = translations
        else:
            entry["common_english"] = MISSING_ENTRY
            entry["common_translated"] = MISSING_ENTRY

    if d:
        df = pd.DataFrame.from_records(d)
        df = df.sort_values("proportion", ascending=False)
    else:
        df = pd.DataFrame(columns=["sample", "name", "taxid", "reads", "rank", "proportion", "cluster_ids"])

    df.to_csv(output_tsv, sep="\t", index=False, encoding="utf-8-sig")

    aggd = {}
    for entry in d:
        aggd.setdefault(entry["sample"], []).append({k: v for k, v in entry.items() if k != "sample"})

    with open(output_json, "w",  encoding="utf-8") as fo:
        json.dump(aggd, fo,indent=4,  sort_keys=True, )


if __name__ == '__main__':
    main(args.json, args.sample_id, args.output_tsv, args.output_json, args.tax_lookup)
