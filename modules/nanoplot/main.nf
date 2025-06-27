process NANOPLOT {
    tag "$meta.sample_id"
    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanoplot:1.44.1--pyhdfd78af_0' :
        'quay.io/biocontainers/nanoplot:1.44.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(ontfile)

    output:
    tuple val(meta), path("output_*")              , emit: results
    tuple val(meta), path('*.txt')                 , emit: txt
    tuple val(meta), path('*.tsv.gz')              , emit: tsv
    path  'versions.yml'                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def suffix = task.ext.suffix ? task.ext.suffix : "nanoplot"
    def prefix = task.ext.prefix ?: "${meta.sample_id}"
    def input_file = ("$ontfile".endsWith('.fastq.gz')) ? "--fastq ${ontfile}" :
        ("$ontfile".endsWith('.txt')) ? "--summary ${ontfile}" : ''
    """
    NanoPlot \\
        -o output_${suffix} \\
        $args \\
        -t $task.cpus \\
        $input_file

    mv output_${suffix}/NanoStats.txt ${prefix}.nanoplot.${suffix}.txt
    mv output_${suffix}/NanoPlot-data.tsv.gz ${prefix}.nanoplot.${suffix}.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoplot: \$(echo \$(NanoPlot --version 2>&1) | sed 's/^.*NanoPlot //; s/ .*\$//')
    END_VERSIONS
    """
}
