#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys


sys.stderr = open(snakemake.log[0], "w")


import numpy as np
import pandas as pd
import taxidTools as txd


def closest_node(taxid, ref_taxids, tax):
    """
    Find closest taxid in a list of refs

    returns closest reference
    """
    lcas = [tax.lca([taxid, tx]) for tx in ref_taxids]
    dists = [tax.distance(taxid, tx.taxid) for tx in lcas]
    return ref_taxids[np.argmin(dists)]


def format_rank(taxid, tax, ranks, target_rank):
    """
    Return node corresponding to target rank if it exists, otherwise
    return node at next corresponding rank for given taxid and rank list.

    If target_rank is None, returns node at next corresponding rank for given taxid and rank list.
    """
    lineage = txd.Lineage(taxid)
    lineage.filter(ranks)
    # Missing ranks ranks are replaced by DummyNodes
    if target_rank:
        try:
            target_node = [node for node in lineage if node.rank == target_rank][0]
            if target_node and not isinstance(target_node, txd.DummyNode):
                return target_node
            else:
                next_node = [node for node in lineage if not isinstance(node, txd.DummyNode)][0]
                return next_node
        except IndexError:
            return tax.get('1')
    else:
        try:
            next_node = [node for node in lineage if not isinstance(node, txd.DummyNode)][0]
            return next_node
        except IndexError:
            return tax.get('1')


def main(
        compo,
        truth,
        output,
        sample,
        threshold,
        target_rank,
        taxonomy
        ):
    # Part 1: Data prep --------------------------------------------

    # Ensure target_rank is linean
    # Waiting to think of a smartest solution
    # best I found so far is to use a normalized list of ranks
    # to ensure that input rank threhsold is valid and consistent with the reuslts.
    # This limits the choice to 'species' and 'genus' in practice (or higher)
    # but enforces consistency with NCBI taxonomy.
    # --> NCBI only Linnean is conserved between all organisms
    # and the other ranks or 'randomly' present.
    # Solution to think about:
    # hard-code an extendended rank list to use to filter the ranks?
    try:
        assert target_rank in txd.linne()
        ranks = txd.linne()+['no rank']
    except AssertionError:
        raise ValueError(f"Parameter 'target_rank' must be in {txd.linne()}")

    tax = txd.load(taxonomy)

    threshold = threshold/100  # Everything in the interval [0,1]

    # Load data
    compo_tbl = pd.read_csv(compo, sep="\t")
    truth_tbl = pd.read_csv(truth, sep="\t")

    # Filter truth table
    truth_tbl = truth_tbl.loc[truth_tbl['sample'] == sample]

    # Filter and normalize compo to range [0, 1] (input in %)
    compo_tbl = compo_tbl.loc[(compo_tbl['Taxid'] != "-")]
    compo_tbl['Percent of assigned'] = compo_tbl['Percent of assigned'].astype(float)/100

    # Preformating tables
    pred = pd.DataFrame(
        compo_tbl,
        columns=['Sample', 'Taxid', 'Count', 'Percent of assigned'],
        copy=True
    ).rename({
        'Sample': 'sample',
        'Taxid': 'taxid',
        'Count': 'read_count',
        'Percent of assigned': 'pred_ratio'
        }, axis=1)

    exp = pd.DataFrame(
        truth_tbl,
        columns=['sample', 'taxid', 'proportion'],
        copy=True
    ).rename({'proportion': 'exp_ratio'}, axis=1)

    # Part2: Checking the acceptability of predictions ---------------------

    # Adding prediction rank INDEX in the rank list
    pred['pred_rank'] = pred.apply(
        lambda x: ranks.index(format_rank(tax.get(str(x['taxid'])), tax, ranks, None).rank),
        axis=1,
    )

    # Normalize ranks to rank threshold if lower
    pred['norm_taxid'] = pred.apply(
        lambda x: format_rank(tax.get(str(x['taxid'])), tax, ranks, target_rank).taxid,
        axis=1,
    )

    pred['norm_rank'] = pred.apply(
        lambda x: tax.getRank(x['norm_taxid']),
        axis=1,
    )

    exp['norm_taxid'] = exp.apply(
        lambda x: format_rank(tax.get(str(x['taxid'])), tax, ranks, target_rank).taxid,
        axis=1,
    )

    # Find matches
    pred['ref_match'] = pred.apply(
        lambda x: closest_node(int(x['norm_taxid']), exp.loc[:, 'norm_taxid'].astype(int).to_list(), tax),
        axis=1,
    )

    # Get Lca of exp and pred matches to know what ranks correspond
    pred['match_rank'] = pred.apply(
        lambda x: format_rank(tax.lca([int(x['taxid']), int(x['ref_match'])]), tax, ranks, target_rank).rank,
        axis=1,
    )

    # Handle case where ref > normalized rank (e.g. looking for taxa at genus level but reference given at fam level)
    pred['norm_taxid'] = pred.apply(
        lambda x: x['ref_match'] if tax.isAncestorOf(int(x['ref_match']), int(x['norm_taxid'])) else x['norm_taxid'],
        axis=1,
    )

    # Reindex pred
    pred = pred.set_index(
        'norm_taxid'
    ).filter(
        items=['pred_ratio', 'pred_rank', 'norm_rank', 'ref_match', 'match_rank']
    )

    # Counts as predicted only if quantif above threshold and norm rank (NOT matching rank) is above min rank
    # Index of max accepted rank
    max_index = ranks.index(target_rank)

    pred['predicted'] = pred.apply(
        lambda x: 1 if (
            float(x['pred_ratio']) >= float(threshold)
        ) and (
            ranks.index(x['norm_rank']) <= max_index
        ) else 0,
        axis=1
    )

    # Reindex exp
    exp = exp.astype(
        {'norm_taxid': int}
    ).rename(
        columns={'norm_taxid': 'Taxid'}
    ).set_index(
        'Taxid'
    ).filter(
        items=['exp_ratio']
    )
    exp['expected'] = 1

    # Part 3: building confusion table ------------------------

    # reindex predicted using ref_match, keep taxid as info and sum ratios below the rank limit
    # This is to avoid merging data on assignement with too high rank for duplicated taxa
    pred['ref_match'] = [
        match_val if ranks.index(match_rank) <= max_index  # Leave as is if matching rank is under threshold
        else taxid_val  # Otherwise take the normalized taxid
        for taxid_val, match_val, match_rank in zip(pred.index, pred['ref_match'], pred['match_rank'])
    ]

    conftable = pred.reset_index(
        drop=True
    ).rename(
        columns={'ref_match': 'Taxid'}
    ).astype(
        {'Taxid': int}
    ).groupby(
        ["Taxid", "match_rank"]
    ).agg({'pred_ratio': 'sum',
           'pred_rank': lambda x: ranks[x.min()],
           'predicted': lambda x: 1 if x.max() > 0 else 0})

    conftable = conftable.reset_index(["match_rank"])
    conftable = conftable.astype({"match_rank": str, 'predicted': int, 'pred_ratio': float, 'pred_rank': str})
    exp = exp.astype({'expected': int, 'exp_ratio': float})

    conftable = conftable.join(
        exp,
        how='outer'
    )

    # Missing values are missagnignements!
    conftable = conftable.fillna(0)
    conftable = conftable.reset_index().rename(columns={'index': 'Taxid'})
    conftable["Sample"] = sample
    conftable['Name'] = conftable.apply(lambda x: tax.getName(int(x['Taxid'])), axis=1)
    conftable = conftable[[
        'Sample',
        'Taxid',
        'Name',
        'match_rank',
        'pred_rank',
        'predicted',
        'expected',
        'pred_ratio',
        'exp_ratio'
    ]]

    conftable.to_csv(output, sep="\t", header=True, index=False)


if __name__ == '__main__':
    main(
        compo=snakemake.input['compo'],
        truth=snakemake.input['truth'],
        output=snakemake.output['confmat'],
        sample=snakemake.params['sample'],
        threshold=snakemake.params['threshold'],
        target_rank=snakemake.params['target_rank'],
        taxonomy=snakemake.input['tax']
    )
