include { CUTADAPT }                    from './../../modules/cutadapt'
include { PTRIMMER }                    from './../../modules/ptrimmer'

ch_versions = Channel.from([])

workflow REMOVE_PCR_PRIMERS {
    take:
    reads
    ch_ptrimmer_config
    ch_primers
    ch_primers_rc

    main:
    // Allow use of cutadapt if need be
    if (params.cutadapt) {
        // Run cutadapt
        CUTADAPT(
            reads,
            ch_primers,
        )
        ch_versions = ch_versions.mix(CUTADAPT.out.versions)
        ch_reads_no_primers = CUTADAPT.out.reads
    } else {
        /*
        Run Ptrimmer using the appropriate config file.
        */
        PTRIMMER(
            reads,
            ch_ptrimmer_config
        )
        ch_versions = ch_versions.mix(PTRIMMER.out.versions)
        ch_reads_no_primers = PTRIMMER.out.reads
    }

    emit:
    reads = ch_reads_no_primers
    versions = ch_versions
}
