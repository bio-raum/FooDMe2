process MD5SUM {

    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/52/52ccce28d2ab928ab862e25aae26314d69c8e38bd41ca9431c67ef05221348aa/data'
        : 'community.wave.seqera.io/library/coreutils_grep_gzip_lbzip2_pruned:838ba80435a629f8'}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.md5")  , emit: checksum
    path("versions.yml")            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"

    """
    find -L * -type f \\
            ! -name '*.md5' \\
            -exec md5sum ${args} "{}" + \\
            > ${prefix}.md5

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        md5sum: \$(echo \$(md5sum --version | sed '1!d; s/.* //'))
    END_VERSIONS
    """
}
