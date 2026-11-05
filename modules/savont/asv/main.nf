process SAVONT_ASV {

    tag "$meta.sample_id"
    label 'medium_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/savont:0.8.0--hec9b1f2_2' :
        'quay.io/biocontainers/savont:0.8.0--hec9b1f2_2' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.fasta'), emit: fasta
    tuple val(meta), path('*.tsv')  , emit: tsv
    tuple val(meta), path('*.log')  , emit: log
    path  'versions.yml'            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"
 
    """
    if savont asv $args -t ${task.cpus} $reads ; then
        sed -E 's/>final_asv_([0-9]+)_depth_([0-9]+).*/>asv_\\1;size=\\2/' savont-out/final_asvs.fasta > ${prefix}_final_asvs.fasta
        cp savont-out/feature-table.tsv ${prefix}_feature_table.tsv
        cp savont-out/*.log ${prefix}_savont.log
    else
        touch ${prefix}_feature_table.tsv
        touch ${prefix}_savont.log
        touch ${prefix}_final_asvs.fasta
    fi
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        savont: \$( fastqc --version | sed '/FastQC v/!d; s/.*v//' )
    END_VERSIONS
    """
}
