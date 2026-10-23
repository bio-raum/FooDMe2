# Supported sequencing technologies

## Overview

FooDMe was originally concieved as a workflow for paired-end Illumina short reads. As the portfolio of sequencing technologies broadens, it seemed only logical to consider supporting more technologies with a potential application in metabarcoding - namely IonTorrent short reads and Oxford Nanopore Technologies (ONT) long reads.

We intend to have completed support for these technologies by release 2.0 (2026). In the meantime, we are already making the initial implementations available with the expressed disclaimer that they are still heavily under development.

## Illumina short-reads (production)

Illumina paired-end short-reads were the basis for the original implementation of FooDMe. Their high base accuracy and throughput make them a very good option for metabarcoding projects, assuming the target amplicons can be covered by overlapping paired-end reads (< 850bp, depending on sequencing chemistry). Illumina reads are currently the most tested technology within FooDMe2 (and metabarcoding in general).

## IonTorrent short-reads (in development)

IonTorrent is an alternative short-read technology that works in single-end layout, with support for slightly longer individual read lengths than Illumina (up to 600 bp). The data is of moderate quality (we have seen a fraction of Q30 bases of 30-60% in test data available to us), and exhibits technology-specific homopolymer error profiles as well as dips in per-base quality at the beginning, in the middle and at the end of reads. 

This combination of inherent quality limitations make Torrent reads largely unsuitable for use with Dada2. For the built-in primer sets, FooDMe2 uses the alternative processing chain based on Vsearch instead. This is combined with additional backmapping of the raw read data onto the final set of OTUs to guage the true abundance of reads per OTU which may get skewed as a substantial fraction of reads are typically lost along the processing chain.

Outside of the pre-configured primer sets, you can enable IonTorrent data processing with the `--iontorrent` command line flag. Consider combining this with `--vsearch` as well as `--cutadapt_flex`. The latter enables single-end trimming that will also try to remove 3' primer sites -  but does not fail if none are found. This seems to be a common issue with longer amplicons on the platform. Finally, you will most likely need to adjust read trimming parameters. Our pre-configured primer sets use the following fastP trimming options (`--fastp_options`) for IonTorrent data:

`"--cut_tail --cut_tail_window_size 15 --cut_tail_mean_quality 15 --disable_adapter_trimming --trim_poly_g --poly_g_min_len 10"`

## Nanopore (ONT) (experimental, in development)

Nanopore is a low-throughout long-read technology with a comparatively higher error rate than both Illumina and IonTorrent as well as distinct homopolymer errors. However, the  technology has a much lower cost of ownership (~1/50th) compared to popular short-read technologies, can be used cost-efficiently even with small sample sizes and, importantly, allows the use of much larger amplicons than short-read technologies (> 1kb). 

Because of the higher error rate, FooDMe2 does not implement a clustering-based processing chain for Nanopore reads. Instead, all reads are mapped against a gene-specific target database using ONT-specific mapping parameters. The resulting alignments are then used to reconstruct "pseudo-OTUS" by "flipping" the mapped locus using any robustly observable sequence variants. These OTUs are subsequently filtered and clustered to generate a non-redundant set, equivalent to what is produced by the short-read worfklows. 

Initial tests suggests that this approach can deliver very comparable results to Illumina and IonTorrent worfklows. However, typical sequencing experiments with Nanopore will yield less data, which may reduce the detection limit and overall resolving power of the data set (ymmv).

Finally, please note that support for ONT data is **highly experimental** within FooDMe2 and we welcome your feedback on how to improve it. 

You can enable Nanopore data processing with the `--ont` command line flag. 
