# 16S Metabarcoding for insect species (Hillinger et al.)

## Description

:light_bulb: **Sequencing parameters:**

* Platform: Illumina, IonTorrent and Nanopore
* Read-length: paired-end 150bp or longer, single-end with 200bp or longer
* Targets: insects

:mortar_board: **Relevant publications:**

* [Development of a DNA Metabarcoding Method for the Identification of Insects in Food ](https://pubmed.ncbi.nlm.nih.gov/36900603/)

:scroll: **Official Methods:**

* Not currently an official method. 

:gear: **Run with:**

`--primer_set 16S_ILM_hillinger_insects` (Illumina)
`--primer_set 16S_IT_hillinger_insects` (Iontorrent)
`--primer_set 16S_ONT_hillinger_insects` (Nanopore)

For example:

```bash
nextflow run bio-raum/FooDMe2 \
  -r main \
  -profile myprofile \ # (1)!
  --input samples.tsv \
  --primer_set 16S_ILM_hillinger_insects
```

1. See the [installation guide](../user_doc/installation.md) for more details on this parameter

## Configuration

Check the relevant configuration file under `conf/primers/` for an list of parameters (e.g. `16S_ILM_hillinger_insects.conf`).