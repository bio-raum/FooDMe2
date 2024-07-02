# FooDMe2 Pipeline requirements

Below are some general guidelines to ensure that your data can be successfully analyzed by FooDMe2. 

## Read count / sequencing depth

FooDMe2 requires a certain amount of reads for a sample to be considered for analysis. This number is controlled by the `--min_reads` parameter and was deliberately set to a very low value (5000) to catch samples that have obviously failed. Our community aims for 50.000-100.000 reads per sample, as a point of reference.  

## Primers

We try to provide pre-configured profiles for primer sets that are commonly used in monitoring. That said, failed removal of primer sites can be a source of great frustration and will prevent FooDMe2 from working correctly. Please note that primer sequences should not be removed from the reads prior to running FooDMe2 since FooDMe2 uses the presence of primer sites as a criterion for inclusion of reads. In other words, all reads in which no primer sites were found, will be discarded. 

Custom primers should be privided in FASTA format, with no special characters in the sequence definition. Primers can include ambigious IUPAC bases and will be disambiguated by FooDMe2. 

If your amplicons are shorter than your average read length, make sure to use the appropriate option to ensure removal of primer sites from both ends of the reads (`--cutadapt_trim_3p`).

## Database

FooDMe2 ships with presumably all of the relevant databases for taxonomic assignment. However, these needs to be installed first - as described [here](installation.md)

We would recommend the use of the single gene databases, provided through [Midori](https://www.reference-midori.info/). However, FooDMe2 also provides access to larger databases - specifically NCBI GenBank Eukaryotes. 

If you absolutely need to use a custom database, this is also supported as described [here](usage.md#--blast_db--default--null).

