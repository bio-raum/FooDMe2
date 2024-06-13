process HELPER_CREATE_BLAST_MASK {
    tag 'Masking'
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container 'gregdenay/taxidtools:devel'

    input:
    path(taxlist)   // List of tax ids in blast database
    val(taxid)      // the root tax id for the mask
    path(taxonomy)  // the taxonomy.json for taxidtools

    output:
    path('*.mask')      , emit: mask
    path 'versions.yml' , emit: versions

    script:
    blast_mask = 'blast.mask'

    """
    make_blast_mask.py \\
    --taxlist $taxlist \\
    --taxid $taxid \\
    --taxonomy $taxonomy \\
    --output $blast_mask

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
