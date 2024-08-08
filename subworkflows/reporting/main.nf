include { HELPER_REPORT_XLSX }              from './../../modules/helper/report_xlsx'
include { HELPER_KRONA_TABLE }              from './../../modules/helper/krona_table'
include { KRONA_HTML }                      from './../../modules/krona/'
include { HELPER_BENCHMARK }                from './../../modules/helper/benchmark'
include { HELPER_BENCHMARK_XLSX }           from './../../modules/helper/benchmark_xlsx'

ch_versions = Channel.from([])
ch_truthtable = params.ground_truth ? Channel.fromPath(file(params.ground_truth, checkIfExists:true)) : Channel.value([])

workflow REPORTING {
    take:
    ch_tax_json // The filtered taxonomy JSON
    ch_compo

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
