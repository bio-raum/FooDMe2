process MINIMAP2_ALIGN {
    tag "$meta.sample_id"
    label 'medium_parallel'

    // Note: the versions here need to match the versions used in the mulled container below and minimap2/index
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' :
        'quay.io/biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' }"

    input:
    tuple val(meta), path(reads), path(reference)

    output:
    tuple val(meta), path("*.bam")                       , emit: bam
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args  = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"
    def bam = "${prefix}.bam"
    def rg = "-R \"@RG\\tID:${prefix}_NANOPORE\\tPL:NANOPORE\\tSM:${meta.sample_id}\""

    """
    minimap2 \\
    $args \\
    -a \\
    -t $task.cpus \\
    $rg \\
    $reference \\
    $reads \\
    | samtools sort -@ ${task.cpus} - | samtools view -h -b -F 256 -o $bam -
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """

}
