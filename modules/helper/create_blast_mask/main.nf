process HELPER_CREATE_BLAST_MASK {
    tag "Masking"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "gregdenay/taxidtools:devel"

    input:
    tuple path(nodes),path(rankedlineage)
    val(taxid)

    output:
    path('*.mask')      , emit: mask
    path 'versions.yml' , emit: versions

    script:
    json = "blast.mask"

    """
    make_blast_mask.py 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
