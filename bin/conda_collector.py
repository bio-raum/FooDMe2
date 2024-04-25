#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys


sys.stderr = open(snakemake.log[0], "w")


import os
import yaml
import pandas as pd


def extract_package_version(envfile):
    with open(envfile, 'r') as stream:
        env = yaml.safe_load(stream)
        for dep in env['dependencies']:
            p, v = dep.split("=")
            yield p, v


def main(report, basedir):
    mypath = os.path.join(basedir, "envs")
    envs = [
        os.path.join(mypath, f) for f in os.listdir(mypath)
        if os.path.isfile(os.path.join(mypath, f)) and f.lower().endswith(('.yaml', '.yml'))
    ]
    df = []
    for ef in envs:
        for p, v in extract_package_version(ef):
            df.append({'Package': p, 'Version': v})
    df = pd.DataFrame(df)
    df.sort_values('Package').to_csv(report, sep="\t", header=True, index=False)


if __name__ == '__main__':
    main(
        report=snakemake.output['report'],
        basedir=snakemake.params['dir']
    )
