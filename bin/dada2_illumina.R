#!/usr/bin/env Rscript

#suppressPackageStartupMessages(library(optparse"))

args <- commandArgs(trailingOnly = TRUE)

base        = args[1]
r1          = args[2]
r2          = args[3]
threads     = strtoi(args[4])
max_EE      = args[5]
minlength   = args[6]
maxlength   = args[7]
max_mismatch    = args[8]
chimera     = args[9]

# logging
log = file(paste(base,".dada2.log", sep=""), open="wt")
sink(log)
sink(log, type = "message")

# Imports
library(ggplot2, quiet=T)
library(dada2, quiet=T)

# Inputs
fnFs <- r1
fnRs <- r2

# Outputs
filtFs          <- paste(base, "_R1_filtered.fasta.gz", sep="")
filtRs          <- paste(base, "_R2_filtered.fasta.gz", sep="")
errplotF        <- paste(base, "_R1_errorRates.pdf", sep="")
errplotR        <- paste(base, "_R2_errorRates.pdf",sep="")
denoising_R1    <- paste(base, "_R1_denoising.txt",sep="")
denoising_R2    <- paste(base, "_R2_denoising.txt", sep="")
merged          <- paste(base, "_merging.txt", sep="")
asv_table       <- paste(base, "_ASVs.fasta", sep="")
report          <- paste(base, "_denoising.tsv", sep="")
chimeras_fasta  <- paste(base, "_chimeras.fasta", sep="")

sample.names    <- base 

getN <- function(x) {
    tryCatch(sum(getUniques(x)),error=function(e){return(0)})
}

# DADA Workflow -------------------------------------------------------------------------------------------------------------

# Filter reads
names(filtFs) <- sample.names
names(filtRs) <- sample.names

out <- suppressWarnings(
    withCallingHandlers(
        expr=filterAndTrim(
            fnFs, filtFs, fnRs, filtRs, 
            maxN=0, maxEE=max_EE, rm.phix=TRUE,
            compress=TRUE, multithread=threads, verbose=TRUE
        ),
        error=function(e) {message(e$message)},
        warning=function(w) { 
            message(w$message)
            writeLines("", filtRs)
            writeLines("", filtFs)
        }
    )
)
            
# Learn Error rate
tryCatch({
    errF <- learnErrors(filtFs, multithread=threads, verbose=TRUE)
    errR <- learnErrors(filtRs, multithread=threads, verbose=TRUE)

    # Sample inference
    dadaFs <- dada(filtFs, err=errF, multithread=threads, verbose=TRUE)
    dadaRs <- dada(filtRs, err=errR, multithread=threads, verbose=TRUE)

    # Merge Reads
    mergers <- mergePairs(
        dadaFs, filtFs, dadaRs, filtRs, 
        maxMismatch=max_mismatch, 
        verbose=TRUE
    )

    # ASV table
    seqtab <- makeSequenceTable(mergers)
    seqtab2 <- seqtab[,nchar(colnames(seqtab)) %in% minlength:maxlength]

    # Remove chimeras
    if (chimera == TRUE) {
        seqtab2.nochim <- removeBimeraDenovo(seqtab2, method="per-sample", multithread=threads, verbose=TRUE)
        bimeras <- isBimeraDenovo(seqtab2, multithread=threads, verbose = FALSE)
    } else {
        seqtab2.nochim <- seqtab2
    }

    # Export sequences and QC reports -------------------------------------------------------------------------------------------

    # ASV table
    asv <- data.frame(seqtab2.nochim)
    colnames(asv) <- c("count")
    asv <- cbind(asv, name = sprintf("ASV_%s", seq(1:dim(asv)[1])))
    asv <- cbind(asv, sequence = rownames(asv))
    rownames(asv) <- seq(1:dim(asv)[1])
    fn <- function(x) paste0(">", x[2], ";size=", trimws(x[1]), "\n", x[3])
    asfasta <- apply(asv, MARGIN=1, fn)
    writeLines(asfasta, asv_table)

    # Error plots
    errFplot <- plotErrors(errF, nominalQ=TRUE)
    ggsave(errplotF, width = 10, height = 10)
    errRplot <- plotErrors(errF, nominalQ=TRUE)
    ggsave(errplotR, width = 10, height = 10)

    # Denoising reports
    write.table(dadaFs$clustering, denoising_R1, quote = FALSE, sep = "\t", row.names = FALSE)
    write.table(dadaRs$clustering, denoising_R2, quote = FALSE, sep = "\t", row.names = FALSE)

    # Merged reads
    write.table(mergers, merged, quote = FALSE, sep = "\t", row.names = FALSE)

    # Chimeras
    if (chimera == TRUE) {
        bimeras <- bimeras[bimeras==TRUE]
        asfasta = vector()
        for (i in seq(1:length(bimeras))) {
            asfasta <- c(asfasta, paste0(">bimera_", i, "\n", names(bimeras)[i]))
        }
    } else {
        asfasta <- c("Skipped chimera detection")
    }
    writeLines(asfasta, chimeras_fasta)

    # Report
    track <- cbind(sample.names,
        out,
        round((out[1]-out[2])/out[1]*100, 2),
        getN(dadaFs),
        getN(dadaRs),
        getN(mergers),
        round((1-getN(mergers)/out[2])*100, 2),
        length(seqtab),
        length(seqtab2),
        round((length(seqtab)-length(seqtab2))/length(seqtab)*100, 2),
        round((sum(seqtab)-sum(seqtab2))/sum(seqtab)*100, 2),
        length(seqtab2.nochim),
        round((length(seqtab2)-length(seqtab2.nochim))/length(seqtab2)*100, 2),
        round((sum(seqtab2)-sum(seqtab2.nochim))/sum(seqtab2)*100, 2),
        sum(seqtab2),
        round(sum(seqtab2)/out[1]*100, 2)
    )
    colnames(track) <- c(
        "Sample",
        "Total reads", "Filtered reads",
        "Discarded reads [%]",
        "Denoised R1",
        "Denoised R2",
        "Merged",
        "Merging failures [%]",
        "ASV",
        "Size-filtered ASV",
        "Discarded ASVs [% ASV]",
        "Discarded ASVs [% of reads]",
        "Non-chimeric ASV",
        "Chimeras [% ASV]",
        "Chimeras [% of reads]",
        "Reads in ASVs",
        "Reads in ASVs [%]"
    )
    write.table(track, report, quote = FALSE, sep = "\t", row.names = FALSE)
    
}, error = function(e) {
    warning(paste0("Error message: ", e$message))
    warning("Terminated process on error.")
    warning("Empty output files generated")
    
    if (!exists(errplotF)){
        ggplot() +
        theme_void() +
        geom_text(aes(0,0,label='N/A')) +
        xlab(NULL)
        ggsave(errplotF)
    }
    if (!exists(errplotR)){
        ggplot() +
        theme_void() +
        geom_text(aes(0,0,label='N/A')) +
        xlab(NULL)
        ggsave(errplotR)
    }
    if (!exists(denoising_R1)){
        writeLines(
            "sequence	abundance	n0	n1	nunq	pval	birth_from	birth_pval	birth_fold	birth_ham	birth_qave",
            denoising_R1
        )
    }
    if (!exists(denoising_R2)){
        writeLines(
            "sequence	abundance	n0	n1	nunq	pval	birth_from	birth_pval	birth_fold	birth_ham	birth_qave",
            denoising_R2
        )
    }
    if (!exists(merged)){
        writeLines(
            "sequence	abundance	forward	reverse	nmatch	nmismatch	nindel	prefer	accept",
            merged
        )
    }
    if (!exists(asv_table)){
        writeLines("", asv_table)
    }
    if (!exists(report)){
        track <- cbind(
            sample.names,
            out,
            round((out[1]-out[2])/out[1]*100, 2),
            getN(dadaFs),
            getN(dadaRs),
            getN(mergers),
            round((1-getN(mergers)/out[2])*100, 2),
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        )
        colnames(track) <- c(
            "Sample",
            "Total reads", "Filtered reads",
            "Discarded reads [%]",
            "Denoised R1",
            "Denoised R2",
            "Merged",
            "Merging failures [%]",
            "ASV",
            "Size-filtered ASV",
            "Discarded ASVs [% ASV]",
            "Discarded ASVs [% of reads]",
            "Non-chimeric ASV",
            "Chimeras [% ASV]",
            "Chimeras [% of reads]",
            "Reads in ASVs",
            "Reads in ASVs [%]"
        )
        write.table(track, report, quote = FALSE, sep = "\t", row.names = FALSE)
    }
    if (!exists(chimeras_fasta)){
        writeLines("", chimeras_fasta)
    }
})
