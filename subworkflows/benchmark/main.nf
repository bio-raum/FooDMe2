include { HELPER_BENCHMARK }                from './../../modules/helper/benchmark'
include { HELPER_BENCHMARK_XLSX }           from './../../modules/helper/benchmark_xlsx'

workflow BENCHMARK {

    take:
    ch_compo
    ch_tax_json
    ch_truthtable

    main:
    // Benchmark
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