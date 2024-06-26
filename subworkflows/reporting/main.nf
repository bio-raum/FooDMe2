include {}              from './../../modules/helper/blast_stats'

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

    /*
    Sample composition
    */

    emit:
    version = ch_versions
}