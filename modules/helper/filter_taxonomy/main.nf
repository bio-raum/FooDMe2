process HELPER_FILTER_TAXONOMY {
    tag "Taxdump"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "gregdenay/taxidtools:devel"

    input:
    tuple path(nodes),path(rankedlineage)
    val(taxid)

    output:
    path('*.json')      , emit: json
    path 'versions.yml' , emit: versions

    script:
    json = "taxonomy.json"
    """
    filter_taxonomy.py --nodes $nodes \\
    --rankedlineage $rankedlineage \\
    --taxid $taxid \\
    --json $json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
