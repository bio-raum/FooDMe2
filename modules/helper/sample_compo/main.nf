process HELPER_SAMPLE_COMPO {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioinfokit:2.1.3--pyh7cba7a3_0' :
        'quay.io/biocontainers/bioinfokit:2.1.3--pyh7cba7a3_0' }"

    input:
    tuple val(meta), path(json) // The json with consensus
    output:
    tuple val(meta), path('*.composition.tsv') , emit: tsv
    tuple val(meta), path('*.composition.json'), emit: json
    path 'versions.yml'                        , emit: versions

    script:
    def prefix = task.ext.prefix ?: json.getSimpleName()

    """
    sample_compo.py --json $json --output_tsv ${prefix}.composition.tsv --output_json ${prefix}.composition.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
