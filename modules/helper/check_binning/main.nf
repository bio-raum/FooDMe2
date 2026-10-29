process HELPER_CHECK_BINNING {
    tag "$meta.sample_id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.27.1--pyhdfd78af_0' :
        'quay.io/biocontainers/multiqc:1.27.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("status.txt"), emit: binned_status

    script:
    def fastq = reads instanceof List ? reads[0] : reads
    """
    check_illumina_binning.py ${fastq} status.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """

}
