process UNTAR {
    tag "$archive"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    input:
    tuple val(meta), path(archive)

    output:
    tuple val(meta), path("$prefix")        , emit: untar
    tuple val(meta), path("$prefix/*.fasta"), optional: true, emit: fasta
    path 'versions.yml'                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args  = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    prefix    = task.ext.prefix ?: (meta.id ? "${meta.id}" : archive.baseName.toString().replaceFirst(/\.tar$/, ''))

    """
    mkdir $prefix

    ## Ensures --strip-components only applied when top level of tar contents is a directory
    ## If just files or multiple directories, place all in prefix
    if [[ \$(tar -taf ${archive} | grep -o -P "^.*?\\/" | uniq | wc -l) -eq 1 ]]; then
        tar \\
            -C $prefix --strip-components 1 \\
            -xavf \\
            $args \\
            $archive \\
            $args2
    else
        tar \\
            -C $prefix \\
            -xavf \\
            $args \\
            $archive \\
            $args2
    fi

    rm -f $prefix/*_dev.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        untar: \$(echo \$(tar --version 2>&1) | sed 's/^.*(GNU tar) //; s/ Copyright.*\$//')
    END_VERSIONS
    """
}
