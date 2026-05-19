from enum import Enum

import pandas as pd
import plotly.express as px
from plotly.graph_objects import Figure

from components.utils import Mode


class View(Enum):
    COUNT = "count"
    PERC = "perc"


def trimming_plot(file_list: list, mode: Mode, view: View) -> Figure:
    df = pd.DataFrame(dict(
        x = [1, 3, 2, 4],
        y = [1, 2, 3, 4]
    ))
    fig = px.line(df, x="x", y="y", title="Unsorted Input")
    return fig


def filter_plot(file_list: list, mode: Mode, view: View) -> Figure:
    df = pd.DataFrame(dict(
        x = [1, 3, 2, 4],
        y = [1, 2, 3, 4]
    ))
    fig = px.line(df, x="x", y="y", title="Unsorted Input")
    return fig


def cluster_plot(file_list: list, mode: Mode, view: View) -> Figure:
    df = pd.DataFrame(dict(
        x = [1, 3, 2, 4],
        y = [1, 2, 3, 4]
    ))
    fig = px.line(df, x="x", y="y", title="Unsorted Input")
    return fig


def taxonomy_plot(file_list: list, mode: Mode, view: View) -> Figure:
    df = pd.DataFrame(dict(
        x = [1, 3, 2, 4],
        y = [1, 2, 3, 4]
    ))
    fig = px.line(df, x="x", y="y", title="Unsorted Input")
    return fig