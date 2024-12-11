process HELPER_SAMPLE_REPORT {
    tag "${meta.sample_id}"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biokit:0.5.0--pyh5e36f6f_0' :
        'quay.io/biocontainers/biokit:0.5.0--pyh5e36f6f_0' }"

    input:
    tuple val(meta), val(composition), val(cutadapt), val(blast), val(consensus), val(fastp)
    path(clustering)
    path(versions)                    // versions yaml

    output:
    tuple val(meta), path('*.report.json') , emit: json

    script:

    def prefix = task.ext.prefix ?: fastp.getSimpleName()  // Will crash if fastp is null!
    def run_name = task.ext.prefix ?: params.run_name
    def fastp_args = fastp ? "--fastp $fastp" : ""
    def consensus_args = consensus ? "--consensus $consensus" : ""
    def blast_args = blast ? "--blast $blast" : ""
    def cutadapt_args = cutadapt ? "--cutadapt $cutadapt" : ""
    def compo_args = composition ? "--compo $composition" : ""

    """
    sample_report.py --sample_id ${meta.sample_id} \
        --run_name ${run_name} \
        $compo_args \
        $cutadapt_args \
        --clustering $clustering \
        $blast_args \
        $consensus_args \
        --versions $versions \
        $fastp_args \
        --output ${prefix}.report.json
    """
}
