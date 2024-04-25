process SINTAX_OTU2JSON {
    tag "$meta.sample_id"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl-json:4.10--pl5321hdfd78af_0' :
        'quay.io/biocontainers/perl-json:4.10--pl5321hdfd78af_0' }"

    input:
    tuple val(meta), path(sintax), path(otu_tab)

    output:
    tuple val(meta), path(result), emit: json
    path 'versions.yml'    , emit: versions

    script:
    def args = task.ext.args ?: ''
    result = meta.sample_id + '.taxonomy_by_sample.json'

    """
    sintax_otu2json_v2.pl --sintax $sintax --otu $otu_tab --outfile $result $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl --version  | head -n2 | tail -n1 | sed -e "s/.*(//" -e "s/).*//")
    END_VERSIONS
    """
}
