process SAMTOOLS_AMPLICONCLIP {

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_0' }"

    tag "${meta.sample_id}"

    publishDir "${params.outdir}/${meta.sample_id}/", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)
    path(bed)

    output:
    tuple val(meta), path(bam_masked), path(bam_masked_bai), emit: bam
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: bam.getBaseName()

    bam_masked = prefix + '-amplicon_clipped.bam'
    bam_masked_bai = bam_masked + '.bai'

    """
    samtools ampliconclip $args -b $bed $bam | samtools sort -o $bam_masked
    samtools index $bam_masked

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
