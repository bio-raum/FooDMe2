process BLAST_BLASTN {
    tag "$meta.sample_id"
    label 'medium_parallel'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/blast:2.14.1--pl5321h6f7f691_0' :
        'quay.io/biocontainers/blast:2.14.1--pl5321h6f7f691_0' }"

    input:
    tuple val(meta) , path(fasta)
    tuple val(meta2), path(db)
    path(taxdb)
    path(blast_mask)

    output:
    tuple val(meta), path('*.txt'), emit: txt
    path 'versions.yml'           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"

    """
    DB=`find -L ./ -name "*.ndb" | sed 's/\\.ndb\$//'`
    if [ -z "\$DB" ]; then
        DB=`find -L ./ -name "*.ndb" | sed 's/\\.ndb\$//'`
    fi
    echo Using \$DB

    export BLASTDB=$taxdb

    blastn \\
        -num_threads ${task.cpus} \\
        -db \$DB \\
        -query ${fasta} \\
        -taxidlist $blast_mask \\
        ${args} \\
        -out ${prefix}.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: \$(blastn -version 2>&1 | sed 's/^.*blastn: //; s/ .*\$//')
        db: ${meta2.id}:${meta2.version}
    END_VERSIONS
    """
}
