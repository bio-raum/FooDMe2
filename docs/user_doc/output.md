# Outputs

## Reports

=== "Excel"

    - `name_of_pipeline_run.xlsx`: A table with accumulated results - one row per sample per taxon:

    | Sample | Taxon | Percentage |
    | --- | --- | --- |
    | SampleA | Sus scrofa | 75.0 |
    | SampleA | Bos taurus | 25.0 | 

=== "Krona"

    - `name_of_pipeline_run_krona.html`: A multi-sample Krona report to visualize taxonomic composition of samples. 

=== "MultiQC"

    - `name_of_pipeline_run_multiqc_report.html`: A graphical and interactive report of various QC steps and results

## Per-sample outputs

=== "Clustering"

    When using Vsearch for OTU clustering
    - `vsearch/sample_id.usearch_global.tsv`: the number of reads mapping against each respective OTU, per sample
    - `vsearch/sample_id.precluster.fasta`: the final set of OTUs in FASTA format

    When using DADA2 for OTU/ASV clustering
    - `DADA2/sample_id_ASVs.fasta`: the clustered sequences (OTU/ASV)

    That same folder also contains a number of additional metrics and outputs, including graphical summaries of the error profiles that can be used to debug sample-specific issues. 

=== "BLAST"

    - `blast/sample_id.filtered.json`: JSON listing of all BLAST hits
    - `blast/sample_id.consensus.json`: JSON listing of consensus taxa assigned to each sequence cluster

=== "Reports"

This folder contains some of the raw sample-level outputs.

- `report/sample_id.composition.tsv`: the taxonomic composition of this sample in TSV format. 
- `report/sample_id.composition.json`: the taxonomic composition of this sample in JSON format. 
- `report/sample_id.blast_stats.tsv`: Details of the blast matches against each respective OTU. 
- `report/sample_id.report.json`: A JSON summary of the results and QC for this sample


## Pipeline run metrics

This folder contains the pipeline run metrics

- `pipeline_dag.svg`: the workflow graph (only available if GraphViz is installed)
- `pipeline_report.html`: the (graphical) summary of all completed tasks and their resource usage
- `pipeline_report.txt`: a short summary of this analysis run in text format
- `pipeline_timeline.htm`: chronological report of compute tasks and their duration
- `pipeline_trace.txt`: Detailed trace log of all processes and their various metrics
