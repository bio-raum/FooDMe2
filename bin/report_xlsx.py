#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
from openpyxl import Workbook
from openpyxl.worksheet.dimensions import ColumnDimension, DimensionHolder
from openpyxl.utils import get_column_letter
from openpyxl.styles import Font, PatternFill
import glob
import csv

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--output")
args = parser.parse_args()


def main(output):

    bucket = {}

    # Get all the TSV files in this directory
    reports = sorted(glob.glob("*.tsv"))

    for report in reports:

        sample = report.split(".")[0]
        entries = []
        with open(report) as fd:
            rd = csv.DictReader(fd, delimiter="\t")
            for row in rd:
                entries.append(row)

        bucket[sample] = entries

    # Create an empty workbook and start page
    wb = Workbook()
    ws = wb.active
    ws.title = "FooDMe2 results"

    ft = Font(name="Sans", bold=True)
    cb_even = PatternFill(fill_type="solid", fgColor="d9e1f2")
    cb_uneven = PatternFill(fill_type="solid", fgColor="cdd1d9")

    # Track cell positions
    row = 0

    ws.append(["Sample", "Taxon", "Percentage", "Reads"])

    for r in ws["A1:D1"]:
        for cell in r:
            cell.font = ft

    this_sample = ""
    sample_counter = 0

    # Iterate over each sample and get taxonomy assignments
    for sample in bucket:

        if sample != this_sample:
            this_sample = sample
            sample_counter += 1

        if sample_counter & 1:
            bgcolor = cb_uneven
        else:
            bgcolor = cb_even

        hits = bucket[sample]

        for hit in hits:
            row += 1
            name = hit["name"]
            perc = round(float(hit["proportion"]), 4)*100
            reads = hit["reads"]
        
            ws.append([sample, name, perc, reads])

            ws["A"+str(ws._current_row)].fill = bgcolor
            ws["B"+str(ws._current_row)].fill = bgcolor
            ws["C"+str(ws._current_row)].fill = bgcolor
            ws["D"+str(ws._current_row)].fill = bgcolor


    # Auto-width for columns
    dim_holder = DimensionHolder(worksheet=ws)

    for column in range(ws.min_column, ws.max_column + 1):
        dim_holder[get_column_letter(column)] = ColumnDimension(ws, min=column, max=column, width=20)

    ws.column_dimensions = dim_holder

    ws.freeze_panes = ws["A2"]

    wb.save(output)


if __name__ == '__main__':
    main(args.output)
