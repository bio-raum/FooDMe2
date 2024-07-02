#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
from openpyxl import Workbook
from openpyxl.worksheet.dimensions import ColumnDimension, DimensionHolder
from openpyxl.utils import get_column_letter
import glob
import csv

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--output")
args = parser.parse_args()

def main(output):

    bucket = {}

    # Get all the TSV files in this directory
    reports = glob.glob("*.tsv")

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
    
    # Track cell positions
    row = 1
    col = 1

    sep = ";"

    d = ws.cell(row=row, column=col, value="Sample")
    d = ws.cell(row=row, column=col+1, value="Taxa")
    
    row += 1

    # Iterate over each sample and get taxonomy assignments
    for sample in bucket:
        d = ws.cell(row=row, column=col, value = sample)
        hits = bucket[sample]
        info = []
        for hit in hits:
            name = hit["name"]
            perc = round(float(hit["proportion"]),2)
            info.append(f"{name}:{perc}")
        d = ws.cell(row=row, column=col+1, value=sep.join(info))
        row += 1

    # Auto-width for columns
    dim_holder = DimensionHolder(worksheet=ws)

    for column in range(ws.min_column, ws.max_column + 1):
        dim_holder[get_column_letter(column)] = ColumnDimension(ws, min=column, max=column, width=20)

    ws.column_dimensions = dim_holder

    wb.save(output)

if __name__ == '__main__':
    main(args.output)
