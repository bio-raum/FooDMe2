#!/usr/bin/env python
from datetime import datetime
from pathlib import Path
import os
import glob
import json
import re
import argparse

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--output", "-o")
parser.add_argument("--run_name", help="run name")
parser.add_argument("--yaml", "-y")
parser.add_argument("--sample", "-s")


args = parser.parse_args()

# JSON keys we want to remove since they are too large and unnecessary
unwanted_keys = [
    "content_curves",
    "kmer_count",
    # "quality_curves",
]


def dict_cleaner(data):
    if not isinstance(data, dict):
        return data if not isinstance(data, list) else list(map(dict_cleaner, data))
    return {a: dict_cleaner(b) for a, b in data.items() if a not in unwanted_keys}


def parse_json(lines, return_adress=None):
    """
    return the JSON as dict
    if return_adress is defined, returns the value at the key adress
    """
    data = json.loads(" ".join(lines))

    data = dict_cleaner(data)

    if return_adress and data:
        for key in return_adress:
            data = data[key]
        return data
    return data


def parse_csv(lines):
    header = lines.pop(0).strip().split(",")
    data = []
    for line in lines:
        this_data = {}
        elements = line.strip().split(",")
        for idx, h in enumerate(header):
            entry = elements[idx]
            if re.match(r"^[0-9]*$", entry):
                entry = int(entry)
            elif re.match(r"^[0-9]*\.[0-9]*$", entry):
                entry = float(entry)
            this_data[h] = entry
        data.append(this_data)
    return data


def parse_tabular(lines):
    header = lines.pop(0).strip().split("\t")
    data = []
    for line in lines:
        this_data = {}
        elements = line.strip().split("\t")
        for idx, h in enumerate(header):
            if idx < len(elements):
                entry = elements[idx]
                # value is an integer
                if re.match(r"^[0-9]+$", entry):
                    entry = int(entry)
                # value is a float
                elif re.match(r"^[0-9]+\.[0-9]+$", entry):
                    entry = float(entry)
                # value is a file path (messes up md5 fingerprinting)
                elif re.match(r"^\/.*\/.*$", entry):
                    entry = entry.split("/")[-1]
                this_data[h] = entry
        data.append(this_data)

    return data


def parse_nanoplot(lines):

    lines.pop(0)  # remove header line

    # We only need a histogram
    data = {"histogram": []}

    # header = lines.pop(0)
    nano_lengths = []
    for line in lines:
        elements = line.split("\t")
        # qual = round(float(elements[0]), 2)
        length = int(elements[1])
        nano_lengths.append(length)

    # render a histogram up to 1000bp
    for xval in range(1000):
        m = len([val for val in nano_lengths if val == xval])
        data["histogram"].append(m)

    return data


def parse_yaml(lines):
    data = {}
    key = ""

    for line in lines:

        line = line.replace(":", "")
        if re.match(r"^\s+.*", line):
            elements = line.strip().split(" ")
            tool = elements.pop(0)
            version = " ".join(elements)
            data[key][tool] = version
        else:
            key = line.strip()
            data[key] = {}

    return data


def main(sample, yaml_file, run_name, output):

    # Mapping each JSON section to (json_key, file regex, parsing_function, kwargs)
    parser_mapper = {
        "composition": ("composition", ".composition.json", parse_json, {"return_adress": [sample]}),
        "cutadapt": ("cutadapt", ".cutadapt_mqc.json", parse_json, {"return_adress": ["data", sample]}),
        "filtered": ("filtered", ".filtered.json", parse_json, None),
        "consensus": ("consensus", ".consensus.json", parse_json, None),
        "fastp": ("fastp", ".adaptertrim.fastp.json", parse_json, None),
        "fastplong": ("fastplong", ".adaptertrim.fastplong.json", parse_json, None),
        "fastp_trimmed": ("fastp_trimmed", ".trim.fastp.json", parse_json, None),
        "fastplong_trimmed": ("fastplong_trimmed", ".trim.fastplong.json", parse_json, None),
        "clustering_dada": ("clustering", ".dada_stats.json", parse_json, {"return_adress": [sample]}),
        "clustering_vsearch": ("clustering", ".vsearch_stats.json", parse_json, {"return_adress": [sample]}),
        "clustering_ont": ("clustering", ".ont_mapping_stats.json", parse_json, {"return_adress": [sample]}),
        "nanoplot": ("nanoplot", ".nanoplot.adaptertrim.tsv", parse_nanoplot, None),
        "nanoplot_trimmed": ("nanoplot_trimmed", ".nanoplot.trim.tsv", parse_nanoplot, None),
        "versions": ("versions", "versions.yml", parse_yaml, None),
    }

    files = [os.path.abspath(f) for f in glob.glob("*/*")]
    files.append(yaml_file)

    date = datetime.today().strftime('%Y-%m-%d')

    matrix = {
        "date": date,
        "sample": sample,
        "composition": None,
        "clustering": None,
        "cutadapt": None,
        "versions": None,
        "run_date": datetime.now().strftime('%Y-%m-%d'),
        "run_name": run_name
    }

    # Iterating over Path objects
    for file_path in map(Path, files):

        with open(file_path, "r") as f:
            lines = [line.rstrip() for line in f]

        # keep track of matched keys to skip
        matched_keys = set()

        for k, (json_key, suffix, func, kwargs) in parser_mapper.items():
            if k in matched_keys:
                continue
            if file_path.name.endswith(suffix):
                kwargs = kwargs or {}
                matrix[json_key] = func(lines, **kwargs)
                matched_keys.add(k)
                break

    with open(output, "w") as fo:
        json.dump(matrix, fo, indent=4, sort_keys=True)


if __name__ == '__main__':
    main(args.sample, args.yaml, args.run_name, args.output)
