process DADA2_MERGE_PAIRS {
    tag "$meta.sample_id"
    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' :
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' }"

    input:
    tuple val(meta), path('filtered/*'), path(denoised)

    output:
    tuple val(meta), path('*.merged.json')  , emit: mergers
    path 'versions.yml'                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args ?: ''
    def outJSON = "\"${meta.sample_id}.merged.json\""

    if (meta.single_end) {
        """
        # Nothing to merge, copying the dada json into a merged json for the seqtable module
        cp *.dada.json $outJSON
        """
    } else {
        """
        dada2-rs merge-pairs $args \
            --fwd-dada *_1.dada.json \
            --rev-dada *_2.dada.json \
            --fwd-fastq *_1.filt.fastq.gz \
            --rev-fastq *_2.filt.fastq.gz \
            --output $outJSON $args\
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
    }