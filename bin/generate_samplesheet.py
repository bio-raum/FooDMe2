#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import glob
import os
import re

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--folder", help="path to read folder")
parser.add_argument("--output", help="Path to output file")
args = parser.parse_args()


def main(folder, output):

    print("sample\tfq1\tfq2")

    files = [ os.path.abspath(f) for f in glob.glob(folder + "/*.fastq.gz") + glob.glob(folder + "/*.fq.gz") ]

    samples = {}

    for file in files:
        grouping = getgroup(file)
        print(grouping)
        if grouping in samples:
            samples[grouping].append(file)
        else:
            samples[grouping] = [file]

    for lib,reads in samples.items():
        print(f"{lib}\t{reads}")


# A function to derive a grouping variable from read names
def getgroup(read):

    readname = os.path.basename(read)
    
    # Regexps to try
    sra = re.compile("^[E,S]RR[0-9]*.*")
    illumina = re.compile("^.*_S[0-9]_L0[0-9]_R[1,2].*")

    if sra.match(readname):
        return readname.split("_")[0]
    elif illumina.match(readname):
        return readname.split("_L00")[0]
    else:
        # If we cannot guess the format, we remove the most likely extension (.fastq,.fq)
        # and then check if the remaining name ends on what might be the indicator of a read pair (_1, _2) - which we remove, if so.
        extensions = re.compile("\.[fastq,fq]")
        bsplit = re.split(extensions, readname)[0]
        pair = re.compile(r"_[,R][1,2]|$")
        if pair.search(bsplit):
            return re.split(pair,bsplit)[0]
        else:
            return bsplit
        

if __name__ == '__main__':
    main(args.folder, args.output)
