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
    val(meta)

    output:
    path('*.html')          , emit: html
    path 'versions.yml'     , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: params.run_name
    def ont = params.ont
    def non_overlapping = params.non_overlapping

    result = prefix + '.html'

    def mode =
        ont ? "ONT" :
        non_overlapping ? "PE_NON" :
        meta.single_end ? "SINGLE" :
        "PE_OVER"

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
