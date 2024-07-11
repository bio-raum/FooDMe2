# Usage information

This is not a full release. Please note that some things may not work as intended yet.

[Running the pipeline](#running-the-pipeline)

[Pipeline version](#specifying-pipeline-version)

[Testing](#running-a-test)

[Options](#options)

- [Basic options](#basic-options)
- [Sequencing technology](#sequencing-technology)
- [PCR primers](#pcr-primers)
- [Database](#database)
- [Expert options](#expert-options)
- [Primer trimming](#pcr-primer-trimming)

## Running the pipeline

Please see our [installation guide](installation.md) to learn how to set up this pipeline first.

A basic execution of the pipeline looks as follows:

### Without a site-specific config file

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

### With a site-specific config file

```bash
nextflow run bio-raum/FooDMe2 -profile lsh \\
--input samples.csv \\
--run_name pipeline-test \\
--primer_set amniotes_dobrovolny
```

In this example, both `--reference_base` and the choice of software provisioning are already set in the  configuration `lsh` and don't have to provided as command line argument. In addition, in your site-specific configuration, you can set additional site-specific parameters, such as your local resource manager, node configuration (CPU, RAM, wall time), desired cache directory for the configured package/container software etc.

### Removing temporary data

Nextflow stores all the process data in a folder structure inside the `work` directory. All the relevant results are subsequently copied to the designated results folder (`--outdir`). The work directory is needed to resume completed or failed pipeline runs, but should be removed once you are satisified with the analysis to save space. To do so, run:

```bash
nextflow clean -f
```

## Specifying a pipeline version

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

where `your_profile` can either be a site-specific config file or one of the built-in [profiles](#without-a-site-specific-config-file). This test requires an active internet connection to download the test data. 

## Options

### Basic options

#### `--input samples.tsv` [default = null]

This pipeline expects a TSV-formatted sample sheet to properly pull various meta data through the processes. The required format looks as follows:

```TSV
sample  fq1 fq2
S100    /path/to/S100_R1.fastq.gz   /path/to/S100_R2.fastq.gz
```

If the pipeline sees more than one set of reads for a given sample ID (i.e. from multi-lane sequencing runs), it will concatenate them automatically at the appropriate time.

#### `--reference_base` [default = null ]

The location of where the pipeline references are installed on your system. This will typically be pre-set in your site-specific config file and is only needed when you run without one.

See our [installation guide](installation.md) to learn how to install the references permanently on your system.

#### `--outdir results` [default = results]

The location where the results are stored. Usually this will be `results` in the location from where you run the nextflow process. However, this option also accepts any other path in your file system(s).

#### `--run_name Fubar` [default = null]

A mandatory name for this run, to be included with the result files.

#### `--email me@google.com` [ default = null]

An email address to which the MultiQC report is send after pipeline completion. This requires for the executing system to have [sendmail](https://rimuhosting.com/support/settingupemail.jsp?mta=sendmail) configured.

### Sequencing technology

By default, the pipeline assumes that it is processing Illumina short-reads in paired-end configuration. Other supported sequencing technologies must be requested specifically with one of the following flags:

#### `--pacbio` [ default = false]
Reads are Pacbio HiFi after demultiplexing, in FastQ format. 

#### `--ont` [ default = false]
Reads are Nanopore/ONT after demultiplexing, chemistry 10.4.1 or later, in FastQ format. Please note that the read quality is critical here, so only the most recent chemistry versions are likely to work.  

#### `--iontorrent` [ default = false]
Reads are IonTorrent after demultiplexing, in FastQ format. 

### PCR primers

#### `--list_primers` [ default = false]

Get a list of pre-configured primer sets.

```bash
nextflow run bio-raum/FooDMe2 --list_primers
```

#### `--primer_set` [default = null]

The name of the pre-configured primer set to use for read clipping. More sets will be added over time

Available options:

- amniotes_dobrovolny (mammals and birds, as published by [Dobrovolny et al.](https://pubmed.ncbi.nlm.nih.gov/30309555/))

A list of pre-configured primer sets is also available from the pipeline directly, see [--list_primers](#--list_primers--default--false).

#### `--primers_fa` [default = null]

If you do not wish to use a pre-configured primer set, you can alternatively provide primer sequences in FASTA format. This option requires `--db` or `--blast_db` to choose the appropriate database to compare your data against.

### Database

Databases for taxonomic assignment can be specified in one of two ways - from the pre-installed references or as a user-supplied option.

#### `--list_dbs` 

You can get a list of available databases and their origin as follows:

```NEXTFLOW
nextflow run bio-raum/FooDMe2 --list_dbs
``` 

#### `--db` [default = null]

Use a pre-installed database (recommended!). Available options are (common choices in bold):

| name | source |
| ---- | ------ |
| a6 | Midori |
| a8 | Midori |
| **srna** | Midori |
| **lrna** | Midori |
| **co1** | Midori |
| co2 | Midori |
| co3 | Midori |
| **cytb** | Midori |
| **genbank** | NCBI |
| ncbi_its | NCBI |
| **its** | Unite |
| nd1 | Midori |
| nd2 | Midori |
| nd3 | Midori |
| nd4l | Midori |
| nd5 | Midori |
| nd6 | Midori |
| **refseq** | RefSeq |

The underlying databases are obtained from [Midori](https://www.reference-midori.info/), [Unite](https://unite.ut.ee/index.php) and [NCBI](https://ftp.ncbi.nlm.nih.gov/blast/db).

#### `--blast_db` [ default = null]
Provide your own blast database. This requires that the database has valid taxonomy IDs included and should only be attempted by experienced users. Databases must be created with the options `--parse_seqids` and `--taxid_map` using the NCBI taxonomy.

#### `--taxid_filter` [ default = null ]
In case you do not use a pre-configured [primer_set](#--primer_set-default--null), you will have to tell the pipeline a taxonomic group you wish to screen. The argument must be an ID from the [NCBI taxonomy](https://www.ncbi.nlm.nih.gov/taxonomy). Some common examples are:

| Taxonomic group | NCBI ID |
| --------------- | ------- |
| Amniotes        | 32524   |
| Mammals         | 40674   |
| Insects         | 50557   |
| Teleost fishes  | 32443   |

Please note that the deeper the node (i.e. the broader the search space), the more RAM will be required. This is not a concern for the single gene databases (e.g. Midori), but will be a significant factor when screening against GenBank NT. If you need to use GenBank NT and find that your jobs crash due to an out-of-memory error, consider using a shallower taxonomic node. 

### Expert options

Most users probably will not need to touch these options.

#### `--store_reads` [ default = false ]
Emit the primer-trimmed reads into the result folder. This option is mostly useful to debug errors that are related to failed primer site removal. This option is set to false by default to save storage space. 

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

### PCR primer trimming

Some possible usage examples:

```bash
nextflow run bio-raum/FooDMe2 -profile standard,conda --input samples.csv \\
--primer_set amniotes_dobrovolny \\
--run_name cutadapt-test
```

This example uses a built-in primer set to perform primer removal.

```bash
nextflow run bio-raum/FooDMe2 -profile standard,conda --input samples.csv \\
--primers_fa my_primers.fasta \\
--db srna \\
--run_name cutadapt-test
```

This example uses your custom primers, performs PCR primer site removal with cutadapt and performs taxonomic profiling against the srrna database.

```bash
nextflow run bio-raum/FooDMe2 -profile standard,conda --input samples.csv \\
--primer_set amniotes_dobrovolny \\
--cutadapt_trim_3p \\
--run_name cutadapt-test
```

This example will additionally reverse complement your primer sequences and check for primer binding sites at both ends of each read.

#### `--cutadapt_trim_3p` [ default = false ]
Use this option if you know that your read length is as long or longer than your PCR product. In this case, the reads will carry both the forward and reverse primer site - something that Cutadapt will normally fail to detect. 

#### `--cutadapt_options` [ default = "" ]
Any additional options you feel should be passed to Cutadapt. Use at your own risk. 

