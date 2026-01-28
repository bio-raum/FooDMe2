process SEQFU_RC {
    tag "$fa"
    label 'short_serial'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqfu:1.20.3--h1eb128b_2':
        'quay.io/biocontainers/seqfu:1.20.3--h1eb128b_2' }"

    input:
    path(fa)

    output:
    path("*rc.fasta")   , emit: fasta
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: fa.getBaseName()

    """
    seqfu \\
        rc \\
        $args \\
        $fa > ${prefix}.rc.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        seqfu: \$(seqfu version)
    END_VERSIONS
    """

}
