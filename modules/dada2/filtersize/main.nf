process DADA2_FILTERSIZE {
    tag "$meta.sample_id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.30.0--r43hf17093f_0' :
        'quay.io/biocontainers/bioconductor-dada2:1.30.0--r43hf17093f_0' }"

    input:
    tuple val(meta), path(seqtab)

    output:
    tuple val(meta), path('*.ASVtable.filt.rds') , emit: filtered
    path 'versions.yml'                          , emit: versions
    path '*.args.txt'                            , emit: args

    when:
    task.ext.when == null || task.ext.when

    script:
    def minLen = params.amplicon_min_length
    def maxLen = params.amplicon_max_length
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))

    seqtab = readRDS("${seqtab}")

    # filter
    seqtab.filt <- seqtab[,nchar(colnames(seqtab)) %in% seq($minLen,$maxLen)]
    saveRDS(seqtab.filt,"${meta.sample_id}.ASVtable.filt.rds")

    write.table('removeBimeraDenovo\t$args', file = "removeBimeraDenovo.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
    writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
    """
}
