/*
Include Modules
*/
include { UNZIP as UNZIP_MIDORI }           from './../modules/unzip'
include { GUNZIP as GUNZIP_TAXONOMY }       from './../modules/gunzip'
include { GUNZIP as GUNZIP_REFSEQ }         from './../modules/gunzip'
include { HELPER_FORMAT_MIDORI }            from './../modules/helper/format_midori'
include { BLAST_MAKEBLASTDB }               from './../modules/blast/makeblastdb'
include { UNTAR as UNTAR_TAXONOMY }         from './../modules/untar'
include { UNTAR as UNTAR_UNITE }            from './../modules/untar'
include { UNTAR as UNTAR_NCBI }             from './../modules/untar'
include { HELPER_FORMAT_GENBANK_TAXIDS }    from './../modules/helper/format_genbank_taxids'
include { HELPER_FORMAT_UNITE }             from './../modules/helper/format_unite'
include { HELPER_INSTALL_GENBANK }          from './../modules/helper/install_genbank'

workflow BUILD_REFERENCES {

    main:

    databases   = params.references.databases.keySet()

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
        databases.each { db ->
            // Genbank NT does not have an url, so we skip it here.
            if (params.references.databases[db].url) {
                database_files << [ [ id: db, tool: 'blast' ] ,
                    file(params.references.databases[db].url, checkIfExists: true)
                ]
            }
        }
    }

    ch_files = Channel.fromList(database_files)
    ch_blast_files = Channel.from([])

    ch_files.branch { m, r ->
        midori: r.toString().contains('MIDORI')
        ncbi_its: r.toString().contains('ITS_eukaryote')
        refseq: r.toString().contains('mitochondrion')
        unite: m.id == 'unite'
    }.set { ch_branched_files }

    /*
    Decompress and format taxonomy id mappings
    */
    HELPER_FORMAT_GENBANK_TAXIDS(
        taxid.map { f ->
            def meta = [:]
            meta.id = f.getBaseName()
            tuple(meta, f)
        }
    )

    /*
    Decompress the taxonomy files
    */
    UNTAR_TAXONOMY(
        tax_files
    )

    /*
    NCBI ITS database
    */
    UNTAR_NCBI(
        ch_branched_files.ncbi_its
    )

    /*
    Decompress Gzipped database (RefSeq)
    */
    GUNZIP_REFSEQ(
        ch_branched_files.refseq
    )

    ch_refseq_with_taxids = GUNZIP_REFSEQ.out.gunzip.combine(
        HELPER_FORMAT_GENBANK_TAXIDS.out.tab.map { m, t -> t }
    )
    ch_blast_files = ch_blast_files.mix(ch_refseq_with_taxids)

    /*
    Decompress the Unite database and re-format
    */
    UNTAR_UNITE(
        ch_branched_files.unite
    )
    HELPER_FORMAT_UNITE(
        UNTAR_UNITE.out.fasta
    )
    ch_unite_with_taxids = HELPER_FORMAT_UNITE.out.clean.combine(
        HELPER_FORMAT_GENBANK_TAXIDS.out.tab.map { m, t -> t }
    )
    ch_blast_files = ch_blast_files.mix(ch_unite_with_taxids)

    /*
    MIDORI Blast databases are zipped, so we unzip them
    */
    UNZIP_MIDORI(
        ch_branched_files.midori
    )

    /*
    Clean FASTA header in Midori files
    */
    HELPER_FORMAT_MIDORI(
        UNZIP_MIDORI.out.unzip
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

    if (params.build_references) {
        workflow.onComplete = {
            log.info 'Installation complete - deleting staged files. '
            workDir.resolve("stage-${workflow.sessionId}").deleteDir()
        }
    }
}

