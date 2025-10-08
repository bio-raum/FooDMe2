process SAMTOOLS_STATS {
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_0' }"

    tag "${meta.sample_id}"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.stats"),   emit: stats
    path("versions.yml"),           emit: versions

    script:
    def stats = bam.getBaseName() + ".stats"
    """
    samtools stats $bam > $stats

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}

