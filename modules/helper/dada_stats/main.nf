process HELPER_DADA_STATS {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.30.0--r43hf17093f_0' :
        'quay.io/biocontainers/bioconductor-dada2:1.30.0--r43hf17093f_0' }"

    input:
    tuple val(meta), path(reads), path(mergers), path(filtered), path(seqtab)  // Trimmed-filtered fastq, merged RDS, filtered RDS and non-chimeric RDS

    output:
    tuple val(meta), path('*.dada_stats.json')  , emit: json
    path 'versions.yml'                         , emit: versions

    script:
    def prefix = task.ext.prefix ?: meta.sample_id
    def sample_id = meta.sample_id
    def reads_in = meta.single_end ? "$reads" : "${reads[0]}"

    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))
    
    count_fastq_records <- function(file_path) {
        cmd <- paste("zcat", shQuote(file_path), "| wc -l")
        total_lines <- as.numeric(system(cmd, intern = TRUE))
        return(total_lines / 4)
    }

    # Total reads form filtered fastq
    total_reads <- count_fastq_records("${reads_in}")
    
    mergers <- readRDS("${mergers}")
    # if mergers is from single end data it will be either "dummy" (illumina wf) or "" (others)
    # So just checking if it is a string is enough
    if ( ! is.character(mergers) ) {
        merged <- sum(mergers[mergers[, "accept"]==TRUE, ]["abundance"])
    } else {
        merged <- total_reads
    }

    filttab <- readRDS("${filtered}")
    filtered <- sum(filttab)

    seqtab <- readRDS("${seqtab}")
    nonchimeric <- sum(seqtab)

    json <- sprintf(
        '{"${sample_id}": {"passing": %d, "no_merged": %d, "filtered": %d, "chimeras": %d}}',
        nonchimeric,
        total_reads - merged,
        merged - filtered,
        filtered - nonchimeric)
    write(json, file="${prefix}.dada_stats.json")
    writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
    """
}
