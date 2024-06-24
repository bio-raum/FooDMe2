process HELPER_FORMAT_GENBANK_TAXIDS {
    tag "${zipped}"

    label 'medium_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    input:
    tuple val(meta), path(zipped)

    output:
    tuple val(meta), path('genbank2taxid')  , emit: tab
    path("versions.yml")                    , emit: versions

    script:
    def args = task.ext.args ?: ''

    """
    gunzip $args -c $zipped | cut -f 1,3 | tail -n +2 > genbank2taxid

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        awk: \$(echo \$(awk --version 2>&1) | head -n1 | cut -f3 -d '' | sed 's/,//')
    END_VERSIONS

    """
}
