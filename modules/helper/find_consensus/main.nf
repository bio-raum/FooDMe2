process HELPER_FIND_CONSENSUS {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container 'gregdenay/taxidtools:3.1.0'

    input:
    tuple val(meta), path(report), path(otus)   // the pre-filtered blast report in custom JSON format and OTUS fasta
    val(consensus)                              // The min consensus value for taxonomy assignment for each OTU
    path(json)                                  // the Taxonomy file in JSON for taxidtools

    output:
    tuple val(meta), path('*.consensus.json') , emit: json
    path 'versions.yml'      , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.sample_id}"

    """
    min_consensus_filter.py \\
    --blast $report \\
    --otus $otus \\
    --taxonomy $json \\
    --min_consensus $consensus \\
    --output ${prefix}.consensus.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
