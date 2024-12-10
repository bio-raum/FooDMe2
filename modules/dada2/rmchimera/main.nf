process DADA2_RMCHIMERA {
    tag "$meta.sample_id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.30.0--r43hf17093f_0' :
        'quay.io/biocontainers/bioconductor-dada2:1.30.0--r43hf17093f_0' }"

    input:
    tuple val(meta), path(seqtab)

    output:
    tuple val(meta), path('*.ASVtable.rds') , emit: rds
    path 'versions.yml'                     , emit: versions
    path '*.args.txt'                       , emit: args

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: 'method="consensus", minSampleFraction = 0.9, ignoreNNegatives = 1, minFoldParentOverAbundance = 2, minParentAbundance = 8, allowOneOff = FALSE, minOneOffParentDistance = 4, maxShift = 16'
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))

    seqtab = readRDS("${seqtab}")

    if (is.null(seqtab) || length(seqtab) == 0) {
        saveRDS(c(),"${meta.sample_id}.ASVtable.rds")
    } else {
        #remove chimera
        seqtab.nochim <- removeBimeraDenovo(seqtab, $args, multithread=$task.cpus, verbose=TRUE)
        saveRDS(seqtab.nochim,"${meta.sample_id}.ASVtable.rds")
    }
    write.table('removeBimeraDenovo\t$args', file = "removeBimeraDenovo.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
    writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
    """
}
