process HELPER_SAMPLE_REPORT {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biokit:0.5.0--pyh5e36f6f_0' :
        'quay.io/biocontainers/biokit:0.5.0--pyh5e36f6f_0' }"

    input:
    tuple val(meta), path(composition), path(cutadapt), path(blast), path(consensus)
    path(clustering)
    path(versions)                    // versions yaml

    output:
    tuple val(meta), path('*.report.json') , emit: json

    script:
    def prefix = task.ext.prefix ?: consensus.getSimpleName()
    def run_name = task.ext.prefix ?: params.run_name

    """
    sample_report.py --sample_id ${meta.sample_id} \
        --run_name ${run_name} \
        --compo $composition \
        --cutadapt $cutadapt \
        --clustering $clustering \
        --blast $blast \
        --consensus $consensus \
        --versions $versions \
        --output ${prefix}.report.json
    """
}
