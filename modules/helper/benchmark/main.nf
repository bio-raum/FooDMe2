process HELPER_BENCHMARK {
    tag 'benchmark'
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container 'gregdenay/taxidtools:3.1.0'


    input:
    path(composition)                           // composition table aggregated over all samples (with collectFiles?)
    path(truthtable)                            // Truth table (tsv)
    path(json)                                  // the Taxonomy file in JSON for taxidtools
    val(rank)                                   // max rank for postive match (string)
    val(cutoff)                                 // Proportion cutoff for positive result


    output:
    path('results.json')     , emit: results
    path('metrics.json')     , emit: metrics
    path('versions.yml')     , emit: versions

    script:
    results = 'results.json'
    metrics = 'metrics.json'

    """
    benchmark.py \\
    --compo $composition \\
    --truth $truthtable \\
    --taxonomy $json \\
    --rank $rank \\
    --cutoff $cutoff \\
    --results $results \\
    --metrics $metrics

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
