process CUTADAPT {
    tag "$meta.sample_id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cutadapt:4.6--py39hf95cd2a_1' :
        'quay.io/biocontainers/cutadapt:4.6--py39hf95cd2a_1' }"

    input:
    tuple val(meta), path(reads)
    path(primers)

    output:
    tuple val(meta), path('*.trim.fastq.gz'), emit: reads
    path('*.cutadapt.json')                 , emit: report
    tuple val(meta), path('*.log')          , emit: log
    path 'versions.yml'                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"
    def trimmed  = meta.single_end ? "-o ${prefix}.trim.fastq.gz" : "-o ${prefix}_1.trim.fastq.gz -p ${prefix}_2.trim.fastq.gz"
    def report = "${prefix}.cutadapt.json"
    def options_5p = ''
    def options_3p = ''
    if (meta.single_end) {
        options_5p = "-g ^file:${primers}"
        options_3p = "-a file\$:${primers}"
    } else {
        options_5p = "-g file:${primers} -G file:${primers}"
        options_3p = "-a file\$:${primers} -A file\$:${primers}"
    }

    if (params.cutadapt_trim_3p) {
        """
        cutadapt --cores $task.cpus \\
            --discard-untrimmed \\
            --revcomp \\
            $args \\
            $reads \\
            $trimmed \\
            $options_5p \\
            $options_3p \\
            --times=2 \\
            -Z \\
            --json=$report \\
            > ${prefix}.cutadapt.log

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            cutadapt: \$(cutadapt --version)
        END_VERSIONS

        """
    } else {
        """
        cutadapt \\
            --discard-untrimmed \\
            -Z \\
            --cores $task.cpus \\
            $args \\
            $trimmed \\
            $reads \\
            $options_5p \\
            --json=$report \\
            > ${prefix}.cutadapt.log
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            cutadapt: \$(cutadapt --version)
        END_VERSIONS
        """
    }
}
