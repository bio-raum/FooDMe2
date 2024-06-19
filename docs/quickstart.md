# Quickstart guide

This is a very short list of steps required to get your started with FooDMe 2. Please see our complete [installation](installation.md) and [usage](usage.md) guides to answer any questions you are left with after reading this. 

## 1. Installation

This pipeline is written in [Nextflow](https://nextflow.io/) and requires a fairly recent [version](https://github.com/nextflow-io/nextflow/releases) of Nextflow on your system. In addition, a software provisioning tool is needed (Docker, Conda, etc). If you need help with this, see [here](https://github.com/marchoeppner/nf-configs/blob/main/doc/installation.md).

We recommend you also contribute a config file for your setup to our [central config repository](https://github.com/marchoeppner/nf-configs/blob/main/doc/config.md). This will save you time down the road by setting certain options automatically based on your compute environment. 

## 2. Pipeline references

FooDMe 2 requires locally stored, formatted databases. The pipeline has a [built-in](installation.md#installing-the-references) option to install these. 

## 3. Run the test

Once everything is set up, you can run a short test to see if everything works as expected. 

```bash
nextflow run bio-raum/FooDMe2 -profile conda,test -r main
```

where the conda profile can be replaced by whatever your [software provider](usage.md#running-the-pipeline) of choice is.
