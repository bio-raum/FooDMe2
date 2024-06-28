# Usage information

This is not a full release. Please note that some things may not work as intended yet.

[Running the pipeline](#running-the-pipeline)

[Pipeline version](#specifying-pipeline-version)

[Testing](#running-a-test)

[Options](#options)

- [Basic options](#basic-options)
- [Sequencing technology](#sequencing-technology)
- [Primer selection](#primer-selection)
- [Expert options](#expert-options)
- [Adapter trimming](#adapter-trimming)

## Running the pipeline

Please see our [installation guide](installation.md) to learn how to set up this pipeline first.

A basic execution of the pipeline looks as follows:

a) Without a site-specific config file

```bash
nextflow run bio-raum/FooDMe2 -profile singularity \\
--input samples.csv \\
--reference_base /path/to/references \\
--run_name pipeline-test \\
--primer_set amniotes_dobrovolny
```

where `path_to_references` corresponds to the location in which you have [installed](installation.md) the pipeline references.

In this example, the pipeline will assume it runs on a single computer with the singularity container engine. Available options to provision software are:

`-profile singularity`

`-profile docker`

`-profile podman`

`-profile conda`

`-profile apptainer`

b) with a site-specific config file

```bash
nextflow run bio-raum/FooDMe2 -profile lsh \\
--input samples.csv \\
--run_name pipeline-test \\
--primer_set amniotes_dobrovolny
```

In this example, both `--reference_base` and the choice of software provisioning are already set in the  configuration `lsh` and don't have to provided as command line argument. In addition, in your site-specific configuration, you can set additional site-specific parameters, such as your local resource manager, node configuration (CPU, RAM, wall time), desired cache directory for the configured package/container software etc.

## Specifying pipeline version

If you are running this pipeline in a production setting, you will want to lock the pipeline to a specific version. This is natively supported through nextflow with the `-r` argument:

```bash
nextflow run bio-raum/FooDMe2 -profile lsh -r 1.0 <other options here>
```

The `-r` option specifies a github [release tag](https://github.com/bio-raum/FooDMe2/releases) or branch, so could also point to `main` for the very latest code release. Please note that every major release of this pipeline (1.0, 2.0 etc) comes with a new reference data set, which has the be [installed](installation.md) separately.

## Running a test

This pipeline has a built-in test to quickly check that your local setup is working correctly. To run it, do:

```bash
nextflow run bio-raum/FooDMe2 -profile your_profile,test
```

This test requires an active internet connection to download the test data. 

## Options

### Basic options

#### `--input samples.tsv` [default = null]

This pipeline expects a TSV-formatted sample sheet to properly pull various meta data through the processes. The required format looks as follows:

```TSV
sample  fq1 fq2
S100    /path/to/S100_R1.fastq.gz   /path/to/S100_R2.fastq.gz
```

If the pipeline sees more than one set of reads for a given sample ID, it will concatenate them automatically at the appropriate time.

#### `--reference_base` [default = null ]

The location of where the pipeline references are installed on your system. This will typically be pre-set in your site-specific config file and is only needed when you run without one.

This option can be ommitted to trigger an on-the-fly temporary installation in the work directory. This is however not recommended as it creates unecessary traffic for the hoster of the references. See our [installation guide](installation.md) to learn how to install the references permanently on your system.

#### `--outdir results` [default = results]

The location where the results are stored. Usually this will be `results`in the location from where you run the nextflow process. However, this option also accepts any other path in your file system(s).

#### `--run_name Fubar` [default = null]

A mandatory name for this run, to be included with the result files.

#### `--email me@google.com` [ default = null]

An email address to which the MultiQC report is send after pipeline completion. This requires for the executing system to have [sendmail](https://rimuhosting.com/support/settingupemail.jsp?mta=sendmail) configured.

### Sequencing technology

By default, the pipeline assumes that it is processing Illumina short-reads in paired-end configuration. Other supported sequencing technologies must be requested specifically with one of the following flags:

#### `--pacbio` [ default = false]
Reads are Pacbio HiFi after demultiplexing, in FastQ format. 

#### `--ont` [ default = false]
Reads are Nanopore/ONT after demultiplexing, chemistry 10.4.1 or later, in FastQ format. 

#### `--torrent` [ default = false]
Reads are IonTorrent after demultiplexing, in FastQ format. 

### Primer selection

#### `--list_primers` [ default = false]

Get a list of pre-configured primer sets.

```bash
nextflow run bio-raum/FooDMe2 --list_primers
```

#### `--primer_set` [default = null]

The name of the pre-configured primer set to use for read clipping. More sets will be added over time

Available options:

- amniotes_dobrovolny (mammals and birds, as published by [Dobrovolny et al.](https://pubmed.ncbi.nlm.nih.gov/30309555/))

A list of available primer sets is also available from the pipeline directly, see [list](#--list_primers--default--false).

#### `--db` [default = null]

If you do not use a pre-configured primer set, you will also need to tell the pipeline which database you wish to use. Available options are (common choices in bold):

- a6
- a8
- **srna**
- **lrna**
- **co1**
- co2
- co3
- **cytb**
- **genbank_nt**
- ncbi_its
- **its**
- nd1
- nd2
- nd3
- nd4l
- nd5
- nd6
- **refseq**

The underlying databases are obtained from [Midori](https://www.reference-midori.info/), [Unite](https://unite.ut.ee/index.php) and [NCBI](https://ftp.ncbi.nlm.nih.gov/blast/db).

You can get a list of supported databases and their origin as follows:

```NEXTFLOW
nextflow run bio-raum/FooDMe2 --list_dbs
``` 

### Expert options

Only change these if you have a good reason to do so.

#### `--blocklist`
Provide a list of NCBI taxonomy IDs (one per line) that should be masked from the BLAST database (and thus the result). FooDMe 2 uses a built-in [block list](../assets/blocklist.txt) - but you can use this option to overwrite it, if need be. A typical use case would be a list of taxa that you know for a fact to be false positive hits.

#### `--disable_low_complexity [default = false]`
By default, Blast with filter/main low complexity sequences. If your amplicons have very low complexity, you may wish to set this option to disable the masking of low complexity motifs.

```bash
nextflow run bio-ram/FooDMe2 -profile singularity \\
--input samples.tsv \\
--disable_low_complexity ...
```

### `--vsearch` [ default = false ]
The default tool to compute OTUs/ASVs is DADA2. Use this option to run VSEARCH instead (short reads only).

#### `--vsearch_min_cov` [ default = 5 ]
The minimum amount of coverage required for an OTU to be created from the read data.

#### `--vsearch_cluster_id` [ default = 98 ]
The percentage similarity for ASUs to be collapsed into OTUs. If you set this to 100, ASUs will not be collapsed at all, which will generate a higher resolution call set at the cost of added noise. In turn, setting this value too low may collapse separate species into "hybrid" OTUs.
The default of 98 seems to work quite well for our data, but will occasionally fragment individual taxa into multiple OTUs if sequencing error rate is high. For the TSV output, OTUs with identical taxonimic assignments will be counted as one, whereas the JSON output leaves this step to the user.

### Adapter trimming

Some possible usage examples:

```bash
nextflow run bio-raum/FooDMe2 -profile standard,conda --input samples.csv \\
--primer_set amniotes_dobrovolny \\
--cutadapt \\
--run_name cutadapt-test
```

This example uses a built-in primer set but performs PCR primer site removal with Cutadapt instead of Ptrimmer.

```bash
nextflow run bio-raum/FooDMe2 -profile standard,conda --input samples.csv \\
--cutadapt \\
--primers_fa my_primers.fasta \\
--db srna \\
--run_name cutadapt-test
```

This example uses your custom primers, performs PCR primer site removal with cutadapt and performs taxonomic profiling against the srrna database.

```bash
nextflow run bio-raum/FooDMe2 -profile standard,conda --input samples.csv \\
--primer_set amniotes_dobrovolny \\
--cutadapt \\
--cutadapt_trim_3p \\
--run_name cutadapt-test
```

This example will additionally reverse complement your primer sequences and check for primer binding sites at both ends of each read.

#### `--cutadapt_trim_3p` [ default = false ]
Use this option if you know that your read length is as long or longer than your PCR product. In this case, the reads will carry both the forward and reverse primer site - something that Cutadapt will normally fail to detect. 

#### `--cutadapt_options` [ default = "" ]
Any additional options you feel should be passed to Cutadapt. Use at your own risk. 

#### `--primers_fa` [ default = null ]
Your primer sequences in FASTA format. There is no need to provide reverse-complemented sequences here if you wish to use `--cutadapt_trim_3p`, since the pipeline will do that automatically. If the primers in this file contain degenerate bases, the pipeline will automatically disambiguate them.

This option requires that you also specify a valid gene name (see above) so that the pipeline knows which database to use for taxonomic profiling. 

