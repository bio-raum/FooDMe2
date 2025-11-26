process SAMTOOLS_VIEW {
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_0' }"

    tag "${meta.sample_id}"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.filtered.bam") ,   emit: bam
    path("versions.yml")                    ,   emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.sample_id}"
    def args = task.ext.args ?: ''
    
    """
    samtools view -h -b $args -o ${prefix}.filtered.bam $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}

