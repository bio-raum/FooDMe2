/*
Include Modules
*/
include { UNZIP as UNZIP_MIDORI }           from './../modules/unzip'
include { GUNZIP as GUNZIP_TAXONOMY }       from './../modules/gunzip'
include { GUNZIP as GUNZIP_REFSEQ }         from './../modules/gunzip'
include { HELPER_FORMAT_MIDORI }            from './../modules/helper/format_midori'
include { BLAST_MAKEBLASTDB }               from './../modules/blast/makeblastdb'
include { UNTAR as UNTAR_TAXONOMY }         from './../modules/untar'
include { UNTAR as UNTAR_NCBI }             from './../modules/untar'
include { WGET as WGET_MIDORI }             from './../modules/wget'
include { HELPER_FORMAT_GENBANK_TAXIDS }    from './../modules/helper/format_genbank_taxids'
include { WGET as WGET_NCBI }               from './../modules/wget'
include { HELPER_INSTALL_GENBANK }          from './../modules/helper/install_genbank'

workflow BUILD_REFERENCES {

    main:

    databases   = params.references.databases.keySet()

    /*
    NCBI taxonomy files are needed to e.g. mask BLAST databases
    and to determine taxonomic consensus calls
    */
    taxdb   = channel.from(params.references.taxonomy.taxdb_url)
    taxdump = channel.from(params.references.taxonomy.taxdump_url)
    taxid   = channel.from(params.references.taxonomy.taxid_url)

    ch_ncbi_files = channel.from([])
    database_files = []
    midori_files = []
    ch_blast_files = channel.from([])
    ch_files = channel.from([])

    taxdb.mix(taxdump, taxid).map { f ->
        def meta = [:]
        def this_id = f.split("/").last().toString().replaceAll(/\.tar.*|\.gz/, "")
        meta.id = this_id
        tuple(meta, f)
    }.set { tax_files }

    ch_ncbi_files = ch_ncbi_files.mix(tax_files)

    if (params.build_references) {
        // For all genes of interest, recover supported tools and the corresponding database link
        databases.each { db ->
            // Genbank NT does not have an url, so we skip it here.
            if (params.references.databases[db].url) {
                if (params.references.databases[db].url.contains("MIDORI2")) {
                    midori_files << [ [ id: db, tool: 'blast' ],
                    params.references.databases[db].url
                ]
                } else {
                    database_files << [ [ id: db, tool: 'blast' ],
                        params.references.databases[db].url
                    ]
                }
            }
        }
    }

    ch_db_files = channel.fromList(database_files)

    ch_ncbi_files = ch_ncbi_files.mix(ch_db_files)

    /*
    Download data from NCBI
    */
    WGET_NCBI(
        ch_ncbi_files
    )

    WGET_NCBI.out.download.branch { m,_f ->
        taxid: m.id.contains("nucl_gb.accession2taxid")
        taxdump: m.id.contains("new_taxdump")
        taxdb: m.id.contains("taxdb")
        db: m.tool == "blast"
    }.set { ch_ncbi_by_type }

    ch_files = ch_files.mix(ch_ncbi_by_type.db)

    // We download Midori with wget since the service is not guaranteed to have a valid SSL cert
    WGET_MIDORI(
        channel.fromList(midori_files)
    )
    ch_files = ch_files.mix(WGET_MIDORI.out.download)    

    ch_files.branch { _m, r ->
        midori: r.toString().contains('MIDORI')
        ncbi_its: r.toString().contains('ITS_eukaryote')
        refseq: r.toString().contains('mitochondrion')
    }.set { ch_branched_files }

    /*
    Decompress and format taxonomy id mappings
    */
    HELPER_FORMAT_GENBANK_TAXIDS(
        ch_ncbi_by_type.taxid.map { _m,f ->
            def meta = [:]
            meta.id = f.getBaseName()
            tuple(meta, f)
        }
    )

    /*
    Decompress the taxonomy files
    */
    UNTAR_TAXONOMY(
        ch_ncbi_by_type.taxdump.mix(ch_ncbi_by_type.taxdb)
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
        HELPER_FORMAT_GENBANK_TAXIDS.out.tab.map { _m,t -> t }
    )
    ch_blast_files = ch_blast_files.mix(ch_refseq_with_taxids)

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

