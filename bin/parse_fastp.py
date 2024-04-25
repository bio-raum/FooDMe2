#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys


sys.stderr = open(snakemake.log[0], "w")


import os
import json
import csv


def main(injson, inhtml, outtsv):
    with open(injson, "r") as handle:
        data = json.load(handle)
        link_path = os.path.join("..", inhtml)
        header = (
            "Total bases before quality trim\tTotal reads after quality trim"
            "\tTotal bases after quality trim\tQ20 rate after\tQ30 rate after"
            "\tDuplication rate\tInsert size peak\tlink_to_report"
        )
        datalist = [
            data["summary"]["before_filtering"]["total_bases"],
            data["summary"]["after_filtering"]["total_reads"],
            data["summary"]["after_filtering"]["total_bases"],
            data["summary"]["after_filtering"]["q20_rate"],
            data["summary"]["after_filtering"]["q30_rate"],
            data["duplication"]["rate"],
            data["insert_size"]["peak"],
            link_path,
        ]
    with open(outtsv, "w") as outfile:
        outfile.write(f"{header}\n")
        writer = csv.writer(outfile, delimiter="\t")
        writer.writerow(datalist)


if __name__ == '__main__':
    main(snakemake.input['json'],
        snakemake.input['html'],
        snakemake.output['tsv'])
