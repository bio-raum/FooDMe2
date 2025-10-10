process HELPER_BLAST_HSP_MERGER {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioinfokit:2.1.3--pyh7cba7a3_0' :
        'quay.io/biocontainers/bioinfokit:2.1.3--pyh7cba7a3_0' }"

    input:
    tuple val(meta), path(xml)       // the BLAST result files

    output:
    tuple val(meta), path('*.txt') , emit: txt
    path 'versions.yml'            , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.sample_id}"
    def qcov = "${params.blast_qcov}"

    """
    blast_hsp_merger.py \\
    --xml $xml \\
    --output ${prefix}.txt \\
    --qcov_hsp $qcov

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
