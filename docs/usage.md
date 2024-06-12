# Usage information

This is not a full release. Please note that some things may not work as intended yet.

[Running the pipeline](#running-the-pipeline)

[Pipeline version](#specifying-pipeline-version)

[Options](#options)

[Expert options](#expert-options)

[Using Cutadapt](#using-cutadapt-instead-of-ptrimmer)

## Running the pipeline

Please see our [installation guide](installation.md) to learn how to set up this pipeline first.

A basic execution of the pipeline looks as follows:

a) Without a site-specific config file

```bash
nextflow run bio-raum/FooDMe2 -profile singularity --input samples.csv \\
--reference_base /path/to/references \\
--run_name pipeline-test \\
--primer_set par64_illumina
```

where `path_to_references` corresponds to the location in which you have [installed](installation.md) the pipeline references (this can be omitted to trigger an on-the-fly temporary installation, but is not recommended in production).

In this example, the pipeline will assume it runs on a single computer with the singularity container engine available. Available options to provision software are:

`-profile singularity`

`-profile docker`

`-profile podman`

`-profile conda`

b) with a site-specific config file

```bash
nextflow run bio-raum/FooDMe2 -profile lsh --input samples.csv \\
--run_name pipeline-test
```

In this example, both `--reference_base` and the choice of software provisioning are already set in the local configuration `lsh` and don't have to provided as command line argument. In addition, you can set additional site-specific parameters, such as your local resource manager, node configuration (CPU, RAM, wall time), desired cache directory for the configured package/container software etc.

## Specifying pipeline version

If you are running this pipeline in a production setting, you will want to lock the pipeline to a specific version. This is natively supported through nextflow with the `-r` argument:

```bash
nextflow run bio-raum/FooDMe2 -profile lsh -r 1.0 <other options here>
```

The `-r` option specifies a github [release tag](https://github.com/bio-raum/FooDMe2/releases) or branch, so could also point to `main` for the very latest code release. Please note that every major release of this pipeline (1.0, 2.0 etc) comes with a new reference data set, which has the be [installed](installation.md) separately.

## Options

### `--input samples.tsv` [default = null]

This pipeline expects a TSV-formatted sample sheet to properly pull various meta data through the processes. The required format looks as follows:

```TSV
sample  platform    fq1 fq2
S100    ILLUMINA    /path/to/S100_R1.fastq.gz   /path/to/S100_R2.fastq.gz
```

If the pipeline sees more than one set of reads for a given sample ID, it will concatenate them automatically at the appropriate time.

Allowed platforms are:

* ILLUMINA (expecting PE Illumina reads)
* NANOPORE (expecting ONT reads in fastq format)
* PACBIO (expecting Pacbio CCS reads in fastq format)
* TORRENT (expecting single-end IonTorrent reads in fastq format)

Note that only Illumina processing is currently enabled - the rest is "coming eventually". The column "platform" is thus optional - if it is not given, "ILLUMINA" is assumed as the default.

### `--primer_set` [default = null]

The name of the pre-configured primer set to use for read clipping. More sets will be added over time

Available options:

- par64_illumina (mammals and birds, as published by [Dobrovolny et al.](https://pubmed.ncbi.nlm.nih.gov/30309555/))

A list of available primer sets is also available from the pipeline directly as follows:

```bash
nextflow run bio-raum/FooDMe2 --list
```

Alternatively, you can specify your own primers as described in the following.

### `--primers_txt` [ default = null ]

If you wish to use a set of primers not already configured for this pipeline, you can provide it with this option. You will also have to specify which mitochondrial gene this primer set is targeting using the `--gene` option described elsewhere.

This text file will be read by [Ptrimmer](https://pubmed.ncbi.nlm.nih.gov/31077131/) to remove PCR primers from the adapter-clipped reads. Please see the Ptrimmer [documentation](https://github.com/DMU-lilab/pTrimmer) on how to create such a config file or look at the [example](../assets/ptrimmer/par64_illumina.txt) included with this pipeline.

Briefly, the file is a simple text format with each row representing one pair of primers, as follows:

```TSV
FORWARD_PRIMER_SEQ  REVERSE_PRIMER_SEQ  EXPECTED_PRODUCT_SIZE   NAME_OF_PRIMER
```

Note that the columns are tab-separated. The expected product size should be roughly correct, but doesn't need to accurate to the base. The primer sequences should represent the exact primer binding sequence.
If you use primers with overhanging ends for e.g., downstream ligation, these overhanging ends must not be part of the sequence listed here. Also note that Ptrimmer does not understand degenerate primer sequences. If this is an issue, please use [Cutadapt](#using-cutadapt-instead-of-ptrimmer) instead of Ptrimmer.

### `--gene` [default = null]

If you do not use a pre-configured primer set, you will also need to tell the pipeline which mitochondrial gene you are targeting. Available options are (common choices in bold):

- a6
- a8
- **srna**
- **lrna**
- **co1**
- co2
- co3
- **cytb**
- nd1
- nd2
- nd3
- nd4l
- nd5
- nd6

Curated databases for these genes are obtained from [Midori](https://www.reference-midori.info/).

### `--run_name Fubar` [default = null]

A mandatory name for this run, to be included with the result files.

### `--email me@google.com` [ default = null]

An email address to which the MultiQC report is send after pipeline completion. This requires for the executing system to have [sendmail](https://rimuhosting.com/support/settingupemail.jsp?mta=sendmail) configured.


### `--reference_base` [default = null ]

The location of where the pipeline references are installed on your system. This will typically be pre-set in your site-specific config file and is only needed when you run without one.

This option can be ommitted to trigger an on-the-fly temporary installation in the work directory. This is however not recommended as it creates unecessary traffic for the hoster of the references. See our [installation guide](installation.md) to learn how to install the references permanently on your system.

### `--outdir results` [default = results]

The location where the results are stored. Usually this will be `results`in the location from where you run the nextflow process. However, this option also accepts any other path in your file system(s).

## Expert options

Only change these if you have a good reason to do so.

### `--disable_low_complexity [default = false]`
By default, Blast with filter/main low complexity sequences. If your amplicons have very low complexity, you may wish to set this option to disable the masking of low complexity motifs.

```bash
nextflow run bio-ram/FooDMe2 -profile singularity \\
--input samples.tsv \\
--disable_low_complexity ...
```

### `--vsearch_min_cov` [ default = 5 ]
The minimum amount of coverage required for an OTU to be created from the read data.

### `--vsearch_cluster_id` [ default = 98 ]
The percentage similarity for ASUs to be collapsed into OTUs. If you set this to 100, ASUs will not be collapsed at all, which will generate a higher resolution call set at the cost of added noise. In turn, setting this value too low may collapse separate species into "hybrid" OTUs.
The default of 98 seems to work quite well for our data, but will occasionally fragment individual taxa into multiple OTUs if sequencing error rate is high. For the TSV output, OTUs with identical taxonimic assignments will be counted as one, whereas the JSON output leaves this step to the user.

## Using Cutadapt instead of Ptrimmer

Using Cutadapt is discouraged for most users as it requires more configuration and knowledge of your read data. It may thus not yield optimal results in all circumstances. It does however support degenerate primer sequences, which Ptrimmer does not.

Some possible usage examples:

```bash
nextflow run bio-raum/FooDMe2 -profile standard,conda --input samples.csv \\
--primer_set par64_illumina \\
--cutadapt \\
--run_name cutadapt-test
```

This example uses a built-in primer set but performs PCR primer site removal with Cutadapt instead of Ptrimmer.

```bash
nextflow run bio-raum/FooDMe2 -profile standard,conda --input samples.csv \\
--cutadapt \\
--primers_fa my_primers.fasta \\
--gene srna \\
--run_name cutadapt-test
```

This example uses your custom primers, performs PCR primer site removal with cutadapt and performs taxonomic profiling against the srrna database.

```bash
nextflow run bio-raum/FooDMe2 -profile standard,conda --input samples.csv \\
--primer_set par64_illumina \\
--cutadapt \\
--cutadapt_trim_3p \\
--run_name cutadapt-test
```

This example will additionally reverse complement your primer sequences and check for primer binding sites at both ends of each read.

### `--cutadapt` [ default = false ]

Use Cutadapt instead of Ptrimmer.

### `--cutadapt_trim_3p` [ default = false ]
Use this option if you know that your read length is as long or longer than your PCR product. In this case, the reads will carry both the forward and reverse primer site - something that Cutadapt will normally fail to detect.

### `--cutadapt_options` [ default = "" ]
Any additional options you feel should be passed to Cutadapt. Use at your own risk.

### `--primers_fa` [ default = null ]
Your primer sequences in FASTA format. There is no need to provide reverse-complemented sequences here if you wish to use `--cutadapt_trim_3p`, since the pipeline will do that automatically. If the primers in this file contain degenerate bases, the pipeline will automatically disambiguate them.

This option requires that you also specify a valid gene name (see above) so that the pipeline knows which database to use for taxonomic profiling.
