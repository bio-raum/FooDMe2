include { DADA2_FILTNTRIM }             from './../../modules/dada2/filterntrim'
include { DADA2_ERROR }                 from './../../modules/dada2/error'
include { DADA2_DENOISING }             from './../../modules/dada2/denoising'
include { DADA2_DENOISING_FOR_JOIN }    from './../../modules/dada2/denoising_for_join'
include { DADA2_FILTERSIZE }            from './../../modules/dada2/filtersize'
include { DADA2_RMCHIMERA }             from './../../modules/dada2/rmchimera'
include { HELPER_SEQTABLE_TO_FASTA }    from './../../modules/helper/seqtable_to_fasta'
include { HELPER_DADA_STATS }           from './../../modules/helper/dada_stats'

workflow DADA2_WORKFLOW {
    take:
    reads

    main:

    ch_versions = channel.from([])
    ch_qc_files = channel.from([])
    ch_stat_reports = channel.from([]) // holds the meta-key specific reports in the correct order for stats to be computed
    ch_asvs = channel.from([])
    ch_seqtab = channel.from([])
    ch_filtered_reads = channel.from([])

    /*
    Check quality binning in the reads and warn
    if unexpected result is found
    */
    reads.branch { _m,r ->
        def is_binned = isBinnedFastq(r[0])
        binned: is_binned
        unbinned: !is_binned
    }.set { ch_illumina_binning }

    // Check if read binning matches the command line flag, but only for Illumina
    if (params.binned_qual) {
        ch_illumina_binning.unbinned.subscribe { m, _r ->
            if (m.platform == "ILLUMINA") {
                log.warn "Expected binned qualities - but ${m.sample_id} use unbinned qualities!\n"
            }
        }
    } else {
        ch_illumina_binning.binned.subscribe { m, _r ->
            if (m.platform == "ILLUMINA") {
                log.warn "Expected unbinned qualities - but ${m.sample_id} seems to use binned qualities!\n"
            }
        }
    }

    /*
    Filter reads; trimming is done by Cutadapt
    */
    DADA2_FILTNTRIM(
        reads
    )
    ch_filtered_reads = ch_filtered_reads.mix(DADA2_FILTNTRIM.out.filtered_reads)
    ch_versions = ch_versions.mix(DADA2_FILTNTRIM.out.versions)
    
    ch_stat_reports = reads.join(DADA2_FILTNTRIM.out.filtered_reads)
    
    /*
    DADA2 Error model calculation
    */
    DADA2_ERROR(
        ch_filtered_reads
    )
    ch_versions = ch_versions.mix(DADA2_ERROR.out.versions)

    // Join filtered reads with the corresponding error model
    ch_reads_with_errors = ch_filtered_reads.join(DADA2_ERROR.out.errormodel)

    /*
    DADA2 denoise and merge reads
    */
    if (params.non_overlapping) {
        DADA2_DENOISING_FOR_JOIN(
            ch_reads_with_errors
        )
        ch_versions = ch_versions.mix(DADA2_DENOISING_FOR_JOIN.out.versions)
        ch_stat_reports = ch_stat_reports.join(DADA2_DENOISING_FOR_JOIN.out.mergers)
        ch_seqtab = ch_seqtab.mix(DADA2_DENOISING_FOR_JOIN.out.seqtab)
    } else {
        DADA2_DENOISING(
            ch_reads_with_errors
        )
        ch_versions = ch_versions.mix(DADA2_DENOISING.out.versions)
        ch_stat_reports = ch_stat_reports.join(DADA2_DENOISING.out.mergers)
        ch_seqtab = ch_seqtab.mix(DADA2_DENOISING.out.seqtab)
    }
    /*
    Filter by merged read size
    */
    DADA2_FILTERSIZE(
        ch_seqtab
    )
    ch_versions = ch_versions.mix(DADA2_FILTERSIZE.out.versions)
    ch_stat_reports = ch_stat_reports.join(DADA2_FILTERSIZE.out.filtered)

    // Remove chimera
    if (params.remove_chimera) {
        DADA2_RMCHIMERA(
            DADA2_FILTERSIZE.out.filtered
        )
        ch_versions = ch_versions.mix(DADA2_RMCHIMERA.out.versions)
        ch_asvs = ch_asvs.mix(DADA2_RMCHIMERA.out.rds)
    } else {
        ch_asvs = ch_asvs.mix(DADA2_FILTERSIZE.out.filtered)
    }
    // Convert Dada2 Seq table to FASTA file
    HELPER_SEQTABLE_TO_FASTA(
        ch_asvs
    )
    ch_versions = ch_versions.mix(HELPER_SEQTABLE_TO_FASTA.out.versions)
    ch_stat_reports = ch_stat_reports.join(ch_asvs)

    // Denoising stats
    HELPER_DADA_STATS(
        ch_stat_reports
    )
    ch_versions = ch_versions.mix(HELPER_DADA_STATS.out.versions)
    ch_qc_files = ch_qc_files.mix(HELPER_DADA_STATS.out.json)

    emit:
    otus = HELPER_SEQTABLE_TO_FASTA.out.fasta
    versions = ch_versions
    qc = ch_qc_files
    stats = HELPER_DADA_STATS.out.json

}

def isBinnedFastq(reads) {
    if (!reads.exists()) {
        throw new IllegalArgumentException("No such file: ${reads.toString()}")
    }

    int lineCounter = 0
    int readsAnalyzed = 0
    // atomic storage of quality characters (unique)
    Set<Character> uniqueQualityChars = []

    try {
        reads.withInputStream { inputStream ->
            new java.util.zip.GZIPInputStream(inputStream).eachLine { line ->
                lineCounter = lineCounter + 1
                
                // The 4th line contains the encoded quality
                if (lineCounter % 4 == 0) {
                    readsAnalyzed = readsAnalyzed + 1
                    
                    // collect the unique quality characters
                    line.each { ch ->
                        uniqueQualityChars.add(ch)
                    }
                    
                    // Around 100 reads should give a sufficent sampling
                    if (readsAnalyzed >= 100) {
                        throw new RuntimeException("Scan beendet")
                    }
                }
            }
        }
    } catch (RuntimeException e) {
        // abort stream if something goes wrong
    }

    // Unbinned data (e.g. MiSeq) typically shows > 25 quality characters across 100 Reads
    // Novaseq etc will show less than 10
    return uniqueQualityChars.size() <= 10
}