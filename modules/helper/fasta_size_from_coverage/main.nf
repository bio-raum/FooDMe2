process HELPER_FASTA_SIZE_FROM_COVERAGE {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biopython.convert:1.0.3--py_0' :
        'quay.io/biocontainers/biopython.convert:1.0.3--py_0' }"

    input:
    tuple val(meta), path(fasta), path(coverage)   // the unfiltered blast report in custom TSV format

    output:
    tuple val(meta), path('*.OTU.fasta')   , emit: fasta
    path 'versions.yml'                         , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id

    """
    fasta_size_from_coverage.py $args --fasta $fasta --coverage $coverage --output ${prefix}.OTU.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
