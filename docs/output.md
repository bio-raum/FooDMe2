# Outputs 

## Reports

<details markdown=1>
<summary>reports</summary>

- `name_of_pipeline_run`.taxonomy_by_sample.tsv: A table with accumulated results - one row per sample using the following format:

```TSV
sample  reads   hits
SampleA 12678   Sus scrofa:75.5,Bos taurus:24.5
```

where hits are a sorted list of identified taxa and their respective percentages of the total read count. If a sample has multiple separate OTU hits for the same taxon, this taxon will be summed up across all matching OTUs to remove noise from the result. 

- `name_of_pipeline_run`.taxonomy_by_sample.json: A JSON formatted data structure for downstream computational processing. The following structure is used:

```JSON
[
    { 
      "sample": "SampleA",
      "hits": [ 
        { "taxon": "Bos taurus", "reads": 1234 },
        { "taxon": "Sus scrofa", "reads": 6543 }
      ],
      "reads_total": 7777
    },
    {
      "sample": "SampleB",
      "hits": [ 
        { "taxon": "Ovis aries", "reads": 246 },
        { "taxon": "Rangifer tarandus", "reads": 753 }
      ],
      "reads_total": 999
    }
]
```

The data in this file is largely unfiltered and it might be useful to compute percentages and remove any taxa that fall below a threshold and/or collapse hits from the same taxon into one result, based on your specific use case. 

</details>

## Quality control

<details markdown=1>
<summary>MultiQC</summary>

- MultiQC/`name_of_pipeline_run`_multiqc_report.html: A graphical and interactive report of various QC steps and results

</details>

## Raw outputs

<details markdown=1>
<summary>OTUs</summary>

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
