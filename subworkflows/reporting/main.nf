include { HELPER_REPORT_XLSX }              from './../../modules/helper/report_xlsx'
include { HELPER_KRONA_TABLE }              from './../../modules/helper/krona_table'
include { KRONA_HTML }                      from './../../modules/krona/'
include { HELPER_HTML_REPORT }              from './../../modules/helper/html_report'
include { HELPER_REPORTS_JSON }             from './../../modules/helper/reports_json'

workflow REPORTING {

    take:
    ch_tax_json // The filtered taxonomy JSON
    ch_versions
    ch_template  // Quarto template for custom HTML report
    ch_reports   // all sample level reports
    pipeline_info 

    main:

    ch_html_report  = Channel.from([])
    ch_xlsx         = Channel.from([])

    // The sample-level summary JSON
    HELPER_REPORTS_JSON(
        ch_reports.groupTuple(),
        ch_versions.collect()
    )

    // Excel report
    HELPER_REPORT_XLSX(
        HELPER_REPORTS_JSON.out.json.map {m,j -> j}.collect()
    )

    ch_xlsx = ch_xlsx.mix(HELPER_REPORT_XLSX.out.xlsx)

    // Krona
    HELPER_KRONA_TABLE(
        HELPER_REPORTS_JSON.out.json,
        ch_tax_json.collect()
    )

    KRONA_HTML(
        HELPER_KRONA_TABLE.out.krona.collect()
    )

    /*
    Write a summary report across all samples using
    a customizable Quarto template
    */
    if (!params.skip_report) {
        HELPER_HTML_REPORT(
            HELPER_REPORTS_JSON.out.json.map {m,j -> j}.collect(),
            KRONA_HTML.out.html,
            ch_template,
            pipeline_info
        )

        ch_html_report = ch_html_report.mix(HELPER_HTML_REPORT.out.html)
    }

    emit:
    versions = ch_versions
    xlsx     = ch_xlsx
    report   = ch_html_report
}
