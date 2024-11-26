# Usage information

## Running the pipeline

Please see our [installation guide](installation.md) to learn how to set up this pipeline first.

A basic execution of the pipeline looks as follows:

=== "Built-in profile"

    ``` bash
    nextflow run bio-raum/FooDMe2 \
      -profile conda \ # (1)!
      -r main \ # (2)!
      --input samples.tsv \
      --reference_base /path/to/references \ # (3)!
      --run_name pipeline-test \
      --primer_set amniotes_dobrovolny
    ```

    1.  In this example, the pipeline will assume it runs on a single computer with the conda engine. Available options to provision software are documented in the [installation section](installation.md).
    2.  We highly recommend pinning a release number(e.g. `-r 1.0.0`) instead of using the latest commit.
    3.  `path_to_references` corresponds to the location in which you have [installed](installation.md) the pipeline references.

=== "Site-specific profile"

    ``` bash
    nextflow run bio-raum/FooDMe2 
      -profile myprofile \ # (1)!
      -r main \ # (2)!
      --input samples.tsv \
      --run_name pipeline-test \
      --primer_set amniotes_dobrovolny
    ```

    1.  In this example, both `--reference_base` and the choice of software provisioning are already set in the  configuration `lsh` and don't have to provided as command line argument. In addition, in your site-specific configuration, you can set additional site-specific parameters, such as your local resource manager, node configuration (CPU, RAM, wall time), desired cache directory for the configured package/container software etc. It is highly recommended to [set up](installation.md) such a config file. 
    2.  We highly recommend pinning a release number(e.g. `-r 1.0.0`) instead of using the latest commit.

### Removing temporary data

Nextflow stores all the process data in a folder structure inside the `work` directory. All the relevant results are subsequently copied to the designated results folder (`--outdir`). The work directory is needed to resume completed or failed pipeline runs, but should be removed once you are satisified with the analysis to save space. To do so, run:

``` bash
nextflow clean -f
```

## Specifying a pipeline version

If you are running this pipeline in a production setting, you will want to lock the pipeline to a specific version. This is natively supported through nextflow with the `-r` argument:

``` bash
nextflow run bio-raum/FooDMe2 -profile myprofile -r 1.0.0 <other options here>
```

The `-r` option specifies a github [release tag](https://github.com/bio-raum/FooDMe2/releases) or branch, so could also point to `main` for the very latest code release. Please note that every major release of this pipeline (1.0, 2.0 etc) comes with a new reference data set, which has the be [installed](installation.md) separately.

## Running a test

This pipeline has a built-in test to quickly check that your local setup is working correctly. To run it, do:

``` bash
nextflow run bio-raum/FooDMe2 -profile myprofile,test
```

where `myprofile` can either be a site-specific config file or one of the built-in [profiles](installation.md#software-provisioning). This test requires an active internet connection to download the test data. 

## Command-line option

### Basic options

`--input samples.tsv` [default = null]

:   This pipeline expects a TSV-formatted sample sheet (tabulation-delimited text file) to properly pull various meta data through the processes. The required format looks as follows:

    ```TSV
    sample  fq1 fq2
    S100    /path/to/S100_R1.fastq.gz   /path/to/S100_R2.fastq.gz
    ```

    If the pipeline sees more than one set of reads for a given sample ID (i.e. from multi-lane sequencing runs), it will concatenate them automatically at the appropriate time.

    This option is the preferred way to provide data to FooDMe2 and it is mutually exclusive with `--reads`.

    !!! tip Automated sample sheet generation

        If you want to automatically generate sample sheets from files in a folder, check out the 
        `create_sampleSheet.sh` script from the BfR ABC Pipelines available [here](https://gitlab.com/bfr_bioinformatics/AQUAMIS/-/blob/master/scripts/create_sampleSheet.sh?ref_type=heads).

`--reads` [ default = null ]

:    This option is an alternative (but discouraged!) way to load data into FooDMe2 and expects a wildcard pattern to specify the location of files and how to group them. 

    Given a set of paired-end reads:

    ```
    Libary1-S01_R1_001.fastq.gz
    Libary1-S01_R2_001.fastq.gz
    Libary2-S02_R1_001.fastq.gz
    Libary2-S02_R1_001.fastq.gz
    ```

    data can be loaded like so (note the single-quotes around the search pattern!):
    
    ```
    nextflow run bio-raum/FooDMe2 -profile singularity --reads '/path/to/reads/*_R{1,2}_001.fastq.gz'
    ```

    which will be interpreted as two samples, Library1-S01 and Library2-S02, in paired-end configuration. It avoids having to create a samplesheet, but requires a well-constructed wildcard pattern to correctly match all the data as well as provides essentially no options to specifically name your samples or group reads across lanes. Read more about the underlying logic and options [here](https://www.nextflow.io/docs/latest/reference/channel.html#fromfilepairs).

    Here are a few examples for common file naming patterns:

    === "Illumina"

        Illumina paired-end file naming follows the convention:
    
        ```
        SampleName_SX_LYYY_R1_001.fastq.gz
        SampleName_SX_LYYY_R2_001.fastq.gz
        ```

        Where SX is the sample number and LYYY the lane number.
        These names can be parsed with the following pattern:

        ```
        '/path/to/reads/*_R{1,2}_001.fastq.gz'
        ```

        resulting in sample names being parsed as `SampleName_SX_LYYY`. However, as mentioned, there is no way to parse common sample names across lanes so you would need to merge multi-lane reads before using this input approach. 

    === "SRA/ENA"

        Data downloaded from online archives like SRA or ENA follow the convention:

        ```
        SampleName_1.fastq.gz
        SampleName_2.fastq.gz
        ```
        
        Which can be parsed with:

        ```
        '/path/to/reads/*_{1,2}.fastq.gz'
        ``` 

    === "Single-end data"

        Collecting single-end data is also possible and fairly straightforward:

        ```
        '/path/to/reads/*.fastq.gz'
        ```


`--reference_base` [default = null ]

:   The location where the pipeline references are installed on your system. This will typically be pre-set in your site-specific config file and is only needed when you run without one.

    See our [installation guide](installation.md) to learn how to install the references permanently on your system.

`--outdir results` [default = results]

:   The location where the results are stored. Usually this will be `results` in the location from where you run the nextflow process. However, this option also accepts any other path in your file system(s).

`--run_name Fubar` [default = null]

:   A mandatory name for this run, to be included with the result files.

`--email me@google.com` [ default = null]

:   An email address to which the MultiQC report is send after pipeline completion. This requires for the executing system to have [sendmail](https://rimuhosting.com/support/settingupemail.jsp?mta=sendmail) configured.

### Resources

The following options can be set to control resource usage outside of a site-specific [config](https://github.com/bio-raum/nf-configs) file.

`--max_cpus` [ default = 8]

:   The maximum number of cpus a single job can request. This is typically the maximum number of cores available on a compute node or your local (development) machine. 

`--max_memory` [ default = 16.GB ]

:   The maximum amount of memory a single job can request. This is typically the maximum amount of RAM available on a compute node or your local (development) machine, minus a few percent to prevent the machine from running out of memory while running basic background tasks.

`--max_time`[ default = 240.h ]

:   The maximum allowed run/wall time a single job can request. This is mostly relevant for environments where run time is restricted, such as in a computing cluster with active resource manager or possibly some cloud environments.  

### PCR primers

`--list_primers` [ default = false]

:   Get a list of pre-configured primer sets.

    ```bash
    nextflow run bio-raum/FooDMe2 --list_primers
    ```

`--primer_set` [default = null]

:   The name of the pre-configured primer set to use for read clipping. More sets will be added over time

    Available options:

    - amniotes_dobrovolny (mammals and birds, as published by [Dobrovolny et al.](https://pubmed.ncbi.nlm.nih.gov/30309555/))

    A list of pre-configured primer sets is also available from the pipeline directly, with `--list_primers`

`--primers_fa` [default = null]

:   If you do not wish to use a pre-configured primer set, you can alternatively provide primer sequences in FASTA format. This option requires `--db` or `--blast_db` to choose the appropriate database to compare your data against.
    Please make sure that your primer sequences only contain [IUPAC-compliant](https://www.bioinformatics.org/sms/iupac.html) bases.

### Database

Databases for taxonomic assignment can be specified in one of two ways - from the pre-installed references or as a user-supplied option.

`--list_dbs` 

:   You can get a list of available databases and their origin as follows:

    ```bash
    nextflow run bio-raum/FooDMe2 --list_dbs
    ``` 

`--db` [default = null]

:   Use a pre-installed database (recommended!). Available options are (common choices in bold):

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

`--blast_db` [ default = null]

:   Provide your own blast database. This requires that the database has valid taxonomy IDs included and should only be attempted by experienced users. Databases must be created with the options `--parse_seqids` and `--taxid_map` using the NCBI taxonomy.

`--taxid_filter` [ default = null ]

:   In case you do not use a pre-configured [primer_set](#pcr-primers), you will have to tell the pipeline a taxonomic group you wish to screen. The argument must be an ID from the [NCBI taxonomy](https://www.ncbi.nlm.nih.gov/taxonomy). Some common examples are:

    | Taxonomic group | NCBI ID |
    | --------------- | ------- |
    | Amniotes        | 32524   |
    | Mammals         | 40674   |
    | Insects         | 50557   |
    | Teleost fishes  | 32443   |

    Please note that the higher the node (i.e. the broader the search space), the more RAM will be required. This is not a concern for the single gene databases (e.g. Midori), but will be a significant factor when screening against GenBank NT. If you need to use GenBank NT and find that your jobs crash due to an out-of-memory error, consider using a shallower taxonomic node. 

### Benchmarking

It is possible to benchmark the pipelines performance against a set of known samples (e.g. for validation).
Therefore, predicted and expected components will be matched in a 'least distance' manner. A match will be deemed positive if the last common ancestor of both components
is at a maximum given rank and it's predicted (and expected) proportion in the sample is at least at a certain threshold.

Benchmarking is activated by providing following arguments:

`--ground_truth` [default = false]

:   Path to a tab-delimited text file giving expected sample composition. The file must be formatted as follows:

    ```TSV
    sample	taxid	proportion
    S100	9303	0.9
	S100	9013	0.1
	S200	9303	0.8
	S200	9313	0.2
    ```

    - `sample`: Sample name
    - `taxid`:Taxonomic identifier 
    - `proportion`: Expected proportion in the [0-1] interval, **not** in percent

`--benchmark_rank` [default = 'genus']

:   Maximum rank for a predicted match to be positive

`--benchmark_cutoff` [default = 0.001]

:   Minimum proportion to be considered predicted

### Expert options

Most users probably will not need to touch these options.

`--store_reads` [ default = false ]

:   Emit the primer-trimmed reads into the result folder. This option is mostly useful to debug errors that are related to failed primer site removal. This option is set to false by default to save storage space. 

`--blocklist`

:   Provide a list of NCBI taxonomy IDs (one per line) that should be masked from the BLAST database (and thus the result). FooDMe2 uses a built-in [block list](https://raw.githubusercontent.com/bio-raum/FooDMe2/main/assets/blocklist.txt) - but you can use this option to overwrite it, if need be. A typical use case would be a list of taxa that you know for a fact to be false positive hits. Consider merging your list with the built-in block list to make sure you mask previously identified problematic taxa. 

`--disable_low_complexity` [default = false]

:   By default, Blast with filter/main low complexity sequences. If your amplicons have very low complexity, you may wish to set this option to disable the masking of low complexity motifs.

	```bash
	nextflow run bio-ram/FooDMe2 
	-profile apptainer \
	--input samples.tsv \
	--disable_low_complexity ...
	```

`--non_overlapping` [default = false]

:   Toggle read concatenation instead of merging with an overlapping sequence. Works for both VSEARCH and DADA2 with paired-end reads. This is useful in case long amplicons and/or short sequencing reads lead to R1 and R2 having no overlap. Note that this applies to **all** reads.

`--vsearch` [ default = false ]

:   The default tool to compute OTUs/ASVs is DADA2. Use this option to run VSEARCH instead (short reads only).

`--vsearch_min_cov` [ default = 5 ]

:   The minimum amount of coverage required for an OTU to be created from the read data.

`--vsearch_cluster_id` [ default = 98 ]

:   The percentage similarity for ASUs to be collapsed into OTUs. If you set this to 100, ASUs will not be collapsed at all, which will generate a higher resolution call set at the cost of added noise. In turn, setting this value too low may collapse separate species into "hybrid" OTUs.
	The default of 98 seems to work quite well for our data, but will occasionally fragment individual taxa into multiple OTUs if sequencing error rate is high. For the TSV output, OTUs with identical taxonimic assignments will be counted as one, whereas the JSON output leaves this step to the user.

### PCR primer trimming

Some possible usage examples:

```bash
nextflow run bio-raum/FooDMe2 \-profile standard,conda --input samples.csv \\
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

This example uses your custom primers, performs PCR primer site removal with cutadapt and performs taxonomic profiling against the srRNA database.

```bash
nextflow run bio-raum/FooDMe2 -profile standard,conda --input samples.csv \\
--primer_set amniotes_dobrovolny \\
--cutadapt_trim_3p \\
--run_name cutadapt-test
```
This example will additionally reverse complement your primer sequences and check for primer binding sites at both ends of each read.

`--cutadapt_trim_3p` [ default = false ]

:   Use this option if you know that your read length is as long or longer than your PCR product. In this case, the reads will carry both the forward and reverse primer site - something that Cutadapt will normally fail to detect. 

`--cutadapt_options` [ default = "" ]

:   Any additional options you feel should be passed to Cutadapt. Use at your own risk. 

`--amplicon_min_length` [ default = 70 ]

:   The minimum size an amplicon is expected to have. Data that falls below this threshold will be discarded. This option does not need to be touched for pre-configured primer profiles. 

`--amplicon_max_length` [ default = 100 ]

:   The maximum size an amplicon is expected to have. Data that lies above this threshold will be discarded. This option does not need to be touched for pre-configured primer profiles. 
