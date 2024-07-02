include { HELPER_BLAST_STATS }              from './../../modules/helper/blast_stats'
include { HELPER_SAMPLE_COMPO }             from './../../modules/helper/sample_compo'
include { HELPER_REPORT_XLSX }              from './../../modules/helper/report_xlsx'

ch_versions = Channel.from([])

workflow REPORTING {
    take:
    bitscore
    consensus

    main:

    // FASTP automatically handled by MultiQC

    if (params.vsearch) {
        /*
        VSEARCH clustering
        */
    } else {
        /*
        DADA2 denoising
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

    HELPER_REPORT_XLSX(
        HELPER_SAMPLE_COMPO.out.tsv.map { m,t -> t}.collect()
    )

    emit:
    versions = ch_versions
}