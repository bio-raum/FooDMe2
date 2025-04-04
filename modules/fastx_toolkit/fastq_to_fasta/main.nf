process FASTQ_TO_FASTA {
    label 'short_serial'

    tag "${fq}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastx_toolkit:0.0.14--hdbdd923_11' :
        'quay.io/biocontainers/fastx_toolkit:0.0.14--hdbdd923_11' }"

    input:
    tuple val(meta),path(fq)

    output:
    tuple val(meta),path(fasta), emit: fasta
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id

    fasta = prefix + ".fasta"

    """
    fastq_to_fasta $args -i $fq -o $fasta -Q33

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastx-toolkit: \$(echo \$(fastq_to_fasta -h | head -n 2 | tail -n1 | sed -e "s/^Part of FASTX Toolkit //" -e "s/ by.*//"))
    END_VERSIONS

    """
}
