from enum import Enum
from typing import Literal
import json

import pandas as pd
import plotly.express as px
from plotly.graph_objects import Figure

from components.utils import Mode, clean_and_complete_distribution, get_nested


Read = Literal["r1", "r2"]
Step = Literal["before", "after"]


class View(Enum):
    COUNT = "count"
    PERC = "percent"


def get_insert_length_dist(file_list: list, fastp_label: str) -> pd.DataFrame:
    """
    parse Json into a size trace Dataframe
    fastp_label points to the json list object to be extracted
    """
    samples = []
    all_lengths = set()

    for json_file in file_list:
        with open(json_file) as f:
            jdata = json.load(f)

        sample = jdata["sample"]

        try:
            size = jdata[fastp_label]["insert_size"]["histogram"]
        except KeyError:
            size = []

        samples.append({
            "sample": sample,
            "size": size,
        })

        all_lengths.update(range(1, len(size) + 1))

    rows = [
        (sample["sample"], pos, sample["size"][pos - 1] if pos <= len(sample["size"]) else 0)
        for sample in samples
        for pos in sorted(all_lengths)
    ]

    df = pd.DataFrame(rows, columns=["sample", "size", "count"])

    return clean_and_complete_distribution(df)


def get_read_size_dist(file_list: list, label: str) -> pd.DataFrame:
    """
    parse Json into a size trace Dataframe
    label points to the json list object to be extracted
    """
    rows = []

    for json_file in file_list:
        with open(json_file) as f:
            jdata = json.load(f)

        sample = jdata["sample"]

        try:
            sizes = jdata[label]
        except KeyError:
            sizes = []

        rows.extend([
            (sample, pos["length"], pos["count"])
            for pos in sizes
        ])

    df = pd.DataFrame(rows, columns=["sample", "size", "count"])

    return clean_and_complete_distribution(df)


def get_qual(file_list: list, fastp_label: str, read_label: str) -> pd.DataFrame:
    """
    parse Json into a PHRED trace Dataframe
    fastp_label and read_label point to the json list object to be extracted
    """
    samples = []
    all_lengths = set()

    for json_file in file_list:
        with open(json_file) as f:
            jdata = json.load(f)

        sample = jdata["sample"]

        try:
            qual = jdata[fastp_label][read_label]["quality_curves"]["mean"]
        except KeyError:
            qual = []

        samples.append({
            "sample": sample,
            "qual": qual,
        })

        all_lengths.update(range(1, len(qual) + 1))

    rows = [
        (sample["sample"], pos, sample["qual"][pos - 1] if pos <= len(sample["qual"]) else None)
        for sample in samples
        for pos in sorted(all_lengths)
    ]

    return pd.DataFrame(rows, columns=["sample", "position", "qual"])


def json_to_df(file_list: list, address: list) -> pd.DataFrame:
    """
    parse Json into a count Dataframe, filling missing values with 0
    JSON value must be a list of key:value pairs corresponding to discrete category counts
    address is a list of nested json labels
    Returns a DataFrame with columns "sample", "label", "count"
    """
    samples = []
    all_labels = set()

    for json_file in file_list:
        with open(json_file) as f:
            jdata = json.load(f)

        sample = jdata["sample"]
        data = get_nested(jdata, address)

        all_labels.update(data.keys())

        samples.append({
            "sample": sample,
            "data": data,
        })

    rows = [
        (sample["sample"], label, sample["data"].get(label, 0))
        for sample in samples
        for label in all_labels
    ]
    return pd.DataFrame(rows, columns=["sample", "label", "count"])


def json_to_composition_df(file_list: list) -> pd.DataFrame:
    """
    Parse JSON files into a composition DataFrame, filling missing values with 0.
    JSON value must contain a "composition" field which is a list of dicts with keys:
    "name", "taxid", "reads", "rank", "proportion".

    Missing "composition" entries are treated as empty and filled with 0 counts.

    Returns a DataFrame grouped by "sample" and "rank" with summed "reads"
    and "proportion" converted to percentage.
    """
    all_rows = []

    for json_file in file_list:
        with open(json_file) as f:
            jdata = json.load(f)

        sample = jdata["sample"]
        data = jdata.get("composition", [])

        if not data:
            data = []

        for row in data:
            row = dict(row)
            row["sample"] = sample
            all_rows.append(row)

        if not data:
            all_rows.append({
                "sample": sample,
                "name": None,
                "taxid": None,
                "reads": 0,
                "rank": None,
                "proportion": 0,
            })

    df = pd.DataFrame(all_rows)

    df = (
        df.groupby(["sample", "rank"], as_index=False)[["reads", "proportion"]]
          .sum()
    )

    df["proportion"] = df["proportion"] * 100

    return df


def count_to_percent(df: pd.DataFrame) -> None:
    """Transform count df to percent df"""
    df["prop"] = 100*df["count"] / df.groupby("sample")["count"].transform("sum")


def placeholder_fig(text="Not implemented") -> Figure:
    """A Placholder figure with some text"""
    fig = px.scatter(template="simple_white")
    fig.update_layout(
        xaxis=dict(visible=False),
        yaxis=dict(visible=False),
        annotations=[dict(text=text, x=0.5, y=0.5, xref="paper", yref="paper", showarrow=False, font=dict(size=24))]
    )

    return fig


def bargraph(df: pd.DataFrame, xdata: str, xlabel: str, groups: str="label", hover_label="%{customdata}: %{x}%<extra></extra>") -> Figure:
    """
    Sandard horizontal bargraph
    xdata: dataframe col for x axis
    xlabel: x axis label
    groups: dataframe column for color grouping
    hover_label: custom hovertemplate text
    """
    fig = px.bar(
        df, x=xdata, y="sample", color=groups, custom_data=groups,
        labels={xdata: xlabel, "sample": ""},
        orientation='h', template="simple_white"
    )

    fig.update_layout(legend={'title_text': ''}, hovermode="y unified")
    fig.update_yaxes(showspikes=False)
    fig.update_traces(hovertemplate=hover_label)

    return fig


def insert_size_plot(json_files: list, mode: str, step: str) -> Figure:
    # PE overlapping
    if Mode(mode) == Mode.PE_OVER and step == "before":
        df = get_insert_length_dist(json_files, "fastp")
    elif Mode(mode) == Mode.PE_OVER and step == "after":
        df = get_insert_length_dist(json_files, "fastp_trimmed")
    # ONT
    elif Mode(mode) == Mode.ONT and step == "before":
        df = get_insert_length_dist(json_files, "nanoplot")
    elif Mode(mode) == Mode.ONT and step == "after":
        df = get_insert_length_dist(json_files, "nanoplot_trimmed")
    # Other
    elif step == "before":
        df = get_read_size_dist(json_files, "read_length_hist_pretrimming")
    elif step == "after":
        df = get_read_size_dist(json_files, "read_length_hist_postrimming")

    fig = px.line(
        df, x="size", y="count", color="sample", hover_name="sample",
        labels={"size": "Insert size (bp)", "count": "Read count"},
        line_shape="spline", template="simple_white"
    )
    fig.update_traces(hovertemplate="%{x}bp: %{y} reads")
    fig.update_layout(hovermode="closest")

    return fig


def read_quality_plot(json_files: list, mode: str, read: str, step: str) -> Figure:
    # ONT
    if Mode(mode) == Mode.ONT and step == "before":
        df = get_qual(json_files, "fastplong", "read_before_filtering")
    elif Mode(mode) == Mode.ONT and step == "after":
        df = get_qual(json_files, "fastplong_trimmed", "read_after_filtering")
    # Others
    elif read == "r1" and step == "before":
        df = get_qual(json_files, "fastp", "read1_before_filtering")
    elif read == "r1" and step == "after":
        df = get_qual(json_files, "fastp_trimmed", "read1_after_filtering")
    elif read == "r2" and step == "before":
        df = get_qual(json_files, "fastp", "read2_before_filtering")
    elif read == "r2" and step == "after":
        df = get_qual(json_files, "fastp_trimmed", "read2_after_filtering")

    fig = px.line(
        df, x="position", y="qual", color="sample", hover_name="sample",
        labels={"position": "Read position", "qual": "Sequence quality"},
        line_shape="spline", template="simple_white",
    )
    fig.update_traces(hovertemplate="#%{x}: %{y}")
    fig.update_layout(hovermode="closest", yaxis_range=[0, 40])

    return fig


def trimming_plot(file_list: list, mode: Mode, view: str) -> Figure:
    df = json_to_df(file_list, ["cutadapt"])
    xdata, xlabel = "count", "Read number"
    hover_label = "%{customdata}: %{x} reads<extra></extra>"
    if View(view) == View.PERC:
        xdata, xlabel = "prop", "Read proportion (%)"
        hover_label = "%{customdata}: %{x}%<extra></extra>"
        count_to_percent(df)

    return bargraph(df, xdata, xlabel, hover_label=hover_label)


def filter_plot(file_list: list, mode: Mode, view: View) -> Figure:
    if mode == Mode.ONT:
        df = json_to_df(file_list, ["fastplong_trimmed", "filtering_result"])
    else:
        df = json_to_df(file_list, ["fastp_trimmed", "filtering_result"])
    xdata, xlabel = "count", "Read number"
    hover_label = "%{customdata}: %{x} reads<extra></extra>"
    if View(view) == View.PERC:
        xdata, xlabel = "prop", "Read proportion (%)"
        hover_label = "%{customdata}: %{x}%<extra></extra>"
        count_to_percent(df)

    return bargraph(df, xdata, xlabel, hover_label=hover_label)


def cluster_plot(file_list: list, mode: Mode, view: View) -> Figure:
    df = json_to_df(file_list, ["clustering"])
    xdata, xlabel = "count", "Read number"
    hover_label = "%{customdata}: %{x} reads<extra></extra>"
    if View(view) == View.PERC:
        xdata, xlabel = "prop", "Read proportion (%)"
        hover_label = "%{customdata}: %{x}%<extra></extra>"
        count_to_percent(df)

    return bargraph(df, xdata, xlabel, hover_label=hover_label)


def taxonomy_plot(file_list: list, mode: Mode, view: View) -> Figure:
    df = json_to_composition_df(file_list)
    xdata, xlabel = "reads", "Read number"
    hover_label = "%{customdata}: %{x} reads<extra></extra>"
    if View(view) == View.PERC:
        xdata, xlabel = "proportion", "Read proportion (%)"
        hover_label = "%{customdata}: %{x}%<extra></extra>"

    return bargraph(df, xdata, xlabel, groups="rank", hover_label=hover_label)
