process HELPER_INSTALL_GENBANK {
    tag "GenBank nt"

    label 'long_serial'

    /*
    Yes, this uses the vsearch container because it happens to have an up-to-date version
    of wget whereas gnu-wget is woefully outdated and does not support TSL. Go figure. 
    */
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vsearch:2.27.0--h6a68c12_0' :
        'quay.io/biocontainers/vsearch:2.27.0--h6a68c12_0' }"

    output:
    tuple val(meta), path("genbank_nt"), emit: db
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''

    """
    fetch_nt_blast.sh $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(echo \$(wget --version 2>&1) | head -n1 | cut -f3 -d " ")
    END_VERSIONS

    """
}
