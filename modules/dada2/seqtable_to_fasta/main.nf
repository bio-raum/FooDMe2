process DADA2_SEQTABLE_TO_FASTA {
    tag "$meta.sample_id"
    label 'short_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' :
        'quay.io/biocontainers/dada2-rs:0.5.0--hfa8f182_0' }"

    input:
    tuple val(meta), path(asvs)

    output:
    tuple val(meta), path('*_ASVs.fasta')  , emit: fasta
    path 'versions.yml'                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args ?: ''
    def outFASTA = "\"${meta.sample_id}_ASVs.fasta\""

    """
    dada2-rs seq-table-to-fasta *.ASVtable.nochim.json \
        --output $outFASTA

    # On error, generate empty json
    rc=$?
    if [ "$rc" -ne 0 ]; then
        touch $outFASTA
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dada2-rs: \$(dada2-rs -v 2>&1 | sed 's/^.*dada2-rs: //; s/ .*\$//')
    END_VERSIONS
    """
    }