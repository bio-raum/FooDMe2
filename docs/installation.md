# Installation

## Installing nextflow

Nextflow is a highly portable pipeline engine. Please see the official [installation guide](https://www.nextflow.io/docs/latest/getstarted.html#installation) to learn how to set it up.

This pipeline expects Nextflow version 23.10.1, available [here](https://github.com/nextflow-io/nextflow/releases/tag/v23.10.1).

## Software provisioning

This pipeline is set up to work with a range of software provisioning technologies - no need to manually install packages. 

You can choose one of the following options:

[Docker](https://docs.docker.com/engine/install/)

[Singularity](https://docs.sylabs.io/guides/3.11/admin-guide/)

[Podman](https://podman.io/docs/installation)

[Conda](https://github.com/conda-forge/miniforge)

The pipeline comes with simple pre-set profiles for all of these as described [here](usage.md); if you plan to use this pipeline regularly, consider adding your own custom profile to our [central repository](https://github.com/marchoeppner/nf-configs) to better leverage your available resources.

## Installing the references

This pipeline requires locally stored genomes in fasta format. To build these, do:

```
nextflow run marchoeppner/eutaxpro -profile singularity \\
--build_references \\
--run_name build_refs \\
--outdir /path/to/references
```

where `/path/to/references` could be something like `/data/pipelines/references` or whatever is most appropriate on your system. 

If you do not have singularity on your system, you can also specify docker, podman or conda for software provisioning - see the [usage information](usage.md).

The path specified with `--outdir` can then be given to the pipeline during normal execution as `--reference_base`. Please note that the build process will create a pipeline-specific subfolder that must not be given as part of the `--outdir` argument. This pipeline is part of a collection of pipelines that use a shared reference directory and it will choose the appropriate subfolder by itself. 

## Site-specific config file

If you run on anything other than a local system, this pipeline requires a site-specific configuration file to be able to talk to your cluster or compute infrastructure. Nextflow supports a wide range of such infrastructures, including Slurm, LSF and SGE - but also Kubernetes and AWS. For more information, see [here](https://www.nextflow.io/docs/latest/executor.html).

Site-specific config-files for our pipeline ecosystem are stored centrally on [github](https://github.com/marchoeppner/nf-configs). Please talk to us if you want to add your system.