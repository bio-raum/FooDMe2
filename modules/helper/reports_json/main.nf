process HELPER_REPORTS_JSON {
    tag "${meta.sample_id}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.27.1--pyhdfd78af_0' :
        'quay.io/biocontainers/multiqc:1.27.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(reports, stageAs: '?/*')
    path(yaml)

    output:
    tuple val(meta), path('*summary.json') , emit: json
    path 'versions.yml'             , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id
    result = prefix + '.summary.json'

    """
    foodme2_json.py --sample ${meta.sample_id} \
    --yaml $yaml \\
    $args \
    --output $result

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
