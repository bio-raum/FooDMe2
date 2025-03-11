#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import glob
import sys
import os
import re

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--folder", "-f", help="path to read folder")
parser.add_argument("--output", "-o", help="Path to output file")
args = parser.parse_args()


EXTENSIONS = ["*.fastq.gz", "*.fq.gz", "*.fastq", "*.fq"]


def stripext(filename, extlist=EXTENSIONS):
    for ext in extlist:
        if filename.endswith(ext):
            return filename[: -len(ext)]
    return filename


# A function to derive a grouping variable from file names
def getgroup(path):

    filename = os.path.basename(path)

    # Regexps to try
    sra = re.compile("^[E,S]RR[0-9]*.*")  # ERR202156_1.fastq.gz
    illumina = re.compile("^.*_S[0-9]*_L00[0-9]_R[1,2].*")  # samplename_S01_L001_R1_001.fastq.gz

    if sra.match(filename):
        return filename.split("_")[0]  # ERR20215
    elif illumina.match(filename):
        return re.split(r"_R[1-2]", filename)[0]  # samplename_S01_L001
    else:
        # If we cannot guess the format, we remove extension
        # and then check if the remaining name ends on what might be the indicator of a read pair (_1, _2) - which we remove, if so.
        bsplit = stripext(filename)
        pair = re.compile(r"_[,R][1,2]|$")
        if pair.search(bsplit):
            return re.split(pair, bsplit)[0]
        else:
            return bsplit


def main(folder, output, extlist=EXTENSIONS):
    # Get all files endings from EXTENSIONS
    files = [os.path.abspath(f) for ext in extlist for f in glob.glob(os.path.join(folder, ext))]

    samples = {}

    ss = ["sample\tfq1\tfq2"]

    # pair files by name - handles single end too
    for file in files:
        grouping = getgroup(file)
        if grouping in samples:
            samples[grouping].append(file)
        else:
            samples[grouping] = [file]

    for lib, reads in samples.items():
        lanes = re.compile(r"_L00[0-9]$")
        # if this library has a lane indicator (L00x), make sure to group by lane
        if lanes.search(lib):
            trimmed_lib = lib.split("_L00")[0]
            sname = re.split(re.compile(r"_S[0-9]*"), trimmed_lib)[0]  # also remove sample number if present
            reads_by_lane = {}
            for read in reads:
                lane = read.split("L00")[-1][0]
                if lane in reads_by_lane:
                    reads_by_lane[lane].append(read)
                else:
                    reads_by_lane[lane] = [read]
            for lane, lreads in reads_by_lane.items():
                if (len(lreads) > 2):
                    raise ValueError(f"Dataset {lib} has more than two read files - something went wrong")
                lreads.sort()
                rdata = "\t".join(lreads)
                ss.append(f"{sname}\t{rdata}")
        # If no lane indicator is found, just go ahead.
        else:
            if (len(reads) > 2):
                raise ValueError(f"Dataset {lib} has more than two read files - something went wrong")
            reads.sort()
            rdata = "\t".join(reads)
            ss.append(f"{lib}\t{rdata}")

    # write to file
    with open(output, "w") as fo:
        for line in ss:
            fo.write(f"{line}\n")


if __name__ == '__main__':
    main(args.folder, args.output)
