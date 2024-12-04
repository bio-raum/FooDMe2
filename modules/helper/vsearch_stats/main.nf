process HELPER_VSEARCH_STATS {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/aminoextract:0.3.1--pyhdfd78af_0' :
        'quay.io/biocontainers/aminoextract:0.3.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fwd), path(rev), path(merged), path(filtered), path(nonchimera, stageAs: 'nonchim*/*' ) // Trimmed fastq, merged fastq, filtered fasta,non-chimeric fasta

    output:
    tuple val(meta), path('*.vsearch_stats.json'), emit: json
    path 'versions.yml'                          , emit: versions

    script:
    def prefix = task.ext.prefix ?: merged.getSimpleName()
    def sample_id = meta.sample_id

    """
    vsearch_stats.py --sample_id $sample_id --fwd $fwd --merged $merged --filtered $filtered --nonchimera $nonchimera --output ${prefix}.vsearch_stats.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
