# Quickstart guide

This is a very short list of steps required to get your started with FooDMe2. Please see our complete [installation](installation.md) and [usage](usage.md) guides to answer any questions you are left with after reading this. 

## Installation

This pipeline is written in [Nextflow](https://nextflow.io/) and requires a fairly recent [version](https://github.com/nextflow-io/nextflow/releases) of Nextflow on your system. In addition, a software provisioning tool is needed (Docker, Conda, etc). If you need help with this, see [here](https://github.com/bio-raum/nf-configs/blob/main/doc/installation.md).

We recommend you also contribute a config file for your setup to our [central config repository](https://github.com/bio-raum/nf-configs/blob/main/doc/config.md). This will save you time down the road by setting certain options automatically based on your compute environment. 

For the example below, we will assume you use Conda (although we highly recommend using a container framework like Apptainer or Singularity!).

## Pipeline references

FooDMe2 requires locally stored, formatted databases. The pipeline has a [built-in](installation.md#installing-the-references) option to install these. 

``` bash
nextflow run bio-raum/FooDMe2 \ # (1)!
  -profile conda \ # (2)!
  -r main \ # (3)!
  --build_references \ # (4)!
  --reference_base /path/to/references \ # (5)!
  --run_name build \
  --skip_genbank
```

1.  Nextflow will fetch the pipeline directly from Github and cache a copy, there is no need to manualy download it.
2.  If you have a [site-specific config]((https://github.com/bio-raum/nf-configs/blob/main/doc/config.md)) you should provide it here. In there it is possible to define ressource usage, software deployment method and much more!
3.  The `-r` argument is always required, you can either provide `-r main` to use the last pipeline version or pin a release with e.g. `-r 1.0.0` (recommended).
4.  This instructs the pipeline to build the reference database.
5. The reference database path can also be part of a [site-specific config]((https://github.com/bio-raum/nf-configs/blob/main/doc/config.md)). Then it can be omitted here.


!!! info Nextflow arguments and pipeline options
    In the command above you can notice two different kinds of arguments.
    Those that start with a single dash (`-profile`, `-r`) are Nextflow arguments, and are documented in the [Nextflow documentation](https://www.nextflow.io/docs/latest/cli.html). Those starting with a double dash (`--build_reference`, `--run_name`) are FooDMe2 options and are detailled in the [usage section](usage.md)


## Run the test

Once everything is set up, you can run a short test to see if everything works as expected. 

``` bash
nextflow run bio-raum/FooDMe2 \
  -profile conda,test 
  -r main 
  --reference_base /path/to/references
```

where the conda profile can be replaced by whatever your [software provider](usage.md#running-the-pipeline) of choice is, e.g. `-profile singularity,test` or `-profile docker,test`.
