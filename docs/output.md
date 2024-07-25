# Outputs

## Reports

<details markdown=1>
<summary>reports</summary>

- `name_of_pipeline_run`.xlsx: A table with accumulated results - one row per sample per taxon:

```TSV
Sample  Taxon Percentage
SampleA Sus scrofa  75.0
SampleA Bos taurus  25.0  
```

- ` name_of_pipeline_run`_krona.html: A multi-sample Krona report to visualize taxonomic composition of samples. 

</details>

## Quality control

<details markdown=1>
<summary>MultiQC</summary>

- MultiQC/`name_of_pipeline_run`_multiqc_report.html: A graphical and interactive report of various QC steps and results

</details>

## Per-sample outputs

<details markdown=1>
<summary>SampleID</summary>

- `name_of_pipeline_run`.usearch_global.tsv - the Number of reads mapping against each respective OTU, per sample
- `name_of_pipeline_run`.precluster.fasta - the final set of OTUs in FASTA format

</details>

<details markdown=1>
<summary>vsearch</summary>

This folder contains the various intermediate processing outputs and is mostly there for debugging purposes.

</details>

## Pipeline run metrics

<details markdown=1>
<summary>pipeline_info</summary>

This folder contains the pipeline run metrics

- pipeline_dag.svg - the workflow graph (only available if GraphViz is installed)
- pipeline_report.html - the (graphical) summary of all completed tasks and their resource usage
- pipeline_report.txt - a short summary of this analysis run in text format
- pipeline_timeline.html - chronological report of compute tasks and their duration
- pipeline_trace.txt - Detailed trace log of all processes and their various metrics

</details>
