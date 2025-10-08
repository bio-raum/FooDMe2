process HELPER_FASTA_FILTER_CONSENSUS {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biopython.convert:1.0.3--py_0' :
        'quay.io/biocontainers/biopython.convert:1.0.3--py_0' }"

    input:
    tuple val(meta), path(fasta)   // the unfiltered blast report in custom TSV format

    output:
    tuple val(meta), path('*.filtered.fasta')   , emit: fasta
    path 'versions.yml'                         , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id

    """
    filter_fasta_consensus.py --fasta $fasta $args --output ${prefix}.filtered.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
