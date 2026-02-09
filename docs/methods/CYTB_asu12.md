# CYTB Metabarcoding for fish species (ASU12)

## Description

:light_bulb: **Sequencing parameters:**

* Platform: Illumina, IonTorrent and Nanopore
* Read-length: Illumina 2x250bp, single-end with 450bp or longer
* Targets: fish

:mortar_board: **Relevant publications:**

* [Untersuchung von Lebensmitteln - DNA-Barcoding zur Fischartidentifizierung in Fisch und Fischerzeugnissen anhand definierter mitochondrialer Cytochrom-b- und Cytochrom-c-Oxidase-I-Genabschnitte](https://www.dinmedia.de/de/technische-regel/bvl-l-10-00-12/391751419)

:scroll: **Official Methods:**

* [Untersuchung von Lebensmitteln - DNA-Barcoding zur Fischartidentifizierung in Fisch und Fischerzeugnissen anhand definierter mitochondrialer Cytochrom-b- und Cytochrom-c-Oxidase-I-Genabschnitte](https://www.dinmedia.de/de/technische-regel/bvl-l-10-00-12/391751419)

:gear: **Run with:**

`--primer_set cytb_ILM_ASU12_fish` (Illumina)

`--primer_set cytb_IT_ASU12_fish` (Iontorrent)

`--primer_set cytb_ONT_ASU12_fish` (Nanopore)

For example:

```bash
nextflow run bio-raum/FooDMe2 \
  -r main \
  -profile myprofile \ # (1)!
  --input samples.tsv \
  --primer_set cytb_ILM_ASU12_fish
```

1. See the [installation guide](../user_doc/installation.md) for more details on this parameter

## Primer sequence(s)

The following primer sequences are used:

```
>L14735
AAAAACCACCGTTGTTATTCAACTA
>H15149ad
GCNCCTCARAATGAYATTTGTCCTCA
```

## Configuration

Check the relevant configuration file under `conf/primers/` for an list of parameters (e.g. `cytb_ILM_ASU12_fish.conf`).