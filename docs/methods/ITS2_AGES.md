# ITS2 Metabarcoding for plants

## Description

:light_bulb: **Sequencing parameters:**

* Platform: Illumina
* Read-length: Illumina 2x150bp
* Targets: plants

:mortar_board: **Relevant publications:**

* Not currently an published. 

:scroll: **Official Methods:**

* Not currently an official method. 

:gear: **Run with:**

`--primer_set ITS2short_ILM_AGES_plants` (Illumina)


For example:

```bash
nextflow run bio-raum/FooDMe2 \
  -r main \
  -profile myprofile \ # (1)!
  --input samples.tsv \
  --primer_set ITS2short_ILM_AGES_plants
```

1. See the [installation guide](../user_doc/installation.md) for more details on this parameter

## Primer sequence(s)

The following primer sequences are used:

!!! Warning

    This primer system is currently embargoed pending publication, and therefore not included in the present distribution.

## Configuration

Check the relevant configuration file under `conf/primers/` for an list of parameters (e.g. `ITS2short_ILM_AGES_plants.conf`).
