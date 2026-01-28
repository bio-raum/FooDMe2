# COI Metabarcoding for fish species (Guenther et al.)

## Description

:light_bulb: **Sequencing parameters:**

* Platform: Illumina, IonTorrent and Nanopore
* Read-length: paired-end 250bp or longer, single-end with 450bp or longer
* Targets: fish

:mortar_board: **Relevant publications:**

* [Full-length and mini-length DNA barcoding for the identification of seafood commercially traded in Germany](https://doi.org/10.1016/j.foodcont.2016.10.016)

:scroll: **Official Methods:**

* Not currently an official method. 

:gear: **Run with:**

`--primer_set COI_ILM_guenther_fish` (Illumina)

`--primer_set COI_IT_guenther_fish` (Iontorrent)

`--primer_set COI_ONT_guenther_fish` (Nanopore)

For example:

```bash
nextflow run bio-raum/FooDMe2 \
  -r main \
  -profile myprofile \ # (1)!
  --input samples.tsv \
  --primer_set COI_ILM_guenther_fish
```

1. See the [installation guide](../user_doc/installation.md) for more details on this parameter

## Primer sequence(s)

The following primer sequences are used:

```
>mlCOIintF
GGWACWGGWTGAACWGTWTAYCCYCC
>jgHCO2198
TANACYTCNGGRTGNCCRAARAAYCA
```

## Configuration

Check the relevant configuration file under `conf/primers/` for an list of parameters (e.g. `COI_ILM_guenther_fish.conf`).