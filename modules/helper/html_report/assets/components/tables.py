import json
import pandas as pd
from pandas.io.formats.style import Styler

from components.utils import Mode, get_nested


PE_OVER_MAPPING = {
    "read_length": ["fastp", "insert_size", "peak"],
    "reads_total": ["fastp", "summary", "before_filtering", "total_reads"],
    "qual": ["fastp", "summary", "before_filtering", "q30_rate"],
    "reads_passing": ["fastp_trimmed", "summary", "after_filtering", "total_reads"],
    "reads_after_clustering": ["clustering", "passing"],
    "chimeras": ["clustering", "chimeras"],
}

PE_NON_MAPPING = {
    "read_length": ["fastp", "summary", "before_filtering", "read1_mean_length"],
    "reads_total": ["fastp", "summary", "before_filtering", "total_reads"],
    "qual": ["fastp", "summary", "before_filtering", "q30_rate"],
    "reads_passing": ["fastp_trimmed", "summary", "after_filtering", "total_reads"],
    "reads_after_clustering": ["clustering", "passing"],
    "chimeras": ["clustering", "chimeras"],
}

SINGLE_MAPPING = {
    "read_length": ["fastp", "summary", "before_filtering", "read1_mean_length"],
    "reads_total": ["fastp", "summary", "before_filtering", "total_reads"],
    "qual": ["fastp", "summary", "before_filtering", "q30_rate"],
    "reads_passing": ["fastp_trimmed", "summary", "after_filtering", "total_reads"],
    "reads_after_clustering": ["clustering", "passing"],
    "chimeras": ["clustering", "chimeras"],
}

ONT_MAPPING = {
    "read_length": ["fastplong_trimmed", "summary", "after_filtering", "read_mean_length"],
    "reads_total": ["fastp_long", "summary", "before_filtering", "total_reads"],
    "qual": ["fastp_long", "summary", "before_filtering", "q20_rate"],
    "reads_passing": ["fastplong_trimmed", "summary", "after_filtering", "total_reads"],
    "reads_after_clustering": ["clustering", "passing"],
    "chimeras": ["clustering", "chimeras"],
}

SUMMARY_HEADER = [
    "Sample",
    "Status",
    "Reads total",
    "Reads Q30 (%)",
    "Insert size peak (bp)",
    "Reads passing",
    "Reads filtered",
    "Reads after clustering",
    "Chimeric reads"
]


def safe_zero_div(quot, num):
    """returns 0 on null numerator"""
    try:
        return quot/num
    except ZeroDivisionError:
        return 0


def color_status(val: str) -> str:
    match val:
        case "pass":
            color = "limegreen"
        case "warn":
            color = "orange"
        case "fail":
            color = "lightcoral"
        case _:
            color = "gray"
    return f"background-color: {color}"


def tooltips(df, cols, mode: Mode) -> pd.DataFrame:
    if mode == Mode.ONT:
        qual_ttip = "Fraction of input reads >= Q20"
    else:
        qual_ttip = "Fraction of input reads >= Q20"
    if mode != Mode.PE_OVER:
        insert_ttip = "The mean of read lengths"
    else:
        insert_ttip = "Insert size peak"

    ttips = pd.DataFrame(
        {k: v for k, v in zip(
            cols[1:],
            [
                "The overall analysis status: pass: ok to use, warn: potential issues found, fail: most probably not usable",
                "The number of reads before any processing",
                qual_ttip,
                insert_ttip,
                "The number of reads passing the primer and quality trimming",
                "The number of reads not passing the primer and quality trimming",
                "The number of reads remaining after clustering",
                "Reads classified as chimera during the clustering"
            ]
        )}, index=df.index
    )

    return ttips


def summary_row(jdata: dict, mode: Mode) -> list:
    match mode:
        case Mode.PE_OVER:
            mapping = PE_OVER_MAPPING
        case Mode.PE_NON:
            mapping = PE_NON_MAPPING
        case Mode.SINGLE:
            mapping = SINGLE_MAPPING
        case Mode.ONT:
            mapping = ONT_MAPPING
        case _:
            raise ValueError(f"Invalid case {mode}")

    data = {label: get_nested(jdata, path, 0) for label, path in mapping.items()}

    # Format values
    reads_total = int(data["reads_total"]/2 if mode in [Mode.PE_OVER, Mode.PE_NON] else data["reads_total"])
    qual = round(data["qual"]*100, 2)
    reads_passing = int(data["reads_passing"]/2 if mode in [Mode.PE_OVER, Mode.PE_NON] else data["reads_passing"])
    reads_filtered = reads_total - reads_passing

    # Check QC
    qc_status = "pass"
    for k in ["reads_total", "reads_passing", "reads_after_clustering"]:
        if data[k] == 0:
            qc_status = "fail"
    if "composition" not in jdata.keys():
        qc_status = "fail"
    elif mode == Mode.ONT and reads_passing < 0.6 * reads_total:
        qc_status = "warn"
    elif reads_passing < 0.8 * reads_total:
        qc_status = "warn"

    row = [
        jdata["sample"],
        qc_status,
        reads_total,
        qual,
        data["read_length"],
        f"{reads_passing} ({round(safe_zero_div(reads_passing, reads_total)*100, 2)}%)",
        f"{reads_filtered} ({round(safe_zero_div(reads_filtered, reads_total)*100, 2)}%)",
        f"{data['reads_after_clustering']} ({round(safe_zero_div(data['reads_after_clustering'], reads_total)*100, 2)}%)",
        f"{data['chimeras']} ({round(safe_zero_div(data['chimeras'], reads_total)*100, 2)}%)",
    ]

    return row


def summary_table(json_files: list, mode: str) -> Styler:
    rows = []

    for json_file in json_files:
        with open(json_file) as f:
            jdata = json.load(f)

        row = summary_row(jdata, Mode(mode))
        rows.append(row)

    if Mode(mode) != Mode.PE_OVER:
        SUMMARY_HEADER[4] = "Mean read length (bp)"
    if Mode(mode) == Mode.ONT:
        SUMMARY_HEADER[3] = "Reads Q320 (%)"

    df = pd.DataFrame(rows, columns=SUMMARY_HEADER)
    styler = df.style.map(
        color_status, subset=pd.IndexSlice[:, ["Status"]]
    ).set_tooltips(
        tooltips(df, SUMMARY_HEADER, Mode(mode))
    ).format(
        {
            SUMMARY_HEADER[3]: "{:.2f}",
        }
    )

    return styler


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
