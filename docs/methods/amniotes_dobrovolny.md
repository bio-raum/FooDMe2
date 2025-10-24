# 16S Metabarcoding for mammals and birds (meat products)

## Description

:light_bulb: **Sequencing parameters:**

* Platform: Illumina, IonTorrent and Nanopore
* Read-length: paired-end 150bp or longer, single-end with 150bp or longer
* Targets: mammals, birds

:mortar_board: **Relevant publications:**

* [Development of a DNA metabarcoding method for the identification of fifteen mammalian and six poultry species in food ](https://pubmed.ncbi.nlm.nih.gov/30309555/)
* [Identification of Mammalian and Poultry Species in Food and Pet Food Samples Using 16S rDNA Metabarcoding](https://pubmed.ncbi.nlm.nih.gov/34829156/)
* [Benchmarking and Validation of a Bioinformatics Workflow for Meat Species Identification Using 16S rDNA Metabarcoding ](https://pubmed.ncbi.nlm.nih.gov/36900485/)
* [Interlaboratory Validation of a DNA Metabarcoding Assay for Mammalian and Poultry Species to Detect Food Adulteration](https://pubmed.ncbi.nlm.nih.gov/35454695/)
* [Detection of adulterated meat products by a next-generation sequencing-based metabarcoding analysis within the framework of the operation OPSON X: a cooperative project of the German National Reference Centre for Authentic Food (NRZ-Authent) and the competent German food control authorities](https://www.openagrar.de/receive/openagrar_mods_00087058)

:scroll: **Official Methods:**

* Illumina, Iontorrent: Amtliche Sammlung von Untersuchungsverfahren: [BVL L 00.00-184](https://www.dinmedia.de/de/technische-regel/bvl-l-00-00-184/367584412) (German)

:gear: **Run with:**

`--primer_set 16S_ILM_ASU184_meat` (Illumina)
`--primer_set 16S_IT_ASU184_meat` (Iontorrent)
`--primer_set 16S_ONT_ASU184_meat` (Nanopore)

For example:

```bash
nextflow run bio-raum/FooDMe2 \
  -r main \
  -profile myprofile \ # (1)!
  --input samples.tsv \
  --primer_set 16S_ILM_ASU184_meat
```

1. See the [installation guide](../user_doc/installation.md) for more details on this parameter

## Configuration

Check the relevant configuration file under `conf/primers/` for an list of parameters (e.g. `16S_ILM_ASU184_meat.conf`).

## Validation

Mammals and birds 16S Illumina metabarcoding, method from [Dobrovolny paper](https://pubmed.ncbi.nlm.nih.gov/30309555/) with the dataset from the [FooDMe1 paper](https://pubmed.ncbi.nlm.nih.gov/36900485/).

For this method, a benchmarking (or validation) profile is provided in the FooDMe2 distribution:

``` bash
nextflow run bio-raum/FooDMe2 \
  -profile singularity,dobrovolny_benchmark \
  -r main
```

Running this will fetch the dataset from ENA, run the workflow with the `16S_ILM_ASU188_meat` preconfiguration and then compare the resutls to the expected composition defined under `assets/validation/dobrovolny_benchmark_groundtruth.csv`. A noise filter fo 0.1% of the total read number is applied to each sample and the composition is matched to up to the genus level.

In the resulting Excel file we can quickly count the number of TP, FP and FN and calculate precision and recall for the analysis:

| - | Expect Positive | Expect negative |
| --- | --- | --- |
| Predicted Positive | 524 | 31 |
| Predicted Negative | 19 | - |

Which means a precision of 94.4% and recall of 96.5% out of the box.

However there are 14 FN occurences of fallow deer (*Dama dama*) in the table, which was not amplified in the initial method and therefore cannot be detected. These can be ignored for the validation.

Another problem in this dataset is that Kangaroo (*Macropodidae*), a family node, was expected with no information on the species, this results in a negative results in the benchmarking tools. We can correct this be converting all FP results for Kangaroo into FP (if a kangaroo speice was detected of course), these are all 17 occurences where either of *Macropus giganteus*, *Osphranter robusuts*, or *Osphranter rufus* were detected.

The corrected confusion table now looks like this:

| - | Expect Positive | Expect negative |
| --- | --- | --- |
| Predicted Positive | 541 | 14 |
| Predicted Negative | 5 | - |

Now resulting in a **precision of 97.4%** and a **recall of 99.1%**.
