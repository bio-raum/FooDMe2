# FooDMe2 Pipeline requirements

Below are some general guidelines to ensure that your data can be successfully analyzed by FooDMe2. 

## Computing

FooDMe2 is a comparatively light-weight pipeline and runs on a wide range of hardware, including your "average" laptop (for limitations, see [Database](#database)). At the same time, it is also capable of taking advantage of high-performance compute clusters, or "the cloud". 

At minimum, you will need 4 CPU cores, 8GB of Ram and ~5.GB of disk space for the reference databases (again, see [Database](#database) for exceptions). In addition, the pipeline requires storage space for the intermediate files and the final results - which will depend on the size of your input data. 

While Nextflow, and consequently FooDMe2, are technically compatible with Windows (through [WSL](https://learn.microsoft.com/en-us/windows/wsl/about)) and OSX, it is going to be easiest to run it on a Linux system. For more details, please see our [installation](installation.md) instructions. 

## Read count / sequencing depth

FooDMe2 results are meant to be quantitative and thus require a certain amount of reads for a sample to be considered for analysis. This number is controlled by the `--min_reads` parameter and was deliberately set to a very low value (5000) to catch samples that have obviously failed. Our community aims for 50.000-100.000 reads per sample, as a point of reference.  

## Primers

We try to provide pre-configured profiles for pcr primer sets that are commonly used in monitoring. That said, failed removal of primer sites can be a source of great frustration and will prevent FooDMe2 from working correctly. Please note that primer sequences should not be removed from the reads prior to running FooDMe2 since FooDMe2 uses the presence of primer sites as a criterion for inclusion of reads. In other words, all reads in which no primer sites were found, will be discarded. 

Custom primers should be provided in FASTA format, with no special characters in the sequence definition. Primers can include ambigious IUPAC bases and will be disambiguated directly within FooDMe2. 

If your amplicons are shorter than your average read length, make sure to use the appropriate option to ensure removal of primer sites from both ends of the reads (`--cutadapt_trim_3p`).

## Database

FooDMe2 ships with presumably all of the relevant databases for taxonomic assignment. However, these needs to be installed first - as described [here](installation.md)

We would recommend the use of the single gene databases, provided through [Midori](https://www.reference-midori.info/). However, FooDMe2 also provides access to larger databases - specifically NCBI GenBank ore_nt. Please note that Genbank has [grown](https://www.ncbi.nlm.nih.gov/genbank/statistics/) over the years, and even the core_nt database comes in at well over 200.GB. Running it will require a lot of RAM, depending on the taxonomic root for your analysis (`--taxid_filter`). For example, setting "amniotes" as the taxonomic root when using Genbank, will require roughly 60-80GB of RAM. In comparison, the same analysis against the Midori lRNA database (lrna) requires less than 3.GB RAM.

If you absolutely need to use a custom database, this is also supported as described [here](usage.md#--blast_db--default--null). 

