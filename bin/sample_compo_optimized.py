#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import json
import pandas as pd


def load_tax_lookup(tax_lookup_file):
    """Load taxid to common english name mapping from file"""
    if not tax_lookup_file:
        return {}

    tax_lookup = {}
    try:
        with open(tax_lookup_file, 'r', encoding="utf-8") as f:
            header = f.readline().rstrip('\r\n').split("\t")
            for line in f:
                if not line.strip():
                    continue

                parts = line.rstrip('\r\n').split('\t')
                this_data = dict(zip(header, parts))

                tax_id = this_data["tax_id"]
                # Handle existing entries with translations
                if ("translation" in header) and (tax_id in tax_lookup):
                    existing_entry = tax_lookup[tax_id]
                    existing_translation = existing_entry.get("translation", "")
                    new_translation = this_data["translation"]

                    if isinstance(existing_translation, list):
                        existing_translation.append(new_translation)
                    else:
                        existing_translation = [existing_translation, new_translation]
                    this_data["translation"] = existing_translation

                tax_lookup[tax_id] = this_data
    except Exception as e:
        print(f"Warning: Could not load tax lookup file {tax_lookup_file}: {e}")

    return tax_lookup


def process_clusters(clusters):
    """Process clusters to aggregate data by taxid"""
    size, cluster_names, rank, name = {}, {}, {}, {}
    total = 0

    for cluster in clusters:
        tax_id = cluster["taxid"]
        size.setdefault(tax_id, []).append(cluster["size"])
        rank.setdefault(tax_id, cluster["rank"])
        name.setdefault(tax_id, cluster["name"])
        cluster_names.setdefault(tax_id, []).append(
            f"{cluster['query']}[{round(cluster['support'], 2)}]"
        )
        total += int(cluster["size"])

    return size, cluster_names, rank, name, total


def create_results_data(size, cluster_names, rank, name, total, sample):
    """Create the results data structure"""
    d = [{
        "sample": sample,
        "name": name[id],
        "taxid": id,
        "reads": sum([int(i) for i in size[id]]),
        "rank": rank[id],
        "proportion": round(sum([float(i) for i in size[id]]) / float(total), 4),
        "cluster_ids": "; ".join(cluster_names[id]),
    } for id in size.keys()]

    return d


def add_taxonomic_info(results, tax_lookup):
    """Add common english name and translation info to results"""
    MISSING_ENTRY = "not_available"
    for entry in results:
        taxid = entry["taxid"]
        if taxid in tax_lookup:
            print(taxid)
            entry["common_english"] = tax_lookup[taxid].get("common_name", MISSING_ENTRY)

            translations = tax_lookup[taxid].get("translation", MISSING_ENTRY)
            if isinstance(translations, list):
                clean_list = [x for x in translations if len(x) > 0]
                entry["common_translated"] = "|".join(list(set(clean_list)))
            else:
                entry["common_translated"] = translations
        else:
            entry["common_english"] = MISSING_ENTRY
            entry["common_translated"] = MISSING_ENTRY


def main():
    parser = argparse.ArgumentParser(description="Script options")
    parser.add_argument("--json", help="Path to blast report as json with delta-bitscore values")
    parser.add_argument("--sample_id", help="sample name")
    parser.add_argument("--output_tsv")
    parser.add_argument("--output_json")
    parser.add_argument("--tax_lookup", help="Path to tabular file with taxid and common english name columns")

    args = parser.parse_args()

    # Load tax lookup dictionary
    tax_lookup = load_tax_lookup(args.tax_lookup)

    with open(args.json, "r", encoding="utf-8") as fi:
        j = json.load(fi)

    # Process clusters
    size, cluster_names, rank, name, total = process_clusters(j)

    # Create results data
    d = create_results_data(size, cluster_names, rank, name, total, args.sample_id)

    # Add taxonomic information
    add_taxonomic_info(d, tax_lookup)

    # Create and sort DataFrame
    if d:
        df = pd.DataFrame.from_records(d)
        df = df.sort_values("proportion", ascending=False)
    else:
        df = pd.DataFrame(columns=["sample", "name", "taxid", "reads", "rank", "proportion", "cluster_ids"])

    df.to_csv(args.output_tsv, sep="\t", index=False, encoding="utf-8-sig")

    # Aggregate data for JSON output
    aggd = {}
    for entry in d:
        sample_name = entry["sample"]
        if sample_name not in aggd:
            aggd[sample_name] = []
        aggd[sample_name].append({k: v for k, v in entry.items() if k != "sample"})

    with open(args.output_json, "w", encoding="utf-8") as fo:
        json.dump(aggd, fo, indent=4, sort_keys=True)


if __name__ == '__main__':
    main()
