# trnL barcode for plants

## Description

:light_bulb: **Sequencing parameters:**

* Platform: Illumina
* Read-length: paired-end 150bp
* Targets: plants

:mortar_board: **Relevant publications:**

* [Taberlet P., Gielly L., Pautou G., Bouvet J. (1991) Universal primers for amplification of three non-coding regions of chloroplast DNA.](https://pubmed.ncbi.nlm.nih.gov/1932684/)
* [Eine universell einsetzbare PCR-Methode zur Pflanzenartbestimmung von Lebensmitteln: Erfahrungen und Möglichkeiten.](https://www.researchgate.net/publication/287284767_A_universally_applicable_PCR_method_for_the_identification_of_plant_species_of_food_Experiences_and_possibilities)

:scroll: **Official Methods:**

* Not currently an official method. 

:gear: **Run with:**

`--primer_set trnLlong_ILM_Taberlet_plants` (Illumina)

For example:

```bash
nextflow run bio-raum/FooDMe2 \
  -r main \
  -profile myprofile \ # (1)!
  --input samples.tsv \
  --primer_set trnLlong_ILM_Taberlet_plants
```

1. See the [installation guide](../user_doc/installation.md) for more details on this parameter

## Primer sequence(s)

The following primer sequences are used:

```
>CLP1a
TAGGTGCAGAGACTCAATGG
>CLP2
GGGGATAGAGGGACTTGAAC
```

## Configuration

Check the relevant configuration file under `conf/primers/` for an list of parameters (e.g. `trnLlong_ILM_Taberlet_plants.conf`).
