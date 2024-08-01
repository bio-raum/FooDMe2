process FASTX_REVERSE_COMPLEMENT {
    label 'short_serial'

    tag "${fa}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastx_toolkit:0.0.14--hdbdd923_11' :
        'quay.io/biocontainers/fastx_toolkit:0.0.14--hdbdd923_11' }"

    input:
    path(fa)

    output:
    path(fasta_rc), emit: fasta
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: fa.getBaseName()

    fasta_rc = prefix + '.rc.fasta'

    """
    fastx_reverse_complement $args -i $fa -o $fasta_rc

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastx-toolkit: \$(echo \$(fastx_reverse_complement -h | head -n 2 | tail -n1 | sed -e "s/^Part of FASTX Toolkit //" -e "s/ by.*//"))
    END_VERSIONS

    """
}
