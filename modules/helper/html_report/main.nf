process HELPER_HTML_REPORT {
    tag "All"

    conda "${moduleDir}/environment.yml"
    container "${ 'mhoeppner/quarto:1.5.57' }"

    input:
    path(reports)
    path(krona)
    path(template)
    path(pipeline_info)

    output:
    path('*.html')          , emit: html
    path 'versions.yml'     , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: params.run_name
    result = prefix + '.html'

    """
    quarto render $template --to html \
    --execute \
    $args \
    --output $result

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
