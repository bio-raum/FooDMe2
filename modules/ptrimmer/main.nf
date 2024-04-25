process PTRIMMER {
    label 'short_serial'

    tag "${meta.sample_id}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ptrimmer:1.3.3--h50ea8bc_5' :
        'quay.io/biocontainers/ptrimmer:1.3.3--h50ea8bc_5' }"

    input:
    tuple val(meta), path(reads)
    path(amplicon_txt)

    output:
    tuple val(meta), path('*ptrimmed.fastq.gz'), emit: reads
    path('versions.yml'), emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: meta.sample_id

    r1 = reads[0]
    r1_trimmed = prefix + '_1.ptrimmed.fastq'
    r1_trimmed_gz = r1_trimmed + '.gz'

    if (meta.single_end) {
        """
        ptrimmer $args -t single -a $amplicon_txt -f $r1 -d $r1_trimmed
        gzip $r1_trimmed

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Ptrimmer: \$(ptrimmer --help 2>&1 | grep Version | sed -e "s/Version: //g")
        END_VERSIONS
        """
    } else {
        r2 = reads[1]
        r2_trimmed = prefix + '_2.ptrimmed.fastq'
        r2_trimmed_gz = r2_trimmed + '.gz'

        """
        ptrimmer $args -t pair -a $amplicon_txt -f $r1 -d $r1_trimmed -r $r2 -e $r2_trimmed
        gzip $r1_trimmed
        gzip $r2_trimmed

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Ptrimmer: \$(ptrimmer --help 2>&1 | grep Version | sed -e "s/Version: //g")
        END_VERSIONS
        """
    }
}
