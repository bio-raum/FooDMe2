process VSEARCH_UCHIME3_DENOVO {
    tag "${meta.sample_id}"

    label 'short_serial'

    conda 'bioconda::vsearch=2.27.0'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vsearch:2.27.0--h6a68c12_0' :
        'quay.io/biocontainers/vsearch:2.27.0--h6a68c12_0' }"

    input:
    tuple val(meta), path(fa)

    output:
    tuple val(meta), path(nonchimera), emit: fasta
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id

    nonchimera = prefix + '.uchime_denovo.fasta'
    derep_uc = prefix + '.uchime_denovo.uc'

    """
    vsearch --uchime3_denovo $fa \
    --threads ${task.cpus} \
    --sizein \
    --sizeout \
    --nonchimera $nonchimera $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vsearch: \$(vsearch --version 2>&1 | head -n 1 | sed 's/vsearch //g' | sed 's/,.*//g' | sed 's/^v//' | sed 's/_.*//')
    END_VERSIONS
    """
}
