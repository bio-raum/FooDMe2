process HELPER_FORMAT_MIDORI {
    tag "${meta.id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/aminoextract:0.3.1--pyhdfd78af_0' :
        'quay.io/biocontainers/aminoextract:0.3.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fa, stageAs: 'midori/')   // the midori database in FASTA format, staged into subfolder midori

    output:
    tuple val(meta), path('*.fasta'), path('*.taxids'), emit: midori
    tuple val(meta), path('*.idmap')                    , emit: idmap
    path 'versions.yml'                                 , emit: versions

    script:
    prefix = meta.id
    """
    format_midori.py --fasta $fa \
    --output $prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
