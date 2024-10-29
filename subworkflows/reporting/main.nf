include { HELPER_REPORT_XLSX }              from './../../modules/helper/report_xlsx'
include { HELPER_KRONA_TABLE }              from './../../modules/helper/krona_table'
include { KRONA_HTML }                      from './../../modules/krona/'
include { HELPER_BENCHMARK }                from './../../modules/helper/benchmark'
include { HELPER_BENCHMARK_XLSX }           from './../../modules/helper/benchmark_xlsx'
include { HELPER_SAMPLE_REPORT }            from './../../modules/helper/sample_report'
include { HELPER_HTML_REPORT }              from './../../modules/helper/html_report'

ch_versions = Channel.from([])
ch_truthtable = params.ground_truth ? Channel.fromPath(file(params.ground_truth, checkIfExists:true)) : Channel.value([])


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
    ch_fastp_json
    ch_template  // Jinja tempalte for custom HTML report


    main:

    // Excel report
    HELPER_REPORT_XLSX(
        ch_compo.map { m, t -> t }.collect()
    )

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
        ch_cutadapt
    ).join(
        ch_blast
    ).join(
        ch_consensus
    ).join(
        ch_fastp_json, remainder: true
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

    // Benchmark
    if (params.ground_truth) {
        ch_compo_agg = ch_compo.map { m, t -> t }.collectFile(name: 'composition.tsv', keepHeader: true)

        HELPER_BENCHMARK(
            ch_compo_agg,
            ch_truthtable,
            ch_tax_json.collect(),
            params.benchmark_rank,
            params.benchmark_cutoff
        )

        HELPER_BENCHMARK_XLSX(
            HELPER_BENCHMARK.out.results.collect()
        )
    }

    emit:
    versions = ch_versions
}
