process HELPER_FILTER_TAXONOMY {
    tag 'Taxdump'
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container 'gregdenay/taxidtools:3.1.0'

    input:
    tuple path(nodes), path(rankedlineage), path(merged)  // nodes.dmp, rankedlineage.dmp and merged.dmp from the ncbi taxonomy
    val(taxid)                              // the root taxid to filter the taxonomy file by

    output:
    path('*.json')      , emit: json
    path 'versions.yml' , emit: versions

    script:
    json = 'taxonomy.json'
    """
    filter_taxonomy.py --nodes $nodes \\
    --rankedlineage $rankedlineage \\
    --merged $merged \\
    --taxid $taxid \\
    --json $json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
