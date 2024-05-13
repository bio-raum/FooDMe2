process HELPER_FORMAT_MIDORI {
    tag "${meta.id  }"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    input:
    tuple val(meta), path(fa, stageAs: 'midori/')

    output:
    tuple val(meta), path(clean), emit: fasta
    path 'versions.yml'             , emit: versions

    script:
    clean = fa.getName().split('/')[-1]
    """
    cut -d '#' -f1 $fa \\
        | tr -d '<' \\
        | sed 's/^>/@/' \\
        | tr -d '>' \\
        | tr '@' '>' \\
        | cut -d ',' -f1,2 \\
        | tr ',' '_' \\
        > $clean

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cut: \$(echo \$(cut --version 2>&1) | head -n1 | sed 's/^.*coreutils) //')
    END_VERSIONS
    """
}
