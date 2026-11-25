process DADA2_DENOISING {
    tag "$meta.sample_id"
    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' :
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' }"

    input:
    tuple val(meta), path('filtered/*'), path(errormodel)

    output:
    tuple val(meta), path('*.dada.json')    , emit: denoised
    path 'versions.yml'                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args ?: ''
    def outJSON     = "\"${meta.sample_id}.dada.json\""
    def outJSONR1   = "\"${meta.sample_id}_1.dada.json\""
    def outJSONR1   = "\"${meta.sample_id}_2.dada.json\""

    if (meta.single_end) {
        """
        dada2-rs dada *.filt.fastq.gz --error-model *.error.json \
            --output $outJSON \
            --inherit-err-params \
            $args \
            --threads $task.cpus \
            --verbose

        # On error, generate empty json
        rc=$?
        if [ "$rc" -ne 0 ]; then
            touch $outJSON
        fi

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            dada2-rs: \$(dada2-rs -v 2>&1 | sed 's/^.*dada2-rs: //; s/ .*\$//')
        END_VERSIONS
        """
    } else {
        """
        dada2-rs dada *_1.filt.fastq.gz --error-model *_1.error.json \
            --output $outJSONR1 \
            --inherit-err-params \
            $args \
            --threads $task.cpus \
            --verbose

        # On error, generate empty json
        rc=$?
        if [ "$rc" -ne 0 ]; then
            touch $outJSONR1
        fi

        dada2-rs dada *_2.filt.fastq.gz --error-model *_2.error.json \
            --output $outJSONR2 \
            --inherit-err-params \
            $args \
            --threads $task.cpus \
            --verbose

        # On error, generate empty json
        rc=$?
        if [ "$rc" -ne 0 ]; then
            touch $outJSONR2
        fi

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            dada2-rs: \$(dada2-rs -v 2>&1 | sed 's/^.*dada2-rs: //; s/ .*\$//')
        END_VERSIONS
        """
    }
}