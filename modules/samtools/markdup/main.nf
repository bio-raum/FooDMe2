process SAMTOOLS_MARKDUP {

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.19.2--h50ea8bc_0' :
        'quay.io/biocontainers/samtools:1.19.2--h50ea8bc_0' }"

    label 'medium_parallel'

    tag "${meta.sample_id}"

    publishDir "${params.outdir}/${meta.sample_id}/", mode: 'copy'

    input:
    tuple val(meta), path(merged_bam), path(merged_bam_index)
    tuple path(fasta), path(fai), path(dict)

    output:
    tuple val(meta), path(outfile_bam), path(outfile_bai), emit: bam
    path(outfile_metrics), emit: report
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id

    namePrefix = "${prefix}-dedup"
    outfile_bam = namePrefix + '.bam'
    outfile_bai = namePrefix + '.bam.bai'
    outfile_metrics = namePrefix + '_duplicate_metrics.txt'

    """
    samtools markdup $args -@ ${task.cpus} --reference $fasta $merged_bam $outfile_bam
    samtools index $outfile_bam
    samtools stats $outfile_bam > $outfile_metrics

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS

    """
}

