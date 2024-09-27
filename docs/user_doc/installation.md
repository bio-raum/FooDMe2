# Installation

If you are new to our pipeline ecosystem, we recommend you first check out our general setup guide [here](https://github.com/bio-raum/nf-configs/blob/main/doc/installation.md). 

## Installing nextflow

Nextflow is a highly portable pipeline engine. Please see the official [installation guide](https://www.nextflow.io/docs/latest/getstarted.html#installation) to learn how to set it up.

This pipeline expects Nextflow version 24.04.4, available [here](https://github.com/nextflow-io/nextflow/releases/tag/v24.04.4).

## Software provisioning

This pipeline is set up to work with a range of software provisioning technologies - no need to manually install packages!

You can choose one of the following options:

[Docker](https://docs.docker.com/engine/install/)

[Singularity](https://docs.sylabs.io/guides/3.11/admin-guide/)

[Podman](https://podman.io/docs/installation)

[Conda/Mamba](https://github.com/conda-forge/miniforge)

[Apptainer](https://apptainer.org/)

The pipeline comes with simple pre-set profiles for all of these as described below; if you plan to use this pipeline regularly, consider adding your own custom profile to our [central repository](https://github.com/bio-raum/nf-configs) to better leverage your available resources. Advantages of using custom profile include:

- possibility to cache environements and containers
- control ressources usage
- use additional container/package managers not pre-configured in FooDMe2, as described [here](https://www.nextflow.io/docs/latest/container.html).

Select the appropriate profile with the `-profile`argument:

=== "Conda/Mamba"

    ``` bash
    nextflow run bio-raum/FooDMe2 \
      -profile conda \
      -r main \
      --reference_base /path/to/references
    ```

=== "Docker"

    ``` bash
    nextflow run bio-raum/FooDMe2 \
      -profile docker \
      -r main \
      --reference_base /path/to/references
    ```

=== "Singularity"

    ``` bash
    nextflow run bio-raum/FooDMe2 \
      -profile singularity \
      -r main \
      --reference_base /path/to/references
    ```

=== "Podman"

    ``` bash
    nextflow run bio-raum/FooDMe2 \
      -profile podman \
      -r main \
      --reference_base /path/to/references
    ```

=== "Apptainer"

    ``` bash
    nextflow run bio-raum/FooDMe2 \
      -profile apptainer \
      -r main \
      --reference_base /path/to/references
    ```

=== "Site-specific"

    ``` bash
    nextflow run bio-raum/FooDMe2 \
      -profile myprofile \
      -r main \
      --reference_base /path/to/references # (1)!
    ```

    1. You can define `reference_base` in your site-specific profile and omit it in the command-line


## Installing the references

This pipeline requires locally stored references from [Midori](https://www.reference-midori.info/), [UNITE](https://unite.ut.ee/) and [NCBI](https://ftp.ncbi.nlm.nih.gov/blast/db) respectively. To build these, do:


=== "Default profile"

    ``` bash
    nextflow run bio-raum/FooDMe2 -profile conda \
      -r main \
      --build_references \
      --run_name build_refs \
      --reference_base /path/to/references \
    ```

=== "Site-specific profile"

    ``` bash
    nextflow run bio-raum/FooDMe2 -profile myprofile \
      -r main \
      --build_references \
      --run_name build \
      --reference_base /path/to/references # (1)!
    ```

    1. You can define `reference_base` in your site-specific profile and omit it in the command-line

where `/path/to/references` could be something like `/data/pipelines/references` or whatever is most appropriate on your system.

The path specified with `--reference_base` can then be given to the pipeline during normal execution as `--reference_base`.

Please note that the build process will create a pipeline-specific subfolder (`foodme2`) that must not be given as part of the `--reference_base` argument. FooDMe2 is part of a collection of pipelines that use a shared reference directory and it will choose the appropriate subfolder by itself.

!!! warning Skip Genbank

    In either case, this will download and format the various databases available through this pipeline. Please note that one of these databases is the full GenBank core_nt database, which has a final size of over 250GB (and growing), and will need around 0.5TB during installation. If your application works with single gene [databases](usage.md#database), you can skip installing this database with `--skip_genbank`. 

## Site-specific config file

If you run on anything other than a local system, this pipeline requires a site-specific configuration file to be able to talk to your cluster or compute infrastructure. Nextflow supports a wide range of such infrastructures, including Slurm, LSF and SGE - but also Kubernetes and AWS. For more information, see [here](https://www.nextflow.io/docs/latest/executor.html). In addition, a site-specific config file allows you to pre-set certain options specifically for your system and removes some of the complexity of the command line calls. 

Site-specific config-files for our pipeline ecosystem are stored centrally on [github](https://github.com/bio-raum/nf-configs). Please [talk to us](https://github.com/bio-raum/nf-configs/issues/new) if you want to add your system.
