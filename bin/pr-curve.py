#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import numpy as np
import pandas as pd
from sklearn.metrics import precision_recall_curve


sys.stderr = open(snakemake.log[0], "w")


def main(confmat, output):
    conf_table = pd.read_csv(confmat, sep="\t")

    # get classification metrics
    pr, rec, thr = precision_recall_curve(conf_table['expected'], conf_table['pred_ratio'])
    thr = np.append(thr, [1.0])  # Because scikit

    # Creating df from lists
    df = pd.DataFrame(
        list(zip(pr, rec, thr)),
        columns=['Precision', 'Recall', 'Theshold']
    )

    df.to_csv(output, sep="\t", header=True, index=False)


if __name__ == '__main__':
    main(
        confmat=snakemake.input['confmat'],
        output=snakemake.output['pr_curve'],
    )
