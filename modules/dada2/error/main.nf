process DADA2_ERROR {
    tag "${meta.sample_id} ($binning)"
    label 'medium_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' :
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' }"

    input:
    tuple val(meta), path(reads), val(binning)

    output:
    tuple val(meta), path('*.error.json')   , emit: errormodel
    path 'versions.yml'                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args ?: ""
    def outJSON     = "\"${meta.sample_id}.error.json\""
    def outJSONR1   = "\"${meta.sample_id}_1.error.json\""
    def outJSONR1   = "\"${meta.sample_id}_2.error.json\""

    def seed = task.ext.seed ?: '100'

    // if we have determined binning, use that - else use the default model or the Pacbio model, if data is pacbio
    def is_pacbio = params.pacbio.toString().toBoolean()
    def has_binning = binning != null && !(binning in [false, "false", "FALSE", ""])

    // Just in case the binning schema arrives as a List
    def bin_str = (binning instanceof Collection) ? binning.join(',') : binning.toString()

    def error_function = is_pacbio
        ? "pacbio"
        : (has_binning ? "binned-qual --binned-quals ${bin_str}" : "loess")
    
    if (meta.single_end) {
        """
        dada2-rs learn-errors *.filt.fastq.gz \
            --output $outJSON \
            --seed $seed \
            $args \
            --errfun $error_function \
            --threads $task.cpus

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
        # Read 1
        dada2-rs learn-errors *_1.filt.fastq.gz \
            --output $outJSONR1 \
            --seed $seed \
            $args \
            --errfun $error_function \
            --threads $task.cpus

        # On error, generate empty json
        rc=$?
        if [ "$rc" -ne 0 ]; then
            touch $outJSONR1
        fi

        # Read 2
        dada2-rs learn-errors *_2.filt.fastq.gz \
            --output $outJSONR2 \
            --seed $seed \
            $args \
            --errfun $error_function \
            --threads $task.cpus

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
