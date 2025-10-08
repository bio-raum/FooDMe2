process SAMTOOLS_COVERAGE {

    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.coverage.txt"),    emit: txt
    path("versions.yml"),                       emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"

    """
    samtools coverage $args -o ${prefix}.coverage.txt $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}

