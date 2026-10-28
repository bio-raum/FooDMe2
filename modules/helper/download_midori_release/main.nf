process HELPER_DOWNLOAD_MIDORI_RELEASE {
    tag "${meta.id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/aminoextract:0.3.1--pyhdfd78af_0' :
        'quay.io/biocontainers/aminoextract:0.3.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), val(version)

    output:
    tuple val(meta), path("download/BLAST/uniq/fasta/*.zip")  , emit: zips
    path 'versions.yml'                                 , emit: versions

    script:
    """
    download_midori_release.py --version $version \
    --outdir download/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
