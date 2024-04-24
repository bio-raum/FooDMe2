process GUNZIP {
    tag "${meta.target}|${zipped}"

    label 'medium_serial'

    publishDir "${params.outdir}/${meta.target}/${meta.tool}", mode: 'copy'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    input:
    tuple val(meta), path(zipped)

    output:
    tuple val(meta), path(unzipped), emit: gunzip
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: zipped.getBaseName()

    unzipped = prefix

    """
    gunzip $args -c $zipped > $unzipped

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gunzip: \$(echo \$(gunzip --version 2>&1) | sed 's/^.*(gzip) //; s/ Copyright.*\$//')
    END_VERSIONS

    """
}
