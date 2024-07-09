process PRIMER_DISAMBIGUATE {
    tag "$fa"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl-bioperl:1.7.8--hdfd78af_1' :
        'quay.io/biocontainers/perl-bioperl:1.7.8--hdfd78af_1' }"

    input:
    path(fa)

    output:
    path(disambiguated), emit: fasta
    path 'versions.yml'    , emit: versions

    script:
    def args = task.ext.args ?: ''
    disambiguated = fa.getSimpleName() + ".disambiguated.fasta"

    """
    primer_disambiguate.pl --fasta $fa --outfile $disambiguated $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl --version  | head -n2 | tail -n1 | sed -e "s/.*(//" -e "s/).*//")
    END_VERSIONS
    """
}
