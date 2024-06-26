include { HELPER_BLAST_STATS }              from './../../modules/helper/blast_stats'

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

    emit:
    versions = ch_versions
}