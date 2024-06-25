include { UNZIP as UNZIP_REFERENCES }       from './../modules/unzip'
include { GUNZIP as GUNZIP_TAXONOMY }       from './../modules/gunzip'
include { GUNZIP as GUNZIP_REFSEQ }         from './../modules/gunzip'
include { HELPER_FORMAT_MIDORI }            from './../modules/helper/format_midori'
include { BLAST_MAKEBLASTDB }               from './../modules/blast/makeblastdb'
include { UNTAR as UNTAR_TAXONOMY }         from './../modules/untar'
include { UNTAR as UNTAR_UNITE }            from './../modules/untar'
include { HELPER_FORMAT_GENBANK_TAXIDS }    from './../modules/helper/format_genbank_taxids'
include { HELPER_FORMAT_UNITE }             from './../modules/helper/format_unite'
include { HELPER_INSTALL_GENBANK }          from './../modules/helper/install_genbank'

genes   = params.references.genes.keySet()

/*
NCBI taxonomy files are needed to e.g. mask BLAST databases
and to determine taxonomic consensus calls
*/
taxdb   = Channel.fromPath(params.references.taxonomy.taxdb_url)
taxdump = Channel.fromPath(params.references.taxonomy.taxdump_url)
taxid   = Channel.fromPath(params.references.taxonomy.taxid_url)

taxdb.mix(taxdump).map { f ->
    def meta = [:]
    meta.id = f.getSimpleName()
    tuple(meta, f)
}.set { tax_files }

database_files = []

if (params.build_references) {
    // For all genes of interest, recover supported tools and the corresponding database link
    genes.each { gene ->
        // Genbank NT does not have an url, so we skip it here. 
        if (params.references.genes[gene].url) {
            database_files << [ [ id: gene, tool: 'blast' ] ,
                file(params.references.genes[gene].url, checkIfExists: true)
            ]
        }
    }
}

ch_files = Channel.fromList(database_files)
ch_blast_files = Channel.from([])

workflow BUILD_REFERENCES {
    main:

    /*
    This is a bit crude. Different DBs happen to have different suffixes, so we can use
    that to branch them for unpacking AND processing. Be careful here if new DBs are added
    and, for example, should not go to the MIDORI formatter...
    */
    ch_files.branch { m, r ->
        zipped: r.toString().contains('.zip')
        tarzipped: r.toString().contains('tar.gz') || r.toString().contains('.tgz')
        gzipped: r.toString().contains('.gz') 
        uncompressed: !ir.toString().contains('.zip') && !r.toString().contains('.gz')
    }.set { ch_branched_files }

    /*
    Decompress and format taxonomy id mappings
    */
    HELPER_FORMAT_GENBANK_TAXIDS(
        taxid.map { f -> 
            def meta = [:]
            meta.id = f.getBaseName()
            tuple(meta,f)
        }
    )

    /*
    Decompress the taxonomy files
    */
    UNTAR_TAXONOMY(
        tax_files
    )

    /*
    Decompress Gzipped database (RefSeq)
    */
    GUNZIP_REFSEQ(
        ch_branched_files.gzipped
    )

    ch_refseq_with_taxids = GUNZIP_REFSEQ.out.gunzip.combine(
        HELPER_FORMAT_GENBANK_TAXIDS.out.tab.map { m,t -> t }
    )
    ch_blast_files = ch_blast_files.mix(ch_refseq_with_taxids)

    /*
    Decompress the Unite database and re-format
    */
    UNTAR_UNITE(
        ch_branched_files.tarzipped
    )
    HELPER_FORMAT_UNITE(
        UNTAR_UNITE.out.fasta
    )
    ch_unite_with_taxids = HELPER_FORMAT_UNITE.out.clean.combine(
        HELPER_FORMAT_GENBANK_TAXIDS.out.tab.map { m,t -> t }
    )
    ch_blast_files = ch_blast_files.mix(ch_unite_with_taxids)

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
    ch_blast_files = ch_blast_files.mix(HELPER_FORMAT_MIDORI.out.midori)

    /*
    Create the Blast database with taxonomy
    */
    BLAST_MAKEBLASTDB(
        ch_blast_files
    )

    /*
    The full NT databases - this is too complex
    to just stage via Nextflow so we use a more sophisticated
    download script -  and we make it skippable in case users
    do not need it. 
    */
    if (!params.skip_genbank) {
        HELPER_INSTALL_GENBANK()
    }
}
