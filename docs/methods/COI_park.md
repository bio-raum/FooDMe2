# COI Metabarcoding for insect species (Park et al.)

## Description

:light_bulb: **Sequencing parameters:**

* Platform: Illumina, IonTorrent and Nanopore
* Read-length: Illumina 2x250bp, single-end with 450bp or longer
* Targets: insects

:mortar_board: **Relevant publications:**

* [Barcoding Bugs: DNA-Based Identification of the True Bugs (Insecta: Hemiptera: Heteroptera)](https://pubmed.ncbi.nlm.nih.gov/21526211/)
* [Molecular systematics of cowries (Gastropoda: Cypraeidae) and diversification patterns in the tropics ](https://academic.oup.com/biolinnean/article/79/3/401/2639779)

:scroll: **Official Methods:**

* Not currently an official method. 

:gear: **Run with:**

`--primer_set COI_ILM_park_insects` (Illumina)

`--primer_set COI_IT_park_insects` (Iontorrent)

`--primer_set COI_ONT_park_insects` (Nanopore)

For example:

```bash
nextflow run bio-raum/FooDMe2 \
  -r main \
  -profile myprofile \ # (1)!
  --input samples.tsv \
  --primer_set COI_ILM_park_insects
```

1. See the [installation guide](../user_doc/installation.md) for more details on this parameter

## Primer sequence(s)

The following primer sequences are used:

```
>Fwd-Insekten-COI
GCATTYCCACGAATAAATAAYATAAG
>Rev-Insekten-COI
TAAACTTCAGGGTGACCAAARAAYCA
```

## Configuration

Check the relevant configuration file under `conf/primers/` for an list of parameters (e.g. `COI_ILM_park_insects.conf`).