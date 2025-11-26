process BLAST_BLASTN {
    tag "$meta.sample_id"
    label 'medium_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/blast:2.17.0--h66d330f_0' :
        'quay.io/biocontainers/blast:2.17.0--h66d330f_0' }"

    input:
    tuple val(meta) , path(fasta)
    tuple val(meta2), path(db)
    path(taxdb)
    path(blast_mask)

    output:
    tuple val(meta), path('*.txt'), emit: txt
    tuple val(meta), path('*.xml'), emit: xml
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

    # BLAST search and output as BLAST archive (ASN1)
    blastn \\
        -num_threads ${task.cpus} \\
        -db \$DB \\
        -query ${fasta} \\
        -taxidlist $blast_mask \\
        ${args} \\
        -outfmt 11 \\
        -out ${prefix}.asn

    # Use BLAST formatter to produce XML2 and TSV
    # XML can be used to retrieve search parameters like lambda, kappa, database size, etc
    if [ -s ${prefix}.asn ]; then
        blast_formatter -archive ${prefix}.asn -outfmt 16 -out ${prefix}.xml
        blast_formatter -archive ${prefix}.asn -outfmt '6 qseqid sseqid evalue pident bitscore sacc staxid length mismatch gaps sscinames' -out ${prefix}.txt
    else
        touch ${prefix}.xml
        touch ${prefix}.txt
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: \$(blastn -version 2>&1 | sed 's/^.*blastn: //; s/ .*\$//')
        db: ${meta2.id}:${meta2.version}
    END_VERSIONS
    """
}
