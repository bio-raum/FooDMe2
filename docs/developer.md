# Developer's guide

This document is a brief overview of how to use this code base. Some understanding of Nextflow and how it implements DSL2 is assumed.

## Editor

We recommend [Microsoft Visual Studio Code](https://code.visualstudio.com/download) for working on nextflow pipelines. It's free and comes with a variety of free extensions to support your work.

This template specifically is set up to work with the following VS extensions:

- nextflow
- prettier
- groovy-lint
- TODO highlight
- Docker

## Basic concept

This pipeline base is organized in the following way:

* `main.nf` - entry point into the pipeline, imports the core workflow from `workflow/<pipeline>.nf`
* `workflow/<pipeline.nf>` - the actual core logic of the pipeline; imports sub-workflows from `subworkflow/<sub>.nf`
* `subworkflow/<sub>.nf` - a self-contained processing chain that is part of the larger workflow (e.g. read alignment and dedup in a WGS calling workflow)
* `modules/<module>.nf` - A command line tool/call that can be imported into a (sub)workflow.

## Config files

Some aspects of this code base are controlled by config files. These are:

`nextflow.config` -  this sets some of the command line options and default values

`conf/resources.config` - here you can put some pipeline-internal options, like locations of reference files and the like (assuming you use a generic base directory with fixed folder structure or S3 buckets)

`conf/base.config` - this file sets the computing specifications for different types of processes.

`/conf/modules.config` - module-specific settings and directives can be set here

## Groovy libraries

This pipeline imports a few functions into the nextflow files from lib/ - mostly to keep the actual pipeline code a bit cleaner/more readable. For example,
the `--help` command line option can be found in `lib/WorkflowMain.groovy`. Likewise, you could use this approach to do some basic validation of your inputs etc.

## Bioconda/biocontainers

By design, modules should provide software as either conda environment or container. See existing modules for how that can be achieved.

```bash
conda '${moduleDir}/environment.yml'
container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/multiqc:1.19--pyhdfd78af_0' :
    'quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0' }"
```

What does this do? Basically, if conda is enabled as software provider, the specified yaml file will be read to install a process-specific environment. Else, a container is pulled - where the source depends on whether you run Docker (native Docker image) or e.g. Singularity (dedicated singularity image).

We normally use Bioconda as the source for software packages; either directly via conda or through containers that are built directly from Bioconda. You'll note that each Bioconda package lists the matching Biocontainer link. For convenience, it is recommended to provide links to the native Biocontainer Docker container as well as the singularity version hosted by the Galaxy team under [https://depot.galaxyproject.org/singularity/](https://depot.galaxyproject.org/singularity/).

There are two situations where this approach will not work (directly). One is the use of multiple software packages in one pipeline process. While this can be done for conda-based provisioning by simply providing the name of multiple packages within the yaml file, it does not work for pre-built containers. Instead, you need a so-called "mulled" container; which are built from two or more Bioconda packages - described [here](https://github.com/BioContainers/multi-package-containers). Sometimes you can be lucky and find existing mulled containers that do what you need. Else - see the description above.

## Github workflows

Github supports the automatic execution of specific tasks on code branches, such as the automatic linting of the code base. To add github workflows to your repository, place them into the sub-directory `.github/workflows`.

### Linting

Nextflow does not have a dedicated linting tool. However, since most of nextflow is actually Groovy, the groovy linting suite works just fine, I find. Linting is set up as an automatic workflow for every push to the TEMPLATE and dev branch as well as pull requests.
You may wish to run this stand-alone also, before you commit your code. I would strongly recommend setting this up in a [conda](https://github.com/conda-forge/miniforge) environment, but it should also work on your *nix system directly (albeit with some minor pitfalls re: java version).

```bash
conda create -n nf-lint nodejs openjdk=17.0.10 flake8
conda activate nf-lint
npm install -g npm-groovy-lint
```

In your pipeline directory, you can check all the files in one go as follows:

```bash
npm-groovy-lint
flake8
```

You'll note that some obvious errors/warnings are omitted. This behavior is controlled by the settings in .groovylintrc [documentation](https://www.npmjs.com/package/npm-groovy-lint), included with this template. If you need to switch on some stuff, just add it the config file - and vice-versa.

Make sure that the local linting produces *no* messages (info, warning, error) or the automatic action will throw an error and flag the commit as "failed linting". This is not a deal breaker, but in principle should be fixed before merging into the `main` branch.

## Adding a new primer set

Primer sets consist of one or more primer pairs, meant to be used in a given experimental setup. A primer set should target a defined region in one of the supported mitochondrial genes. Primer sets are defined in [conf/primers](https://github.com/bio-raum/FooDMe2/blob/main/conf/primers.config) and should include the following information:

``` GROOVY
'amniotes_dobrovolny' {
  description = "Amniote primer set described in Dobrovolny et al. 2019"
  gene = "lrna"
  doi = "10.1016/j.foodchem.2018.08.032"
  maxee = 2.0
  minlen = 70
  maxlen = 100
  ptrimmer_config = "${baseDir}/assets/ptrimmer/par64_illumina.txt"
  fasta = "${baseDir}/assets/primers/par64_illumina.fasta"
  taxid_filter = 32524
}
```
In addition to supporting information and tool settings, please make sure to also include the corresponding primer FASTA file under [assets/primers](https://github.com/bio-raum/FooDMe2/tree/main/assets/primers).