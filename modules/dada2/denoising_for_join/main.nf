process DADA2_DENOISING_FOR_JOIN {
    tag "$meta.sample_id"
    label 'parallel_short'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.30.0--r43hf17093f_0' :
        'quay.io/biocontainers/bioconductor-dada2:1.30.0--r43hf17093f_0' }"

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
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''

    if (meta.single_end) {
        """
        #!/usr/bin/env Rscript
        suppressPackageStartupMessages(library(dada2))

        # Note: Kept single workflow here in case, but normally won't be used in the non_overlapping configuration

        sink(file = "${meta.sample_id}.dada.log")

        errF = readRDS("${errormodel}")

        if (is.null(errF)) {
            saveRDS(c(), "${meta.sample_id}.dada.rds")
            saveRDS(c(), "${meta.sample_id}.seqtab.rds")
            saveRDS("dummy", "dummy_${meta.sample_id}.mergers.rds")
        } else {
            filtFs <- sort(list.files("./filtered/", pattern = ".fastq*", full.names = TRUE))

            #denoising
            dadaFs <- dada(filtFs, err = errF, $args, multithread = $task.cpus)
            saveRDS(dadaFs, "${meta.sample_id}.dada.rds")
            sink(file = NULL)

            #make table
            seqtab <- makeSequenceTable(dadaFs)
            saveRDS(seqtab, "${meta.sample_id}.seqtab.rds")

            #dummy file to fulfill output rules
            saveRDS("dummy", "dummy_${meta.sample_id}.mergers.rds")
        }

        write.table('dada\t$args', file = "dada.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
        writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
        """
    } else {
        """
        #!/usr/bin/env Rscript
        suppressPackageStartupMessages(library(dada2))

        sink(file = "${meta.sample_id}.dada.log")

        errF = readRDS("${errormodel[0]}")
        errR = readRDS("${errormodel[1]}")

        if (is.null(errF) || is.null(errR)) {
            saveRDS(c(), "${meta.sample_id}_2.dada.rds")
            saveRDS(c(), "${meta.sample_id}_1.dada.rds")
            saveRDS(c(), "${meta.sample_id}.mergers.rds")
            saveRDS(c(), "${meta.sample_id}.seqtab.rds")
        } else {
            filtFs <- sort(list.files("./filtered/", pattern = "_1.filt.fastq.gz", full.names = TRUE))
            filtRs <- sort(list.files("./filtered/", pattern = "_2.filt.fastq.gz", full.names = TRUE))

            #denoising
            dadaFs <- dada(filtFs, err = errF, $args, multithread = $task.cpus)
            saveRDS(dadaFs, "${meta.sample_id}_1.dada.rds")

            dadaRs <- dada(filtRs, err = errR, $args, multithread = $task.cpus)
            saveRDS(dadaRs, "${meta.sample_id}_2.dada.rds")

            sink(file = NULL)

            #make table
            # First merge what can be merged
            overlapmergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, $args2, verbose=TRUE, returnRejects=TRUE)
            saveRDS(overlapmergers, "${meta.sample_id}.overlapmergers.rds")
            # Then concatenate 
            concatmergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, $args2, verbose=TRUE, justConcatenate=TRUE)
            saveRDS(concatmergers, "${meta.sample_id}.concatmergers.rds")

            # Now need to get the sequences from concatenation for all rejected merge
            mergers <- rbind(
                overlapmergers[overlapmergers[,'accept']==TRUE,],
                concatmergers[overlapmergers[,'accept']==FALSE,]
            )
            mergers <- mergers[order(as.numeric(row.names(mergers))), ]
            saveRDS(mergers, "${meta.sample_id}.mergers.rds")

            # Finally make seq tabs and join them
            seqtab <- makeSequenceTable(mergers)
            saveRDS(seqtab, "${meta.sample_id}.seqtab.rds")
        }

        write.table('dada\t$args', file = "dada.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
        write.table('mergePairs\t$args2', file = "mergePairs.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
        writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
        """
    }
}
