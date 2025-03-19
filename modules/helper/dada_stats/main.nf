process HELPER_DADA_STATS {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
<<<<<<< HEAD
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.30.0--r43hf17093f_0' :
        'quay.io/biocontainers/bioconductor-dada2:1.30.0--r43hf17093f_0' }"
=======
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.28.0--r43hf17093f_0' :
        'quay.io/biocontainers/bioconductor-dada2:1.28.0--r43hf17093f_0' }"
>>>>>>> 4040db9918acef05197229ef250c4efb8b45c286

    input:
    tuple val(meta), path(mergers), path(filtered), path(seqtab)  // mergers rds

    output:
    tuple val(meta), path('*.dada_stats.json')  , emit: json
    path 'versions.yml'                         , emit: versions

    script:
    def prefix = task.ext.prefix ?: mergers.getSimpleName()
    def sample_id = meta.sample_id

    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))

    mergers <- readRDS("${mergers}")
    total_pairs <- sum(mergers["abundance"])
    merged <- sum(mergers[mergers[, "accept"]==TRUE, ]["abundance"])

    filttab <- readRDS("${filtered}")
    filtered <- sum(filttab)

    seqtab <- readRDS("${seqtab}")
    nonchimeric <- sum(seqtab)

    json <- sprintf(
        '{"${sample_id}": {"passing": %d, "no_merged": %d, "filtered": %d, "chimeras": %d}}',
        nonchimeric,
        total_pairs - merged,
        merged - filtered,
        filtered - nonchimeric)
    write(json, file="${prefix}.dada_stats.json")
    writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
    """
}
