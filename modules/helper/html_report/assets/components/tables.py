import json
import pandas as pd

from components.utils import Mode


def color_status(val):
    if val == "pass":
        color = "limegreen"
    elif val == "warn":
        color = "orange"
    elif val == "fail":
        color = "lightcoral"
    return f"background-color: {color}"


def summary_table(json_files: list, mode: Mode) -> pd.DataFrame:
    return pd.DataFrame([])


def version_table(json_files: list) -> pd.DataFrame:
    frames = []

    for json_file in json_files:

        with open(json_file) as f:
            versions = json.load(f)["versions"]

        df = pd.json_normalize(versions).T. rename(columns={0: "Version"})
        df.index = pd.MultiIndex.from_tuples(
            [col.split(".") for col in df.index],
            names=["Module", "Software"],
        )

        frames.append(df)
    if frames:
        return pd.concat(frames, axis=1).bfill(axis=1).iloc[:, 0].reset_index()
    return pd.DataFrame([])


def settings_table(settings_file: str) -> str:
    if not settings_file:
        return pd.DataFrame()

    with open(settings_file) as f:
        psettings = json.load(f)

    for key in ("maxMultiqcEmailFileSize", "primers", "references"):
        psettings.pop(key, None)

    return pd.DataFrame(
        sorted(psettings.items()),
        columns=["Setting", "Value"],
    )
