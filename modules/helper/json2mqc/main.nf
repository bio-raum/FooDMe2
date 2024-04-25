process JSON2MQC {
    tag "$meta.sample_id"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl-json-xs:4.03--pl5321h4ac6f70_2' :
        'quay.io/biocontainers/perl-json-xs:4.03--pl5321h4ac6f70_2' }"

    input:
    tuple val(meta), path(json)

    output:
    path('*mqc.json'), emit: mqc_json
    path 'versions.yml'    , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: params.run_name
    
    result = prefix + '.taxonomy_by_sample_mqc.json'

    """
    eutaxpro_json2mqc.pl --json $json --outfile $result $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl --version  | head -n2 | tail -n1 | sed -e "s/.*(//" -e "s/).*//")
    END_VERSIONS
    """
}
