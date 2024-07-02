include { HELPER_REPORT_XLSX }              from './../../modules/helper/report_xlsx'

ch_versions = Channel.from([])

workflow REPORTING {
    take:
    ch_compo

    main:

    HELPER_REPORT_XLSX(
        ch_compo.map { m,t -> t}.collect()
    )

    emit:
    versions = ch_versions
}