process INSTALL_GENBANK {
    tag "GenBank nt"

    label 'long_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    output:
    tuple val(meta), path("genbank_nt"), emit: db
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''

    """
    fetch_nt_blast.sh $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(echo \$(wget --version 2>&1) | head -n1 | cut -f3 -d " ")
    END_VERSIONS

    """
}
