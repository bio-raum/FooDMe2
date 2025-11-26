# Supported sequencing technologies

## Overview

FooDMe was originally concieved as a workflow for paired-end Illumina short reads. As the portfolio of sequencing technologies broadens, it seemed only logical to consider supporting more technologies with a potential application in metabarcoding - namely IonTorrent short reads and Oxford Nanopore Technologies (ONT) long reads.

We intend to have completed support for these technologies by release 2.0 (2026). In the meantime, we are already making the initial implementations available with the expressed disclaimer that they are still heavily under development.

## Illumina short-reads (production)

Illumina paired-end short-reads were the basis for the original implementation of FooDMe. Their high base accuracy and throughput make them a very good option for metabarcoding projects, assuming the target amplicons can be covered by overlapping paired-end reads (< 550bp). Illumina reads are currently the most tested technology within FooDMe2 (and metabarcoding in general).

## IonTorrent short-reads (in development)

IonTorrent is an alternative short-read technology that works in single-end layout, with longer individual read lengths than Illumina (up to 600 bp). The data is of high quality, but exhibits technology-specific homopolymer error profiles. Within FooDMe2, IonTorrent is processed with the Illumina tool chain and select modifications to account for homopolymer errors. The technology is limited to amplicons that fit within a single read (< 550 bp).

You can enable IonTorrent data processing with the `--iontorrent` command line flag.

## Nanopore (ONT) (experimental, in development)

Nanopore is a low-throughout long-read technology with a comparatively higher error rate than both Illumina and IonTorrent as well as distinct homopolymer errors. However, the  technology has a much lower cost of ownership (~1/100th) compared to popular short-read technologies, can be used cost-efficiently even with small sample sizes and, importantly, allows the use of much larger amplicons than short-read technologies (> 1kb). 

Because of the higher error rate, FooDMe2 does not implement a clustering-based processing chain for Nanopore reads. Instead, all reads are mapped against a gene-specific target database using ONT-specific mapping parameters. These alignments are then used to reconstruct "pseudo-OTUS" by "flipping" the mapped locus using any robustly observable sequence variants. These OTUs are subsequently filtered and clustered to generate a non-redundant set, equivalent to what is produced by the short-read worfklows. 

Initial tests suggests that this approach can deliver very comparable results to Illumina and IonTorrent worfklows. However, typical sequencing experiments with Nanopore will yield less data, which may reduce the detection limit and overall resolving power of the data set (ymmv).

Finally, please note that support for ONT data is **highly experimental** within FooDMe2 and we welcome your feedback on how to improve it. 

You can enable Nanopore data processing with the `--ont` command line flag. 
