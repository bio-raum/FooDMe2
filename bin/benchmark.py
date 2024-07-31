#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json
import taxidTools


parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--compo", help="Path to composition table")  # name taxid rank proportion
parser.add_argument("--truth", help="Path to truth table")  # sample taxid proportion ...
parser.add_argument("--taxonomy", help="Path to taxonomy JSON")
parser.add_argument("--rank", help="max rank for positive result")
parser.add_argument("--cutoff", help="min frequency for positive results([0,1] interval)")
parser.add_argument("--results", help="path to results file")
parser.add_argument("--metrics", help="path to metrics file")
args = parser.parse_args()


def parse_table(path):
    """
    Extract coloumns with "name", "taxid" and "proportion"
    Returns a nested dict {id: {'taxids': [], 'freqs': []}}
    """
    bucket_id = {}
    bucket_freq = {}
    with open(path, "r") as fi:
        header = next(fi)
        header = [name.strip().lower() for name in header.split("\t")]
        index_id = header.index("name")
        index_taxid = header.index("taxid")
        index_freq = header.index("proportion")
        for line in fi:
            l = line.split("\t")
            # skip if Undetermined
            if l[index_taxid] == "Undetermined":
                continue
            bucket_id.setdefault(l[index_id].strip(), []).append(l[index_taxid].strip()) 
            bucket_freq.setdefault(l[index_id].strip(), []).append(float(l[index_freq].strip()))
    return {id: {"taxids": bucket_id[id], "freqs": bucket_freq[id]} for id in bucket_id.keys()}


def get_match(id, id_list):
    """Return match_id, distance, lca_id for closest match of id in id_list"""
    if not id_list:
        return None, None, None
    lcas = [tax.lca([id, e], ignore_missing=True).taxid for e in id_list]
    distances = [tax.distance(id, e) for e in lcas]
    index_corr = distances.index(min(distances))
    return id_list[index_corr], distances[index_corr], lcas[index_corr]


def compare_ids(left, right):
    """
    try to match taxids in left to taxids in right
    returns:
        - best matchs list
        - distance list 
        - lca of the two matching taxids list

    List order is the same as left
    """
    matches = []
    for id in left:
        matches.append(get_match(id, right))
    if not matches:
        return [], [], []
    return zip(*matches)


def evaluate_rank(taxid, max_rank):
    """Returns True if taxid is at or below max rank, False otherwise"""
    if tax[taxid].rank == max_rank:
        return True
    elif max_rank in [n.rank for n in tax.getAncestry(taxid)]:
        return True
    return False


def filter_freqs(d, cutoff):
    """
    filter d {'taxids': [], 'freqs':[]} to keep only indexes where freqs >= cutoff
    returns a copy of d
    """
    new = {}
    for id in d.keys():
        l = [(t, f) for t, f in zip(d[id]['taxids'], d[id]['freqs']) if f >= cutoff]
        taxids, freqs = zip(*l)
        new[id] = {'taxids': taxids, 'freqs': freqs}
    return new


def main(compo, truth, taxonomy, max_rank, cutoff, results_out, metrics_out):
    global tax
    tax = taxidTools.read_json(taxonomy)

    predicted = parse_table(compo, 0, 2, 4)
    expected = parse_table(truth, 0, 2, 3)

    ## Filter predicted and expected by freqs >= thrshold
    predicted = filter_freqs(predicted, cutoff)
    expected = filter_freqs(expected, cutoff)
    
    results, metrics = {}, {}

    for id in predicted.keys():
        # Get true positives and false positives
        # if sample is missing for truth table, then everything is false pos
        pred_matchs, pred_distances, pred_lcas = compare_ids(
            predicted[id]["taxids"],
            expected.get(id, {"taxid":[]})["taxids"],
            )
        # Filter for max rank and get a true (tp) /false (fp) list, only pos if above threshold!
        pred_correct = [evaluate_rank(taxid, max_rank) for taxid in pred_lcas]

        # Work in reverse for the false negatives True (tp) /false (fn) - nescesssary because multiple expected ids can be matched to single pred
        # use copy of expected taxids where already matched ones are gone
        expected_taxids = [id for id in expected.get(id, {"taxid":[]})["taxids"] if id not in pred_matchs]
        exp_matchs, exp_distances, exp_lcas = compare_ids(
            expected_taxids,
            predicted[id]["taxids"],
            )
        exp_found = [evaluate_rank(taxid, max_rank) for taxid in exp_lcas]

        # Metrics - handling special case div by 0 returns 0 (maybe None better?)
        if expected.get(id, {"taxid":[]})["taxids"]:
            recall = (sum(pred_correct) + sum(exp_found)) / len(expected.get(id, {"taxid":[]})["taxids"])
        else:
            recall = 0.0
        if pred_correct:
            precision = (sum(pred_correct) + sum(exp_found)) / len(pred_correct)
        else:
            precision = 0.0

        # jsonify 
        # {prediction: str, expect: str, match_rank: str, result: str, pred_freq: float, expect_freq: float}
        pred_correct = ["tp" if x else "fp" for x in pred_correct]
        exp_found = ["tp" if x else "fn" for x in exp_found]

        entry = []
        for i in range(len(predicted[id]["taxids"])):
            entry.append({
                'prediction': predicted[id]["taxids"][i],
                'expect': pred_matchs[i],
                'match_rank': tax[pred_lcas[i]].rank,
                'result': pred_correct[i],
                'pred_freq': predicted[id]["freqs"][i],
                'expect_freq': expected[id]["freqs"][expected[id]["taxids"].index(pred_matchs[i])],
            })
        for i in range(len(expected_taxids)):
            entry.append({
                'prediction': exp_matchs[i],
                'expect': expected_taxids[i],
                'match_rank': tax[exp_lcas[i]].rank,
                'result': exp_found[i],
                'pred_freq': predicted[id]["freqs"][predicted[id]["taxids"].index(exp_matchs[i])],
                'expect_freq': expected[id]["freqs"][expected[id]["taxids"].index(expected_taxids[i])],
            })
        results[id] = entry
        metrics[id] =  {'recall': recall, 'precision': precision}

    # dump JSONs
    with open(results_out) as fo:
        json.dump(results, fo, indent=4)
    with open(metrics_out) as fo:
        json.dump(metrics, fo, indent=4)


if __name__ == '__main__':
    main(
        args.compo,
        args.truth,
        args.taxonomy,
        args.rank,
        args.cutoff,
        args.results,
        args.metrixs,
        )