process DADA2_ERROR {
    tag "$meta.sample_id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.30.0--r43hf17093f_0' :
        'quay.io/biocontainers/bioconductor-dada2:1.30.0--r43hf17093f_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.err.rds'), emit: errormodel
    tuple val(meta), path('*.err.pdf'), emit: pdf
    tuple val(meta), path('*.err.svg'), emit: svg
    tuple val(meta), path('*.err.log'), emit: log
    tuple val(meta), path('*.err.convergence.txt'), emit: convergence
    path 'versions.yml'               , emit: versions
    path '*.args.txt'                 , emit: args

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: [ 'nbases = 1e8, nreads = NULL, randomize = TRUE, MAX_CONSIST = 10, OMEGA_C = 0, qualityType = "Auto"',
            params.pacbio ? 'errorEstimationFunction = PacBioErrfun' : 'errorEstimationFunction = loessErrfun'
        ].join(',').replaceAll('(,)*$', '')
    def seed = task.ext.seed ?: '100'
    if (meta.single_end) {
        """
        #!/usr/bin/env Rscript

        suppressPackageStartupMessages(library(dada2))
        set.seed($seed) # Initialize random number generator for reproducibility

        fnFs <- sort(list.files(".", pattern = ".fastq.gz", full.names = TRUE))

        sink(file = "${meta.sample_id}.err.log")
        errF <- learnErrors(fnFs, $args, multithread = $task.cpus, verbose = TRUE)
        saveRDS(errF, "${meta.sample_id}.err.rds")
        sink(file = NULL)

        pdf("${meta.sample_id}.err.pdf")
        plotErrors(errF, nominalQ = TRUE)
        dev.off()
        svg("${meta.sample_id}.err.svg")
        plotErrors(errF, nominalQ = TRUE)
        dev.off()

        sink(file = "${meta.sample_id}.err.convergence.txt")
        dada2:::checkConvergence(errF)
        sink(file = NULL)

        write.table('learnErrors\t$args', file = "learnErrors.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
        writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
        """
    } else {
        """
        #!/usr/bin/env Rscript
        suppressPackageStartupMessages(library(dada2))
        set.seed($seed) # Initialize random number generator for reproducibility

        fnFs <- sort(list.files(".", pattern = "_1.filt.fastq.gz", full.names = TRUE))
        fnRs <- sort(list.files(".", pattern = "_2.filt.fastq.gz", full.names = TRUE))

        sink(file = "${meta.sample_id}.err.log")
        errF <- learnErrors(fnFs, $args, multithread = $task.cpus, verbose = TRUE)
        saveRDS(errF, "${meta.sample_id}_1.err.rds")
        errR <- learnErrors(fnRs, $args, multithread = $task.cpus, verbose = TRUE)
        saveRDS(errR, "${meta.sample_id}_2.err.rds")
        sink(file = NULL)

        pdf("${meta.sample_id}_1.err.pdf")
        plotErrors(errF, nominalQ = TRUE)
        dev.off()
        svg("${meta.sample_id}_1.err.svg")
        plotErrors(errF, nominalQ = TRUE)
        dev.off()

        pdf("${meta.sample_id}_2.err.pdf")
        plotErrors(errR, nominalQ = TRUE)
        dev.off()
        svg("${meta.sample_id}_2.err.svg")
        plotErrors(errR, nominalQ = TRUE)
        dev.off()

        sink(file = "${meta.sample_id}_1.err.convergence.txt")
        dada2:::checkConvergence(errF)
        sink(file = NULL)

        sink(file = "${meta.sample_id}_2.err.convergence.txt")
        dada2:::checkConvergence(errR)
        sink(file = NULL)

        write.table('learnErrors\t$args', file = "learnErrors.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
        writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
        """
    }
}
