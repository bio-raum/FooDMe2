process BLAST_TAXONOMY_FROM_DB {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/blast:2.15.0--pl5321h6f7f691_1' :
        'quay.io/biocontainers/blast:2.15.0--pl5321h6f7f691_1' }"

    input:
    tuple val(meta), path(db)

    output:
    path('*.list')          , emit: list
    path 'versions.yml'     , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.id

    """
    blastcmd -db $db \\
    -tax_info \\
    -outfmt %T > ${prefix}.list

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
