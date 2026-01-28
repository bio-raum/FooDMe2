# rbcL barcode for plants

## Description

:light_bulb: **Sequencing parameters:**

* Platform: Illumina
* Read-length: paired-end 150bp
* Targets: plants

:mortar_board: **Relevant publications:**

* [A DNA mini-barcode for land plants](https://pubmed.ncbi.nlm.nih.gov/24286499/)
* [Soft fruit traceability in food matrices using real-time PCR](https://pubmed.ncbi.nlm.nih.gov/22253987/)

:scroll: **Official Methods:**

* Not currently an official method. 

:gear: **Run with:**

`--primer_set rbcL_ILM_Little_plants` (Illumina)

For example:

```bash
nextflow run bio-raum/FooDMe2 \
  -r main \
  -profile myprofile \ # (1)!
  --input samples.tsv \
  --primer_set rbcL_ILM_Little_plants
```

1. See the [installation guide](../user_doc/installation.md) for more details on this parameter

## Primer sequence(s)

The following primer sequences are used:

```
>rbcL1
TTGGCAGCATTYCGAGTAACTCC
>rbcLB
AACCYTCTTCAAAAAGGTC
```

## Configuration

Check the relevant configuration file under `conf/primers/` for an list of parameters (e.g. `rbcL_ILM_Little_plants.conf`).
