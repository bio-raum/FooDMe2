process DADA2_FILTNTRIM {
    tag "$meta.sample_id"
    label 'short_parallel'

    conda "${moduleDir}/enviornment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.30.0--r43hf17093f_0' :
        'quay.io/biocontainers/bioconductor-dada2:1.30.0--r43hf17093f_0' }"

    input:
    tuple val(meta), path(reads)
    tuple val(fwd),val(rev)     // sequence of forward and reverse primer
    
    output:
    tuple val(meta), path("*.trim.fastq.gz"), emit: filtered_reads
    tuple val(meta), path("*.trim.fastq.gz"), path("*.filter_stats.tsv"), path("*.args.txt"), emit: reads_logs_args
    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args ?: ''
    def in_and_out  = meta.single_end ? "\"${reads}\", \"${meta.sample_id}.trim.fastq.gz\"" : "\"${reads[0]}\", \"${meta.sample_id}_1.trim.fastq.gz\", \"${reads[1]}\", \"${meta.sample_id}_2.trim.fastq.gz\""
    def outfiles    = meta.single_end ? "\"${meta.sample_id}.trim.fastq.gz\"" : "\"${meta.sample_id}_1.trim.fastq.gz\", \"${meta.sample_id}_2.trim.fastq.gz\""
    
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(dada2))

    out <- removePrimers($in_and_out,
        $fwd,
        $rev,
        $args,
        compress = TRUE,
        multithread = $task.cpus,
        verbose = TRUE)
    out <- cbind(out, ID = row.names(out))

    # If no reads passed the filter, write an empty GZ file
    if(out[2] == '0'){
        for(fp in c($outfiles)){
            print(paste("Writing out an empty file:", fp))
            handle <- gzfile(fp, "w")
            write("", handle)
            close(handle)
        }
    }

    write.table( out, file = "${meta.sample_id}.filter_stats.tsv", sep = "\\t", row.names = FALSE, quote = FALSE, na = '')
    write.table(paste('removePrimers','$args',sep=","), file = "removePrimers.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
    writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
    """
}
