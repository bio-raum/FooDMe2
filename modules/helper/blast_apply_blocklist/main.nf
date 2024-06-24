process HELPER_BLAST_APPLY_BLOCKLIST {
    tag 'Blocklist'
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container 'gregdenay/taxidtools:3.1.0'

    input:
    path(taxlist)       // The basic blast mask
    path(blocklist)     // The list of taxids to additionally mask

    output:
    path('*.blocked.mask')      , emit: mask
    path 'versions.yml'         , emit: versions

    script:
    blast_mask = 'blast.blocked.mask'

    """
    apply_blocklist.py \\
    --taxids $taxlist \\
    --blocklist $blocklist \\
    --output $blast_mask

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
