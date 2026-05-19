process HELPER_HTML_REPORT {
    tag "All"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ 'mhoeppner/quarto:1.5.57' }"

    input:
    path(reports)
    path(krona)
    path(assets)
    path(pipeline_info)

    output:
    path('*.html')          , emit: html
    path 'versions.yml'     , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: params.run_name
    def mode="PE_OVER"  // need to check if ont is on and if single or paired end
    result = prefix + '.html'

    """
    cp -r ${assets}/* .
    export REPORT_MODE=$mode
    quarto render report.qmd --to html \
        --execute \
        $args --execute-daemon-restart \
        --output $result

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
