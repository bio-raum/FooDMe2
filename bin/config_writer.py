#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys


sys.stderr = open(snakemake.log[0], "w")


import yaml


def main(default_config_file, params, output):
    """
    Update default YAML config with parameter set obtained from paramspace wildcards pattern
    """

    with open(default_config_file, 'r') as stream:
        config = yaml.safe_load(stream)

    config.update(params)

    dump = "\n".join([f"{k}: {v}" for k, v in config.items()])
    with open(output, 'w') as stream:
        stream.write(dump)


if __name__ == '__main__':
    main(
        default_config_file=snakemake.input['conffile'],
        params=snakemake.params['pspace'],
        output=snakemake.output['conf'],
    )
