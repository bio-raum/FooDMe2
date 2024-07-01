process HELPER_DADA_STATS {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.28.0--r43hf17093f_0' :
        'biocontainers/bioconductor-dada2:1.28.0--r43hf17093f_0' }"

    input:
    tuple val(meta), path(mergers)  // mergers rds
    tuple val(meta), path(seqtab)   // seqtab rds
    
    output:
    tuple val(meta), path('*.dada_stats.json')  , emit: json
    path 'versions.yml'                         , emit: versions

    script:

    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))

    mergers <- readRDS("${mergers}")
    total_pairs <- sum(mergers["abundance"])
    merged <- sum(mergers[mergers[, "accept"]==TRUE, ]["abundance"])

    seqtab <- readRDS("${seqtab}")
    nonchimeric <- sum(seqtab)
    asvs <- ncol(seqtab)

    json <- sprintf(
        "{'total_pairs': %d, 'merged': %d, 'non_chimeric': %d, 'asvs': %d}",
        total_pairs,
        merged,
        nonchimeric,
        asvs)
    cat(json, file=${json}, sep="\n")
    """
}