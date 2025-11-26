process HELPER_ONT_MAPPING_REPORT {

    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioinfokit:2.1.3--pyh7cba7a3_0' :
        'quay.io/biocontainers/bioinfokit:2.1.3--pyh7cba7a3_0' }"

    input:
    tuple val(meta), path(reports, stageAs: '?/*') //

    output:
    tuple val(meta), path('*.json')       , emit: json
    path 'versions.yml'                     , emit: versions

    script:
    def prefix = task.ext.prefix ?: meta.sample_id

    """
    ont_mapping_report.py \
    --sample_id ${meta.sample_id} \
    --before ${reports[0]} \
    --after ${reports[1]} \
    --output ${prefix}.ont_mapping_stats.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
