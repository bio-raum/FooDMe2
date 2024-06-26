include { HELPER_BLAST_STATS }              from './../../modules/helper/blast_stats'
include { HELPER_SAMPLE_COMPO }             from './../../modules/helper/sample_compo'

ch_versions = Channel.from([])

workflow REPORTING {
    take:
    bitscore
    consensus

    main:

    // FASTP automatically handled by MultiQC

    if (params.dada) {
        /*
        DADA2 denoising
        */
    } else {
        /*
        VSEARCH clustering
        */
    }

    /*
    BLAST search
    */
    HELPER_BLAST_STATS(
        bitscore
    )
    ch_versions = ch_versions.mix(HELPER_BLAST_STATS.out.versions)

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