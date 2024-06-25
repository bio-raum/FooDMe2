#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import taxidTools


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--taxlist")
parser.add_argument("--taxid")
parser.add_argument("--taxonomy")
parser.add_argument("--output")
args = parser.parse_args()


def main(taxid_file, parent, output, taxonomy):

    tax = taxidTools.read_json(taxonomy)

    with open(taxid_file, "r") as fin:
        db_entries = set(fin.read().splitlines()[1:])

    with open(output, "w") as fout:
        for taxid in db_entries:
            try:
                if tax.isDescendantOf(str(taxid).strip(), str(parent).strip()):
                    fout.write(taxid + "\n")
                else:
                    pass
            except taxidTools.InvalidNodeError:
                pass  # Ignoring missing taxids as they are either not in the
                # taxdumps or actively filtered by the user.


if __name__ == '__main__':
    main(args.taxlist, args.taxid, args.output, args.taxonomy)
