process HELPER_VSEARCH_STATS {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container 'https://depot.galaxyproject.org/singularity/aminoextract:0.3.1--pyhdfd78af_0'
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/aminoextract:0.3.1--pyhdfd78af_0' :
    //    'quay.io/biocontainers/aminoextract:0.3.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(reads), val(merged), val(filtered), path(nonchimera, stageAs: 'nonchim*/*' ) // Trimmed fastq, merged fastq, filtered fasta,non-chimeric fasta

    output:
    tuple val(meta), path('*.vsearch_stats.json'), emit: json
    path 'versions.yml'                          , emit: versions

    script:
    def prefix = task.ext.prefix ?: meta.sample_id
    def sample_id = meta.sample_id 
    def in_opt = meta.single_end ? "--fwd $reads" : "--fwd ${reads[0]}"
    def merge_opt = merged ? "--merged $merged" : ""
    def filter_opt = filtered ? "--filtered $filtered" : ""

    """
    vsearch_stats.py --sample_id $sample_id $in_opt $merge_opt $filter_opt --nonchimera $nonchimera --output ${prefix}.vsearch_stats.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
