include { DADA2_FILTNTRIM }             from './../../modules/dada2/filterntrim'
include { DADA2_ERROR }                 from './../../modules/dada2/error'
include { DADA2_DENOISING }             from './../../modules/dada2/denoising'
include { DADA2_DENOISING_FOR_JOIN }    from './../../modules/dada2/denoising_for_join'
include { DADA2_FILTERSIZE }            from './../../modules/dada2/filtersize'
include { DADA2_RMCHIMERA }             from './../../modules/dada2/rmchimera'
include { HELPER_SEQTABLE_TO_FASTA }    from './../../modules/helper/seqtable_to_fasta'
include { HELPER_DADA_STATS }           from './../../modules/helper/dada_stats'
include { HELPER_CHECK_BINNING }        from './../../modules/helper/check_binning'
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
    if unexpected result is found - we only do this
    for Illumina data
    */
    if (!params.pacbio && !params.iontorrent && !params.ont) {

        HELPER_CHECK_BINNING(reads)

        HELPER_CHECK_BINNING.out.binned_status.join(reads).branch { m, status_file, fastq ->
            def is_binned_value = status_file.text.trim()
            binned: is_binned_value == "true"
                [ m, fastq]
            unbinned: is_binned_value == "false"
                [ m, fastq]
        }.set { ch_illumina_binning}

        // Check if read binning matches the command line flag, but only for Illumina
        if (params.binned_qual) {
            ch_illumina_binning.unbinned.subscribe { m, _r ->
                log.warn "Expected binned qualities - but ${m.sample_id} seems to use unbinned qualities!\n"
            }
        } else {
            ch_illumina_binning.binned.subscribe { m, _r ->
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



