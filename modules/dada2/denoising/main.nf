process DADA2_DENOISING {
    tag "$meta.sample_id"
    label 'process_medium'
    label 'process_long'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.28.0--r43hf17093f_0' :
        'biocontainers/bioconductor-dada2:1.28.0--r43hf17093f_0' }"

    input:
    tuple val(meta), path('filtered/*'), path(errormodel)

    output:
    tuple val(meta), path('*.dada.rds')   , emit: denoised
    tuple val(meta), path('*.seqtab.rds') , emit: seqtab
    tuple val(meta), path('*.mergers.rds'), emit: mergers
    tuple val(meta), path('*.log')        , emit: log
    path 'versions.yml'                   , emit: versions
    path '*.args.txt'                     , emit: args

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: [
            'selfConsist = FALSE, priors = character(0), DETECT_SINGLETONS = FALSE, GAPLESS = TRUE, GAP_PENALTY = -8, GREEDY = TRUE, KDIST_CUTOFF = 0.42, MATCH = 5, MAX_CLUST = 0, MAX_CONSIST = 10, MIN_ABUNDANCE = 1, MIN_FOLD = 1, MIN_HAMMING = 1, MISMATCH = -4, OMEGA_A = 1e-40, OMEGA_C = 1e-40, OMEGA_P = 1e-4, PSEUDO_ABUNDANCE = Inf, PSEUDO_PREVALENCE = 2, SSE = 2, USE_KMERS = TRUE, USE_QUALS = TRUE, VECTORIZED_ALIGNMENT = TRUE',
            params.iontorrent ? 'BAND_SIZE = 32, HOMOPOLYMER_GAP_PENALTY = -1' : 'BAND_SIZE = 16, HOMOPOLYMER_GAP_PENALTY = NULL'
        ].join(',').replaceAll('(,)*$', '')
    def args2 = task.ext.args2 ?: ''
    if (meta.single_end) {
        """
        #!/usr/bin/env Rscript
        suppressPackageStartupMessages(library(dada2))

        errF = readRDS("${errormodel}")

        filtFs <- sort(list.files("./filtered/", pattern = ".fastq.gz", full.names = TRUE))

        #denoising
        sink(file = "${meta.sample_id}.dada.log")
        dadaFs <- dada(filtFs, err = errF, $args, multithread = $task.cpus)
        saveRDS(dadaFs, "${meta.sample_id}.dada.rds")
        sink(file = NULL)

        #make table
        seqtab <- makeSequenceTable(dadaFs)
        saveRDS(seqtab, "${meta.sample_id}.seqtab.rds")

        #dummy file to fulfill output rules
        saveRDS("dummy", "dummy_${meta.sample_id}.mergers.rds")

        write.table('dada\t$args', file = "dada.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
        writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
        """
    } else {
        """
        #!/usr/bin/env Rscript
        suppressPackageStartupMessages(library(dada2))

        errF = readRDS("${errormodel[0]}")
        errR = readRDS("${errormodel[1]}")

        filtFs <- sort(list.files("./filtered/", pattern = "_1.trim.fastq.gz", full.names = TRUE))
        filtRs <- sort(list.files("./filtered/", pattern = "_2.trim.fastq.gz", full.names = TRUE))

        #denoising
        sink(file = "${meta.sample_id}.dada.log")
        dadaFs <- dada(filtFs, err = errF, $args, multithread = $task.cpus)
        saveRDS(dadaFs, "${meta.sample_id}_1.dada.rds")
        dadaRs <- dada(filtRs, err = errR, $args, multithread = $task.cpus)
        saveRDS(dadaRs, "${meta.sample_id}_2.dada.rds")
        sink(file = NULL)

        #make table
        mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, $args2, verbose=TRUE)
        saveRDS(mergers, "${meta.sample_id}.mergers.rds")
        seqtab <- makeSequenceTable(mergers)
        saveRDS(seqtab, "${meta.sample_id}.seqtab.rds")

        write.table('dada\t$args', file = "dada.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
        write.table('mergePairs\t$args2', file = "mergePairs.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
        writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
        """
    }
}
