process FASTP {
    tag "${meta.sample_id}"

    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastp:0.23.4--hadf994f_2' :
        'quay.io/biocontainers/fastp:0.23.4--hadf994f_2' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*trim.fastq.gz'), emit: reads
    tuple val(meta), path('*.json'), emit: json
    path('versions.yml'), emit: versions

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"
    def suffix = task.ext.suffix ?: "trim.fastq.gz"
    def trimmed  = meta.single_end ? "--out1 ${prefix}.trim.${suffix}" : "--out1 ${prefix}_1.${suffix} --out2 ${prefix}_2.${suffix}"

    r1 = reads.first()

    json = prefix + '.fastp.json'
    html = prefix + '.fastp.html'

    if (meta.single_end) {
        r1_trim = r1.getBaseName() + suffix
        """
        fastp --in1 ${r1} \
        $trimmed \
        -w ${task.cpus} \
        -j $json \
        -h $html $args

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
        END_VERSIONS
        """
    } else {
        r2 = reads[1]
        r1_trim = r1.getBaseName() + suffix
        r2_trim = r2.getBaseName() + suffix
        """
        fastp --in1 ${r1} --in2 ${r2} \
        $trimmed \
        -w ${task.cpus} \
        -j $json \
        -h $html \
        $args

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
        END_VERSIONS

        """
    }
}
