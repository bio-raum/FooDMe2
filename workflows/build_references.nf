include { UNZIP as UNZIP_REFERENCES }   from './../modules/unzip'
include { GUNZIP as GUNZIP_TAXONOMY }   from './../modules/gunzip'
include { HELPER_FORMAT_MIDORI }        from './../modules/helper/format_midori'
include { BLAST_MAKEBLASTDB }           from './../modules/blast/makeblastdb'

genes   = params.references.genes.keySet()

taxdb   = Channel.fromPath(params.references.taxonomy.taxdb)
taxdump = Channel.fromPath(params.references.taxonomy.taxdump)

taxdb.mix(taxdump).map { f ->
    def meta = [:]
    meta.sample = f.getSimpleName()
    tuple(meta, f)
}.set { tax_files }

midori_files = []

// For all genes of interest, recover supported tools and the corresponding database link
genes.each { gene ->
    midori_files << [ [ id: gene, tool: 'blast' ] ,
        file(params.references.genes[gene].blast_url, checkIfExists: true)
    ]
}

ch_files = Channel.fromList(midori_files)

workflow BUILD_REFERENCES {
    main:

    ch_files.branch { m, r ->
        zipped: r.toString().contains('.zip')
        gzipped: r.toString().contains('.gz')
        uncompressed: !ir.toString().contains('.zip') && !r.toString().contains('.gz')
    }.set { ch_branched_files }

    /*
    Decompress the taxonomy files
    */
    GUNZIP_TAXONOMY(
        tax_files
    )
    /*
    MIDORI Blast databases are zipped, so we unzip them
    */
    UNZIP_REFERENCES(
        ch_branched_files.zipped
    )

    ch_fasta_files = ch_branched_files.uncompressed.mix(UNZIP_REFERENCES.out.unzip)

    /*
    Clean FASTA header in Midori files
    */
    HELPER_FORMAT_MIDORI(
        ch_fasta_files
    )

    /*
    Create the Blast database with taxonomy
    */
    BLAST_MAKEBLASTDB(
        HELPER_FORMAT_MIDORI.out.midori
    )
}
