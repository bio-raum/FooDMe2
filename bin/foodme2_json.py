#!/usr/bin/env python
from datetime import datetime
import os
import glob
import json
import re
import argparse

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--output", "-o")
parser.add_argument("--yaml", "-y")
parser.add_argument("--sample", "-s")


args = parser.parse_args()


def parse_json(lines):
    data = json.loads(" ".join(lines))
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


def main(sample, yaml_file, output):

    files = [os.path.abspath(f) for f in glob.glob("*/*")]
    date = datetime.today().strftime('%Y-%m-%d')

    with open(yaml_file, "r") as f:
        yaml_lines = [line.rstrip() for line in f]

    versions = parse_yaml(yaml_lines)

    matrix = {
        "date": date,
        "sample": sample,
        "composition": {},
        "cutadapt": {},
        "blast": {"filtered": {}, "consensus": {}},
        "fastp": {"trim": {}, "input": {}},
        "software": versions
    }

    for file in files:

        with open(file, "r") as f:
            lines = [line.rstrip() for line in f]

        if re.search(".composition.json", file):
            matrix["composition"] = parse_json(lines)
        elif re.search(".cutadapt_mqc.json", file):
            matrix["cutadapt"] = parse_json(lines)
        elif re.search(".filtered.json", file):
            matrix["blast"]["filtered"] = parse_json(lines)
        elif re.search(".consensus.json", file):
            matrix["blast"]["consensus"] = parse_json(lines)
        elif re.search(".adaptertrim.fastp.json", file):
            matrix["fastp"]["input"] = parse_json(lines)
        elif re.search(".trim.fastp.json", file):
            matrix["fastp"]["trim"] = parse_json(lines)
        elif re.search(".dada_stats.json", file):
            matrix["dada2"] = parse_json(lines)[sample] # is a dict with the sample name as key, so we need the value for that

    with open(output, "w") as fo:
        json.dump(matrix, fo, indent=4, sort_keys=True)


if __name__ == '__main__':
    main(args.sample, args.yaml, args.output)
