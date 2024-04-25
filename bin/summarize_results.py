#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import sys


sys.stderr = open(snakemake.log[0], "w")


import pandas as pd


def concatenate_uniq(entries):
    s = "; ".join(entries.to_list())
    df = pd.DataFrame(
        [e.rsplit(" (", 1) for e in s.split("; ")], columns=["name", "freq"]
        )  # parenthesis in names
    df.loc[:, "freq"] = df["freq"].str.replace(")", "", regex=False).astype(float)
    # Aggreagte, normalize, and sort
    tot = df["freq"].sum()
    df = df.groupby("name").apply(lambda x: x.sum() / tot)
    df = df.sort_values(by=["freq"], ascending=False)
    # Format as string
    uniq = df.to_dict()["freq"]
    uniq = [f"{name} ({round(freq, 2)})" for name, freq in uniq.items()]
    return "; ".join(uniq)


def main(compo, report, sample):
    df = pd.read_csv(compo, sep="\t", header=0).fillna(0)

    # Empty input case
    if len(df["Query"]) == 1 and df["Query"].head(1).item() == "-":
        with open(report, "w") as fout:
            fout.write(
                "Sample\tConsensus\tRank\tTaxid\tCount\tDisambiguation\tPercent of total\tPercent of assigned"
            )

    else:
        groups = df.groupby(["Consensus", "Rank", "Taxid"]).agg(
            {"Count": "sum", "Disambiguation": concatenate_uniq}
        )
        groups = groups.sort_values("Count", ascending=False).reset_index()

        # Get percs of total
        groups["perc"] = round(groups["Count"] / groups["Count"].sum() * 100, 2)

        # Get percs of assigned
        assigned, notassigned = (
            groups[groups["Consensus"] != "-"],
            groups[groups["Consensus"] == "-"],
        )
        assigned["perc_ass"] = round(assigned["Count"] / assigned["Count"].sum() * 100, 2)
        notassigned["perc_ass"] = "-"
        groups = pd.concat([assigned, notassigned])

        # Formatting
        groups.insert(0, "Sample", sample)
        groups.rename(columns={"perc": "Percent of total",
                               "perc_ass": "Percent of assigned"},
                      inplace=True)
        groups["Consensus"].replace({"-": "No match"}, inplace=True)
        groups["Taxid"].replace({0: "-"}, inplace=True)
        groups.to_csv(report, sep="\t", index=False)


if __name__ == '__main__':
    main(snakemake.input['compo'],
         snakemake.output['report'],
         snakemake.params['sample_name'])
