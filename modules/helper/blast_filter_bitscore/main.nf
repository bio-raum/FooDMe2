process BLAST_FILTER_BITSCORE {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioinfokit:2.1.3--pyh7cba7a3_0' :
        'quay.io/biocontainers/bioinfokit:2.1.3--pyh7cba7a3_0' }"

    input:
    tuple val(meta),path(report),val(bit_diff)

    output:
    path(report_filtered)   , emit: tsv
    path 'versions.yml'     , emit: versions

    script:
    def args = task.ext.args ?: ''
    report_filtered = meta.sample_id + ".blast.filtered.tsv"
    
    """
    filter_blast.py
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl --version  | head -n2 | tail -n1 | sed -e "s/.*(//" -e "s/).*//")
    END_VERSIONS
    """
}
