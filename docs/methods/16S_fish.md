# 16S Metabarcoding for fish (Dobrovolny et al.)

## Description

:light_bulb: **Sequencing parameters:**

* Platform: Illumina, IonTorrent and Nanopore
* Read-length: paired-end 150bp or longer, single-end with 150bp or longer
* Targets: fish

:mortar_board: **Relevant publications:**

* [Development of a DNA metabarcoding method for the identification of fifteen mammalian and six poultry species in food ](https://pubmed.ncbi.nlm.nih.gov/30309555/)
* [Identification of Mammalian and Poultry Species in Food and Pet Food Samples Using 16S rDNA Metabarcoding](https://pubmed.ncbi.nlm.nih.gov/34829156/)

:scroll: **Official Methods:**

!!! Warning

  This system is used in an official method for mammals and birds, but **not** for fish species


* Illumina, Iontorrent: Amtliche Sammlung von Untersuchungsverfahren: [BVL L 00.00-184](https://www.dinmedia.de/de/technische-regel/bvl-l-00-00-184/367584412) (German)

:gear: **Run with:**

`--primer_set 16S_ILM_ASU184_fish` (Illumina)

`--primer_set 16S_IT_ASU184_fish` (Iontorrent)

`--primer_set 16S_ONT_ASU184_fish` (Nanopore)

For example:

```bash
nextflow run bio-raum/FooDMe2 \
  -r main \
  -profile myprofile \ # (1)!
  --input samples.tsv \
  --primer_set 16S_ILM_ASU184_fish
```

1. See the [installation guide](../user_doc/installation.md) for more details on this parameter

## Primer sequence(s)

The following primer sequences are used:

```
>MA_FWD
GACGAGAAGACCCTATGGAGC
>MA_REV
TCCGAGGTCACCCCAACC
>POL_FWD
GACGAGAAGACCCTGTGGAAC
>POL_REV
TCCGAGATCACCCCAATC
>MA_ALT_REV
TCCAAGGTCGCCCCAACC
```

## Configuration

Check the relevant configuration file under `conf/primers/` for an list of parameters (e.g. `16S_ILM_ASU184_fish.conf`).

