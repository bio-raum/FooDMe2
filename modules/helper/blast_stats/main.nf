process HELPER_BLAST_STATS {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioinfokit:2.1.3--pyh7cba7a3_0' :
        'quay.io/biocontainers/bioinfokit:2.1.3--pyh7cba7a3_0' }"

    input:
    tuple val(meta), path(json) // The json with delta-bitscore values

    output:
    tuple val(meta), path('*.blast_stats.tsv'), emit: tsv
    path 'versions.yml'                       , emit: versions

    script:
    def prefix = task.ext.prefix ?: json.getSimpleName()

    """
    blast_stats.py --json $json --output ${prefix}.blast_stats.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
