process VSEARCH_FASTQFILTER_READS {
    tag "${meta.sample_id}"

    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vsearch:2.27.0--h6a68c12_0' :
        'quay.io/biocontainers/vsearch:2.27.0--h6a68c12_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*filtered.fastq'), emit: reads
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''

    r1 = reads.first()

    suffix = '.filtered.fastq'

    if (meta.single_end) {
        r1_trim = r1.getBaseName() + suffix
        """
        vsearch --fastq_filter ${r1} \
        --threads ${task.cpus} \
        --sample ${meta.sample_id} \
        -fastqout ${meta.sample_id}${suffix} $args

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            vsearch: \$(vsearch --version 2>&1 | head -n 1 | sed 's/vsearch //g' | sed 's/,.*//g' | sed 's/^v//' | sed 's/_.*//')
        END_VERSIONS
        """
    } else {
        r2 = reads[1]
        r1_filt = r1.getBaseName() + suffix
        r2_filt = r2.getBaseName() + suffix
        """
        vsearch --fastq_filter ${r1} --reverse ${r2} \
        --threads ${task.cpus} \
        --sample ${meta.sample_id} \
        --fastqout $r1_filt \
        --fastqout_rev $r2_filt $args

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            vsearch: \$(vsearch --version 2>&1 | head -n 1 | sed 's/vsearch //g' | sed 's/,.*//g' | sed 's/^v//' | sed 's/_.*//')
        END_VERSIONS
        """
    }
}
