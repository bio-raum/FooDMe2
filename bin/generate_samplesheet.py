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


def main(folder, output):

    ss = open(output, "w+")

    ss.write("sample\tfq1\tfq2\n")

    # Get all files ending in fastq.gz or fq.gz
    files = [os.path.abspath(f) for f in glob.glob(folder + "/*.fastq.gz") + glob.glob(folder + "/*.fq.gz")]

    samples = {}

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
            reads_by_lane = {}
            for read in reads:
                lane = read.split("L00")[-1][0]
                if lane in reads_by_lane:
                    reads_by_lane[lane].append(read)
                else:
                    reads_by_lane[lane] = [read]
            for lane, lreads in reads_by_lane.items():
                if (len(lreads) > 2):
                    sys.exit(f"Dataset {lib} has more than two read files - something went wrong :/")
                rdata = "   ".join(lreads)
                ss.write(f"{trimmed_lib}\t{rdata}\n")
        # If no lane indicator is found, just go ahead.
        else:
            if (len(reads) > 2):
                sys.exit(f"Dataset {lib} has more than two read files - something went wrong :/")
            rdata = "   ".join(reads)
            ss.write(f"{lib}\t{rdata}\n")

    ss.close()


# A function to derive a grouping variable from read names
def getgroup(read):

    readname = os.path.basename(read)

    # Regexps to try
    sra = re.compile("^[E,S]RR[0-9]*.*")
    illumina = re.compile("^.*_S[0-9]*_L00[0-9]_R[1,2].*")

    if sra.match(readname):
        return readname.split("_")[0]
    elif illumina.match(readname):
        return re.split(r"_R[1-2]", readname)[0]
    else:
        # If we cannot guess the format, we remove the most likely extension (.fastq,.fq)
        # and then check if the remaining name ends on what might be the indicator of a read pair (_1, _2) - which we remove, if so.
        extensions = re.compile(r"\.[fastq,fq]")
        bsplit = re.split(extensions, readname)[0]
        pair = re.compile(r"_[,R][1,2]|$")
        if pair.search(bsplit):
            return re.split(pair, bsplit)[0]
        else:
            return bsplit


if __name__ == '__main__':
    main(args.folder, args.output)
