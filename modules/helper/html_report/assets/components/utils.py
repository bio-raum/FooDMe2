import os
from enum import Enum


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