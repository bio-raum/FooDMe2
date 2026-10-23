process HELPER_VSEARCH_UPDATE_SIZE {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container 'https://depot.galaxyproject.org/singularity/aminoextract:0.3.1--pyhdfd78af_0'
    //container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //    'https://depot.galaxyproject.org/singularity/aminoextract:0.3.1--pyhdfd78af_0' :
    //    'quay.io/biocontainers/aminoextract:0.3.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta), val(sizes)

    output:
    tuple val(meta), path('*.precluster_with_counts.fasta'), emit: fasta
    path 'versions.yml'                          , emit: versions

    script:
    def prefix = task.ext.prefix ?: meta.sample_id
    def abundances = prefix + ".precluster_with_counts.fasta"

    """
    vsearch_update_otu_sizes.py --table $sizes --input $fasta --output $abundances

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
