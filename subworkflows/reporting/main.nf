include { HELPER_SAMPLE_COMPO }             from './../../modules/helper/sample_compo'
include { HELPER_REPORT_XLSX }              from './../../modules/helper/report_xlsx'

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

    HELPER_REPORT_XLSX(
        HELPER_SAMPLE_COMPO.out.tsv.map { m,t -> t}.collect()
    )

    emit:
    versions = ch_versions
}