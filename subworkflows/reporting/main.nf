include { HELPER_REPORT_XLSX }              from './../../modules/helper/report_xlsx'
include { HELPER_KRONA_TABLE }              from './../../modules/helper/krona_table'
include { KRONA_HTML }                      from './../../modules/krona/'

ch_versions = Channel.from([])

workflow REPORTING {
    take:
    ch_tax_json // The filtered taxonomy JSON
    ch_compo

    main:

    // Excel report
    HELPER_REPORT_XLSX(
        ch_compo.map { m,t -> t}.collect()
    )

    // Krona
    HELPER_KRONA_TABLE(
        ch_compo,
        ch_tax_json.collect()
    )

    KRONA_HTML(
        HELPER_KRONA_TABLE.out.krona.collect()
    )

    emit:
    versions = ch_versions
}