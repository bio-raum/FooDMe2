process DADA2_ERROR {
    tag "$meta.sample_id"
    label 'medium_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.30.0--r43hf17093f_0' :
        'quay.io/biocontainers/bioconductor-dada2:1.30.0--r43hf17093f_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.err.rds')                  , emit: errormodel
    tuple val(meta), path('*.err.pdf')                  , emit: pdf, optional: true
    tuple val(meta), path('*.err.svg')                  , emit: svg, optional: true
    tuple val(meta), path('*.err.log')                  , emit: log, optional: true
    tuple val(meta), path('*.error_rates.tsv')          , emit: err_rates, optional: true
    tuple val(meta), path('*.observed_transitions.tsv') , emit: trans, optional: true
    path 'versions.yml'                                 , emit: versions
    path '*.args.txt'                                   , emit: args

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ""
    def seed = task.ext.seed ?: '100'
    
    if (meta.single_end) {
        """
        #!/usr/bin/env Rscript

        suppressPackageStartupMessages(library(dada2))
        set.seed($seed) # Initialize random number generator for reproducibility

        generate_empty <- function(e) {
            # On error or empty input generate empty output files
            print(e)
            saveRDS(c(), "${meta.sample_id}.err.rds")
        }

        output_func <- function(error, name) {
            pErr <- plotErrors(error, nominalQ = TRUE)
            pdf(paste(name, ".err.pdf"))
            print(pErr)
            dev.off()
            svg(paste(name, ".err.svg"))
            print(pErr)
            dev.off()
            write.table(error[["err_out"]], sep="\t", file=paste(name, ".error_rates.tsv"), col.names=NA, quote=FALSE)
            write.table(error[["trans"]], sep="\t", file=paste(name, ".observed_transitions.tsv"), col.names = NA, quote=FALSE)
        }

        run_module <- function(fnFs) {
            # Run the module as intended
            errF <- learnErrors(fnFs, $args, multithread = $task.cpus, verbose = TRUE)

            saveRDS(errF, "${meta.sample_id}.err.rds")

            output_func(errF, "${meta.sample_id}")
        }
        
        sink(file = "${meta.sample_id}.err.log")

        fnFs <- sort(list.files(".", pattern = ".fastq.gz", full.names = TRUE))

        # Check if file is empty
        n_lines <- as.integer(system(sprintf('gunzip -c %s | wc -l', fnFs), intern= TRUE))
        if (n_lines < 4 ) {
            generate_empty("WARNING: Detected empty input")
        } else {
            tryCatch(
                expr = run_module(fnFs),
                error = function(e) generate_empty(e)
            )
        }
        sink(file = NULL)
        write.table('learnErrors\t$args', file = "learnErrors.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
        writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
        """
    } else {
        """
        #!/usr/bin/env Rscript
        suppressPackageStartupMessages(library(dada2))
        set.seed($seed) # Initialize random number generator for reproducibility

        generate_empty <- function(e) {
            # On error or empty input generate empty output files
            print(e)
            saveRDS(c(), "${meta.sample_id}_1.err.rds")
            saveRDS(c(), "${meta.sample_id}_2.err.rds")
        }

        output_func <- function(error, name) {
            pErr <- plotErrors(error, nominalQ = TRUE)
            pdf(paste(name, ".err.pdf"))
            print(pErr)
            dev.off()
            svg(paste(name, ".err.svg"))
            print(pErr)
            dev.off()
            write.table(error[["err_out"]], sep="\t", file=paste(name, ".error_rates.tsv"), col.names = NA, quote=FALSE)
            write.table(error[["trans"]], sep="\t", file=paste(name, ".observed_transitions.tsv"), col.names = NA, quote=FALSE)
        }
        
        run_module <- function(fnFs, fnRs) {
            # Run the module as intended
            print("Forward reads ...")
            errF <- learnErrors(fnFs, $args, multithread = $task.cpus, verbose = TRUE)
            saveRDS(errF, "${meta.sample_id}_1.err.rds")
            print("Reverse reads ...")
            errR <- learnErrors(fnRs, $args, multithread = $task.cpus, verbose = TRUE)
            saveRDS(errR, "${meta.sample_id}_2.err.rds")

            output_func(errF, "${meta.sample_id}_1")
            output_func(errR, "${meta.sample_id}_2")
        }

        sink(file = "${meta.sample_id}.err.log")

        fnFs <- sort(list.files(".", pattern = "_1.filt.fastq.gz", full.names = TRUE))
        fnRs <- sort(list.files(".", pattern = "_2.filt.fastq.gz", full.names = TRUE))
        
        # Check if file is empty
        n_lines <- as.integer(system(sprintf('gunzip -c %s | wc -l', fnFs), intern= TRUE))
        # fastq has at least 4 lines, save empty arrray if empty input
        if (n_lines < 4 ) {
            generate_empty("WARNING: Detected empty input")
        } else {
            tryCatch(
                expr = run_module(fnFs, fnRs),
                error = function(e) generate_empty(e)
            )
        }
        sink(file = NULL)
        write.table('learnErrors\t$args', file = "learnErrors.args.txt", row.names = FALSE, col.names = FALSE, quote = FALSE, na = '')
        writeLines(c("\\"${task.process}\\":", paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = ".")),paste0("    dada2: ", packageVersion("dada2")) ), "versions.yml")
        """
    }
}
