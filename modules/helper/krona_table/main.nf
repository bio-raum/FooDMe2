process HELPER_KRONA_TABLE {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container 'gregdenay/taxidtools:3.1.0'

    input:
    tuple val(meta), path(table)    // composition table
    path(taxonomy)                  // taxonomy json

    output:
    path('*.txt')      , emit: krona
    path 'versions.yml', emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.sample_id}"

    """
    make_krona_table.py \\
    --table $table \\
    --tax $taxonomy \\
    --output ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
