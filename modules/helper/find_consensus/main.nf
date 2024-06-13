process HELPER_FIND_CONSENSUS {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container 'gregdenay/taxidtools:devel'

    input:
    tuple val(meta), path(report)   // the pre-filtered blast report in custom TSV format
    val(consensus)                  // The consensus taxonomy assignment for each OTU
    path(json)                      // the Taxonomy file in JSON for taxidtools

    output:
    path('*.tsv')       , emit: tsv
    path 'versions.yml' , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.sample_id}"

    """
    min_consensus_filter.py \\
    --blast $report \\
    --taxonomy $json \\
    --min_consensus $consensus \\
    --output ${prefix}_consensus.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
