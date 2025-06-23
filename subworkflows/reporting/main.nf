include { HELPER_REPORT_XLSX }              from './../../modules/helper/report_xlsx'
include { HELPER_KRONA_TABLE }              from './../../modules/helper/krona_table'
include { KRONA_HTML }                      from './../../modules/krona/'
include { HELPER_SAMPLE_REPORT }            from './../../modules/helper/sample_report'
include { HELPER_HTML_REPORT }              from './../../modules/helper/html_report'
include { HELPER_REPORTS_JSON }             from './../../modules/helper/reports_json'

workflow REPORTING {

    take:
    ch_tax_json // The filtered taxonomy JSON
    ch_compo
    ch_compo_json
    ch_cutadapt
    ch_clustering
    ch_blast
    ch_consensus
    ch_versions
    ch_fastp_input_json
    ch_fastp_trim_json
    ch_template  // Quarto template for custom HTML report
    ch_reports

    main:

    HELPER_REPORTS_JSON(
        ch_reports.groupTuple(),
        ch_versions
    )

    ch_report = Channel.from([])
    ch_xlsx   = Channel.from([])

    // Excel report
    HELPER_REPORT_XLSX(
        HELPER_REPORTS_JSON.out.json.map {m,j -> j}.collect()
    )

    ch_xlsx = ch_xlsx.mix(HELPER_REPORT_XLSX.out.xlsx)

    // Krona
    HELPER_KRONA_TABLE(
        ch_compo,
        ch_tax_json.collect()
    )

    KRONA_HTML(
        HELPER_KRONA_TABLE.out.krona.collect()
    )

    /*
    Here we group all the sample-specific reports by meta hash
    the fastp report is optional in case of ONT data, so we need to account for that
    */

    ch_compo_json.join(
        ch_cutadapt, remainder: true
    ).join(
        ch_blast, remainder: true
    ).join(
        ch_consensus, remainder: true
    ).join(
        ch_fastp_input_json, remainder: true
    ).join(
        ch_fastp_trim_json, remainder: true
    ).set { ch_reports_grouped }

    /*
    Make a pretty JSON using the sample-specific reports and
    summary metrics from the clustering as well as software versions
    */

    HELPER_SAMPLE_REPORT(
        ch_reports_grouped,
        ch_clustering.collect(),
        ch_versions.collect()
    )

    /*
    Write a summary report across all samples using
    a customizable jinja2 template
    */
    HELPER_HTML_REPORT(
        HELPER_SAMPLE_REPORT.out.json.map {m,j -> j}.collect(),
        KRONA_HTML.out.html,
        ch_template,
    )

    ch_report = ch_report.mix(HELPER_HTML_REPORT.out.html)

    emit:
    versions = ch_versions
    xlsx     = ch_xlsx
    report   = ch_report
}
