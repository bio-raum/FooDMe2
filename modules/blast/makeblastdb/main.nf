process BLAST_MAKEBLASTDB {
    tag "$meta.id"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/blast:2.15.0--pl5321h6f7f691_1' :
        'quay.io/biocontainers/blast:2.15.0--pl5321h6f7f691_1' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${meta.id}"), emit: db
    path 'versions.yml'                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_compressed = fasta.getExtension() == 'gz' ? true : false
    def fasta_name = is_compressed ? fasta.getBaseName() : fasta
    """
    if [ "${is_compressed}" == "true" ]; then
        gzip -c -d ${fasta} > ${fasta_name}
    fi

    makeblastdb \\
        -in ${fasta_name} \\
        ${args}
    mkdir ${prefix}
    mv ${fasta_name}* ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: \$(blastn -version 2>&1 | sed 's/^.*blastn: //; s/ .*\$//')
    END_VERSIONS
    """
}
