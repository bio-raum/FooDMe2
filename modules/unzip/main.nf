process UNZIP {
    tag "${zipped}"

    label 'medium_serial'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mentalist:0.2.4--h031d066_7' :
        'quay.io/biocontainers/mentalist:0.2.4--h031d066_7' }"

    input:
    tuple val(meta), path(zipped)

    output:
    tuple val(meta), path(prefix), emit: unzip
    path("versions.yml"), emit: versions

    script:
    unzipped = zipped.getBaseName()
    prefix = meta.id

    """
    unzip -d ${prefix} $zipped

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        unzip: \$(echo \$(unzip --version 2>&1) | sed 's/^.*(unzip) //; s/ Copyright.*\$//')
    END_VERSIONS

    """
}
