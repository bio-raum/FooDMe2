include { HELPER_SAMPLE_COMPO }             from './../../modules/helper/sample_compo'

ch_versions = Channel.from([])

workflow REPORTING {
    take:
    consensus

    main:

    /*
    Sample composition
    */
    HELPER_SAMPLE_COMPO(
        consensus
    )
    ch_versions = ch_versions.mix(HELPER_BLAST_STATS.out.versions)

    emit:
    versions = ch_versions
}