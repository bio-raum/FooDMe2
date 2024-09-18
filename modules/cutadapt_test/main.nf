process CUTADAPT {
    tag "$meta.sample_id"
    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cutadapt:4.9--py39hff71179_1' :
        'quay.io/biocontainers/cutadapt:4.9--py39hff71179_1' }"

    input:
    tuple val(meta), path(reads)
    path(primers)
    path(primers_rc)

    output:
    tuple val(meta), path('*.trim.fastq.gz')  , emit: reads
    tuple val(meta), path('*.cutadapt*.json') , emit: report
    tuple val(meta), path('*.log')          , emit: log
    path 'versions.yml'                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"
    def trimmed  = meta.single_end ? "-o ${prefix}.trim.fastq.gz" : "-o ${prefix}_1.trim.fastq.gz -p ${prefix}_2.trim.fastq.gz"
    def options_5p = ''
    def options_3p = ''
    if (meta.single_end) {
        options_5p = "-g ^file:${primers}"
        options_3p = "-a file\$:${primers_rc}"
    } else {
        options_5p = "-g file:${primers} -G file:${primers}"
        options_3p = "-a file\$:${primers_rc} -A file\$:${primers_rc}"
    }

    if (params.cutadapt_trim_3p) {
        """
        cutadapt --interleaved \\
            --discard-untrimmed \\
            --cores $task.cpus \\
            $args \\
            $reads \\
            $options_5p \\
            --json=${prefix}_forward.json \\
        | cutadapt --interleaved \\
            --discard-untrimmed \\
            $args \\
            --cores $task.cpus \\
            $trimmed \\
            $options_3p \\
            --json=${prefix}_reverse.json \\
            -Z - \\
            > ${prefix}.cutadapt.log

        cutadapt_sum_json.py --sample ${meta.sample_id} \\
        --forward ${prefix}_forward.json \\
        --reverse ${prefix}_reverse.json \\
        --output ${meta.sample_id}.cutadapt_mqc.json
        
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
            --json=${meta.sample_id}.cutadapt.json \\
            > ${prefix}.cutadapt.log
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            cutadapt: \$(cutadapt --version)
        END_VERSIONS
        """
    }
}
