process DADA2_FILTNTRIM {
    tag "$meta.sample_id"
    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' :
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.filt.fastq.gz')    , emit: filtered_reads
    tuple val(meta), path('*.filter_stats.json'), emit: json
    path 'versions.yml'                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args ?: ''
    def in_and_out  = meta.single_end ? "--fwd \"${reads}\" --filt \"${meta.sample_id}.filt.fastq.gz\"" : "--fwd \"${reads[0]}\" --filt \"${meta.sample_id}_1.filt.fastq.gz\" --rev \"${reads[1]}\" --filt-rev \"${meta.sample_id}_2.filt.fastq.gz\""
    def outJSON     = "\"${meta.sample_id}.filter_stats.json\""
    def outfiles    = meta.single_end ? "\"${meta.sample_id}.filt.fastq.gz\"" : "\"${meta.sample_id}_1.filt.fastq.gz\" \"${meta.sample_id}_2.filt.fastq.gz\""

    """
    dada2-rs filter-and-trim $in_and_out \
        --compress --output $outJSON \  
        $args \
        --threads $task.cpus \
        --verbose

    # If no reads passed the filter, write  empty GZ file(s)
    for file in $outfiles; do
        if [ ! -s "$file" ]; then
        : | gzip -c > "$file"
        fi
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dada2-rs: \$(dada2-rs -v 2>&1 | sed 's/^.*dada2-rs: //; s/ .*\$//')
    END_VERSIONS
    """
}
