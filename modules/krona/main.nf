process KRONA_HTML {
    tag 'krona'
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/krona:2.8.1--pl5321hdfd78af_1' :
        'quay.io/biocontainers/krona:2.8.1--pl5321hdfd78af_1' }"

    input:
    path(table)

    output:

    path('*.html')   , emit: html
    path 'versions.yml'  , emit: versions

    script:
    def prefix = task.ext.prefix ?: params.run_name + "_krona"

    """
    ktImportText ${table} -o ${prefix}.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: \$(blastn -version 2>&1 | sed 's/^.*blastn: //; s/ .*\$//')
    END_VERSIONS
    """
}
