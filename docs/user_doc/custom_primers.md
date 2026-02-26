# Using custom primers

## Disclaimer

While we try to provide pre-configured profiles for commonly used metabarcoding primers, it is also possible to provide primer information from the command line. Please note that you may have to adjust a number of default parameters to achieve good results - which we will discuss below. 

## From a parameter file

A clean way to feed your primer system to the pipeline is via a configuration file using the Nextflow argument `-params-file`. This command line flag accepts files in JSON or YAML format, with keys matching parameter names understood by the pipeline - including all the options needed to configure a primer profile. 

For example, if we wanted to pass the 16S ASU184 primer system from the command line:

```bash
nextflow run bio-raum/FooDMe2 -profile apptainer \\
-r 1.5.1 \\
-params-file 16S_primer.json \\
--input samples.tsv \\
--run_name TestRun
```

where the file 16S_primer.json looks as follows:
```JSON
{
    "database": "lrna",
    "fasta": "https://raw.githubusercontent.com/bio-raum/FooDMe2/refs/heads/main/assets/primers/16S_ASU184.fasta",
    "blast_low_complexity": "-dust no -soft_masking false",
    "blast_evalue": "1e-20",
    "blast_qcov": 100,
    "blast_perc_id": 97,
    "blast_bitscore_diff": 4,
    "blast_min_consensus": 0.51,
    "taxid_filter": 32524,
    "remove_chimera": true,
    "amplicon_min_length": 59,
    "amplicon_max_length": 95,
    "max_expected_errors": 2.0,
    "max_ns": 0,
    "merging_max_mismatch": 1,
    "fastp_options": "-l 50 -3 --cut_tail_window_size 4 --cut_tail_mean_quality 25",
    "cutadapt_trim_3p": true,
    "cutadapt_trim_flex": false,
    "cutadapt_options": "-m 40"
}
```

## From the command line

### Primer sequences

Primers must be provided as one Fasta file, containing the forward and reverse primer sequence(s). Ambiguous IUPAC bases are allowed, but please make sure that no non-IUPAC bases are included. A common example we have encountered in the literature is `I`, which is *not* part of the IUPAC nucleotide dictionary (replace with `N`). 

```bash
nextflow run bio-raum/FooDMe2 -profile apptainer --input samples.tsv --primers_fa primers.fasta ...
```

### Amplicon size

FooDMe2 filters sequences outside of the expected size range - so make sure to adjust the minumum and maximum size of the expected amplicons, with a bit of "buffer" up and down. 

Relevant parameters: `--amplicon_min_size` and `--amplicon_max_size`.

### Expected errors

Read processing requires information about the amount of errors that are to be expected in your data. 

Relevant parameter: `--max_expected_errors`.

The value can be calculated by multiplying the assumed error rate with the length of the amplicon. As an example - for an error rate of 0.025 (our default for Illumina) and an amplicon length of 315bp, the max expected error would be 7.9. 

Suggested error rates:

| Techbology | Error |
| ---------- | ----- |
| Illumina | 0.025 |
| IonTorrent | 0.05 |
| Nanopore | 0.05 |

Adjust as needed. 

### Database

You will have to specify which database to search against, using the --db argument. To get a list of pre-installed databases, use `--list_dbs`. 

### Taxonomic group

FooDMe2 restricts the search space to a specific taxononomic group.

Relevant parameters: `--taxid_filter`

Please specify the id of your taxonomic group of interest from the [NCBI taxonomy](https://www.ncbi.nlm.nih.gov/taxonomy) here. 

### Trimming

FooDMe2 can trim primer sites in multiple configurations. If you are using paired-end reads and each reads carries one of the primers, you don't have to do anything. However, if you are using single-end reads or paired-end reads where each read spans the entirety of the amplicon, some adustments are needed. 

`--cutadapt_trim_3p` - use when a read carries both primers. This is typically needed when short amplicons are sequenced paired-end as well as for single-end data - unless your reads are for some reason truncated. This can happen with ONT and IonTorrent as part of sequencing or library preparation (debug in the lab, if possible!). In that case, requesting three-prime trimming would reject a lot of reads.

`--cutadapt_ont` - use when you suspect three-prime trimming to be needed, but don't want to reject any reads where no primer site(s) was found (truncated reads).

`--cutadapt_trim_flex` - Trim primer sites in all possible configurations, but without applying rejection rules to the reverse search.