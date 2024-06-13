process DADA2_ILLUMINA {
    tag "${meta.sample_id}"

    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioconductor-dada2:1.30.0--r43hf17093f_0' :
        'quay.io/biocontainers/bioconductor-dada2:1.30.0--r43hf17093f_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*ASVs.fasta')    , emit: otus
    tuple val(meta), path('*denoising.tsv') , emit: tsv
    tuple val(meta), path('*.dada2.log')    , emit: log
    tuple val(meta), path('*.pdf')          , emit: errors
    path('versions.yml')                    , emit: versions

    script:

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id

    r1 = reads[0]
    r2 = reads[1]

    // args = [ maxee, minlength, maxlength, max_mismatch, chimera  ] see conf/modules.config

    """
    dada2_illumina.R \\
    $prefix \\
    $r1 \\
    $r2 \\
    ${task.cpus} \\
    $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dada2: 1.30
    END_VERSIONS

    """
}
