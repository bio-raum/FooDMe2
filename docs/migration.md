# Migrating from FooDMe 1

If you are migrating from FooDMe1, welcome! We hope that you will find the process quite simple. We designed FooDMe2 to be more flexible and take away some of the complexity encountered in FooDMe 1. This not only concerns the installation procedure, which is vastly streamlined now, but also the process of configuring and starting individual analysis runs. We'll discuss some of the changes and updates below.

## Switch from Snakemake to Nextflow

Snakemake is a widely used "build" tool and has been adopted by a number of bioinformaticians to run so-called pipelines. That said, the core principle of Snakemake is not well suited for bioinformatic pipeline jobs as it is unable to deal with optional outputs or "failed" samples without some added complexity. It also has limited built-in support for different computing platforms and container frameworks, which restricts its portability.

We have thus decided to re-implement FooDMe using [Nextflow](https://nextflow.io/) to address three key areas - usability, maintainability and portability. Nextflow is a dedicated framework for bioinformatic pipeline development and is seeing growing adoption rates - such as by the [nf-co.re](https://nf-co.re/) project. Some of the key advantages of Nextflow are the seamless integration with numerous software provisioning frameworks and a top-down workflow design approach that more logically represents the actual flow of data. 

## Installation

We have re-visited the process of pipeline installation and decided to more tightly integrate it with the actual workflow. Whereas FooDMe 1 required users to clone the pipeline repository from Github, keep track of the cloned version of the code as well as run stand-alone bash scripts to download and format some of the required reference databases, this is now all done with Nextflow commands. All users need to do is to have a working installation of Nextflow and a software provisioning tool of choice (e.g. Singularity, Docker, Conda, etc) - that's it. You can check out more details in our [installation guide](installation.md).

Some advantages are:

- No manual cloning of code is needed
- Users can specify the desired version of the pipeline during start-up (no manual update/switching is needed)
- References are now version-locked to specific versions of the pipeline. 
- The default databases are now significantly smaller than in FooDMe 1 (3.5GB vs >100GB)
- No manual installation or creation of software environments is needed
- Support for most commonly used software provisioning frameworks (Docker, Singularity, Apptainer, Conda, Spack, ...)
- Compatible with many compute environments, including cloud infrastructures

## Scope

FooDMe 1 was designed for Illumina short reads in paired-end configuration. With FooDMe2, we decided to extend the scope to additional sequencing approaches - namely:

- ONT long reads (chemistry 10.4.3 and onwards)
- Pacbio HiFI Reads
- Ion Torrent

This added scope will allow labs to run data from different sequencing platforms through the same workflow and help with data interoperability as well as remove some of the clutter that comes from having multiple pipelines set up for what is essentially the same technical challenge. 

## Running a pipeline job

FooDMe2 removes some of the complexity encountered with FooDMe 1. For example, whereas FooDMe 1 required users to fill out somewhat lengthy configuration files in YAML format, FooDMe2 works with pre-configured [primer set profiles](usage.md#primer-selection) that set a range of options automatically (although these can be overwritten, if need be). Likewise, if users wanted to run different versions of the pipeline code, FooDMe 1 requires users to switch git release tags, or keep multiple copies of the code. Instead, FooDMe2 with the help of Nextflow hides the underlying complexity by simply exposing the desired release tag as a command line option (`-r VERSION`).

## In-/Outputs

While optimizing the usage over the old version, FooDMe2 maintains backwards compatibility with the FooDMe 1 sample sheet format and most of its outputs.

That said, we took a hard look to see if any of the outputs could be streamlined. We wanted to make it easier for users to get to the information that they needed without any added noise. To this end, we split the rather complex HTML report from FooDMe 1 into two separate files:

### Sequencing QC
- MultiQC report to summarize the sequence data metrics and software versions

### Results
- Krona reports to visualize the taxonomic composition of individual samples
- An XLSX table that summarizes all samples with all hits and their relative abundances



