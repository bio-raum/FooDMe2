process HELPER_ONT_CLUSTER_REPORT {

    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioinfokit:2.1.3--pyh7cba7a3_0' :
        'quay.io/biocontainers/bioinfokit:2.1.3--pyh7cba7a3_0' }"

    input:
    tuple val(meta), path(report)

    output:
    tuple val(meta), path('*.json')       , emit: json
    path 'versions.yml'                     , emit: versions

    script:
    def prefix = task.ext.prefix ?: meta.sample_id

    """
    parse_savont_log.py \\
    --sample ${meta.sample_id} \\
    --log $report \\
    --output ${prefix}.ont_cluster_stats.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
