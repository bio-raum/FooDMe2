process FASTPLONG {
    tag "${meta.sample_id}"

    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastplong:0.3.0--h224cc79_0' :
        'quay.io/biocontainers/fastplong:0.3.0--h224cc79_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*trim.fastq.gz'), emit: reads
    tuple val(meta), path('*.json'), emit: json
    path('versions.yml'), emit: versions

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"
    def suffix = task.ext.suffix ?: "trim"

    json = prefix + "." + suffix + '.fastplong.json'
    html = prefix + "." + suffix + '.fastplong.html'

    """
    fastplong --in ${reads} \
    --out ${prefix}.${suffix}.fastq.gz \
    -w ${task.cpus} \
    -j $json \
    -h $html \
    $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastplong: \$(fastplong -v 2>&1 | sed -e "s/fastplong //g")
    END_VERSIONS

    """
}
