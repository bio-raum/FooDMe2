# Workflow validation

## Benchmarking tool

Bioinformatics workflows should always be properly validated before routine use.
To facilitate this process, it is possible to provide FooDMe2 a list of expected smaple composition 
which will beautomatically compared to the predicted composition (see [usage](user_doc/usage.md)).

FooDMe2 comes with somepre-configured validations for specific analysis. Currently following validations are available:

### Mammals and birds

Mammals and birds 16S Illumina metabarcoding, method from [Dobrovolny paper](https://pubmed.ncbi.nlm.nih.gov/30309555/) with the dataset from the [FooDMe1 paper](https://pubmed.ncbi.nlm.nih.gov/36900485/).

``` bash
nextflow run bio-raum/FooDMe2 \
-profile singularity,dobrovolny_benchmark
```

Running this will fetch the dataset from ENA, run the workflow with the `amniotes_dobrovolny` preconfiguration and then compare the resutls to the expected composition defined under `assets/validation/dobrovolny_benchmark_groundtruth.csv`. A noise filter fo 0.1% of the total read number is applied to each sample and the composition is matched to up to the genus level.

In the resulting Excel file we can quickly count the number of TP, FP and FN and calculate precision and recall for the analysis:

| - | Expect Positive | Expect negative |
| Predicted Positive | 524 | 31 |
| Predicted Negative | 19 | - |

Which means a precision of 94.4% and recall of 96.5% out of the box. 

However there are 14 FN occurences of fallow deer (*Dama dama*) in the table, which was not amplified in the initial method and therefore cannot be detected. These can be ignored for the validation.

Another problem in this dataset is that Kangaroo (*Macropodidae*), a family node, was expected with no information on the species, this results in a negative results in the benchmarking tools. We can correct this be converting all FP results for Kangaroo into FP (if a kangaroo speice was detected of course), these are all 17 occurences where either of *Macropus giganteus*, *Osphranter robusuts*, or *Osphranter rufus* were detected.

The corrected confusion table now looks like this:

| - | Expect Positive | Expect negative |
| Predicted Positive | 541 | 14 |
| Predicted Negative | 5 | - |

Now resulting in a **precision of 97.4%** and a **recall of 99.1%**.
