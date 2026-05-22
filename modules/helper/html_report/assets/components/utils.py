import os
from enum import Enum

import pandas as pd


class Mode(Enum):
    SINGLE = "SINGLE"
    PE_OVER = "PE_OVER"
    PE_NON = "PE_NON"
    ONT = "ONT"


def get_mode():
    return Mode(os.getenv("REPORT_MODE", default="PE_OVER"))


def collect_jsons(path: str = ".", debug: bool = False) -> list:
    if debug:
        path = os.getenv("REPORT_DATA")
    return [pos_json for pos_json in os.listdir(path) if pos_json.endswith('.summary.json')]


def collect_krona(path: str = ".", debug: bool = False) -> list:
    if debug:
        path = os.getenv("REPORT_DATA")
    return [fi for fi in os.listdir(path) if fi.endswith('_krona.html')]


def get_settings_file(path: str = ".") -> str:
    files = [pos_json for pos_json in os.listdir(path) if pos_json.startswith('params_')]
    return files.pop(0)


def clean_and_complete_distribution(df: pd.DataFrame) -> pd.DataFrame:
    """
    For each sample:
    - trim leading and trailing zeros
    - fill missing sizes in between with 0
    - ensure continuous size range per sample
    """

    if df.empty:
        return df

    non_zero = df[df["count"] != 0]
    bounds = non_zero.groupby("sample")["size"].agg(
        min_size="min",
        max_size="max"
    )

    df = df.merge(bounds, on="sample", how="left")
    df = df[
        (df["size"] >= df["min_size"]) &
        (df["size"] <= df["max_size"])
    ]
    df = df.drop(columns=["min_size", "max_size"])

    full_index = pd.MultiIndex.from_product(
        [
            df["sample"].unique(),
            range(df["size"].min(), df["size"].max() + 1),
        ],
        names=["sample", "size"],
    )

    df = (
        df.set_index(["sample", "size"])
          .reindex(full_index, fill_value=0)
          .reset_index()
    )

    return df