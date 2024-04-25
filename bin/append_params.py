#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys


sys.stderr = open(snakemake.log[0], "w")


import pandas as pd


def main(
    benchmarkin, confmatin, yieldsin, metricsin, pr_curvein,
    benchmarkout, confmatout, yieldsout, metricsout, pr_curveout,
    pspace,
):

    for fin, fout in [
        (benchmarkin, benchmarkout),
        (confmatin, confmatout),
        (yieldsin, yieldsout),
        (metricsin, metricsout),
        (pr_curvein, pr_curveout),
    ]:
        tbl = pd.read_csv(fin, sep="\t")
        for k, v in pspace.items():
            tbl[k] = v
        tbl.to_csv(fout, sep="\t", header=True, index=False)


if __name__ == '__main__':
    main(
        benchmarkin=snakemake.input['benchmark'],
        confmatin=snakemake.input['confmat'],
        yieldsin=snakemake.input['yields'],
        metricsin=snakemake.input['metrics'],
        pr_curvein=snakemake.input['pr_curve'],
        benchmarkout=snakemake.output['benchmark'],
        confmatout=snakemake.output['confmat'],
        yieldsout=snakemake.output['yields'],
        metricsout=snakemake.output['metrics'],
        pr_curveout=snakemake.output['pr_curve'],
        pspace=snakemake.params['pspace'],
    )
