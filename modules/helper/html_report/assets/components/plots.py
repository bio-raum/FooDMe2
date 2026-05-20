from enum import Enum
import json

import pandas as pd
import plotly.express as px
from plotly.graph_objects import Figure

from components.utils import Mode


class View(Enum):
    COUNT = "count"
    PERC = "percent"


def get_nested(data: dict, path: list, default=None):
    for key in path:
        if not isinstance(data, dict):
            return default
        data = data.get(key, default)
        if data is default:
            return default
    return data


def json_to_df(file_list:list, address: list) -> pd.DataFrame:
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
    samples = []
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


def bargraph(df, xdata, xlabel, groups="label", hover_label="%{customdata}: %{x}%<extra></extra>"):
    """Sandard horizontal bargraph
    xdata: dataframe col for x axis
    xlabel: x axis label
    groups: dataframe column for color grouping
    hover_label: custom hovertemplate text
    """
    fig = px.bar(
        df, x=xdata, y= "sample", color=groups, custom_data=groups,
        labels={xdata: xlabel, "sample": ""},
        orientation='h', template="simple_white"
    )

    fig.update_layout(legend={'title_text':''}, hovermode="y unified")
    fig.update_yaxes(showspikes=False)
    fig.update_traces(hovertemplate=hover_label)
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
        return placeholder_fig("Not implemented for ONT data.")

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
