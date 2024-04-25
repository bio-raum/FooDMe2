process VSEARCH_DEREPFULL {
    tag "${meta.sample_id}"

    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vsearch:2.27.0--h6a68c12_0' :
        'quay.io/biocontainers/vsearch:2.27.0--h6a68c12_0' }"

    input:
    tuple val(meta), path(fa)

    output:
    tuple val(meta), path(derep), emit: fasta
    tuple val(meta), path(derep_uc), emit: uc
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"
    derep = prefix + '.derep.fasta'
    derep_uc = prefix + '.derep.uc'

    if (meta.sample_id != 'all') {
        args = args.concat(" --relabel ${meta.sample_id}_Derep")
    }
    """
    vsearch --derep_fulllength $fa \
    $args \
    --uc $derep_uc \
    --threads ${task.cpus} \
    --output $derep

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vsearch: \$(vsearch --version 2>&1 | head -n 1 | sed 's/vsearch //g' | sed 's/,.*//g' | sed 's/^v//' | sed 's/_.*//')
    END_VERSIONS
    """
}
