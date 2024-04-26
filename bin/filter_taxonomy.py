#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Script to prune taxonomic assignments

import argparse
import sys
import taxidTools as txd

def main(nodes, lineage, taxid, out):
    tax = txd.Taxonomy.from_taxdump(nodes, lineage)
    tax.prune(taxid)
    tax.write(out)


if __name__ == '__main__':
    main(snakemake.params['nodes'],
        snakemake.params['rankedlineage'],
        snakemake.params['taxid'],
        snakemake.output['tax'])
