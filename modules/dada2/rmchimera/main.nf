process DADA2_RMCHIMERA {
    tag "$meta.sample_id"
    label 'medium_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' :
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' }"

    input:
    tuple val(meta), path(seqtab)

    output:
    tuple val(meta), path('*.ASVtable.nochim.json') , emit: asvs
    path 'versions.yml'                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: : ''
    def outJSON = "\"${meta.sample_id}.ASVtable.nochim.json\""

    if (params.remove_chimera) {
        """
        dada2-rs remove-bimera-denovo *.ASVtable.json $args \
            --output $outJSON
            --threads $task.cpus \
            --verbose
        
        # On error, generate empty json
        rc=$?
        if [ "$rc" -ne 0 ]; then
            touch $outJSON
        fi

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            dada2-rs: \$(dada2-rs -v 2>&1 | sed 's/^.*dada2-rs: //; s/ .*\$//')
        END_VERSIONS
        """
    } else {
        """
        # skipping filtering, just copy file
        cp *.ASVtable.json $outJSON
        """
    }
}
