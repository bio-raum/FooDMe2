process HELPER_FORMAT_UNITE {
    tag "${meta.id}"

    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    input:
    tuple val(meta), path(fa, stageAs: 'raw/?')

    output:
    tuple val(meta), path('*.fasta')  , emit: clean
    path("versions.yml")              , emit: versions

    script:
    // def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: 'unite'

    """
    awk -F'|' '{if (\$0 ~ /^>/) {print ">"\$2} else { print \$0 }}' $fa > ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gunzip: \$(echo \$(gunzip --version 2>&1) | sed 's/^.*(gzip) //; s/ Copyright.*\$//')
    END_VERSIONS

    """
}
