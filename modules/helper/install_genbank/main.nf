process HELPER_INSTALL_GENBANK {
    tag "GenBank nt"

    label 'long_serial'

    /*
    Seems like no bioconda container has the proper wget available, so we have to resort to Dockerhub 
    */
    conda "${moduleDir}/environment.yml"
    container "biocontainers/ncbi-datasets-cli:15.12.0_cv23.1.0-4"

    output:
    tuple val(meta), path("core_nt"), emit: db
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
