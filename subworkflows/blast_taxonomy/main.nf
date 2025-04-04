include { BLAST_BLASTN }                    from './../../modules/blast/blastn'
include { HELPER_BLAST_FILTER_BITSCORE }    from './../../modules/helper/blast_filter_bitscore'
include { HELPER_FILTER_TAXONOMY }          from './../../modules/helper/filter_taxonomy'
include { BLAST_TAXONOMY_FROM_DB }          from './../../modules/helper/blast_taxonomy_from_db'
include { HELPER_FIND_CONSENSUS }           from './../../modules/helper/find_consensus'
include { HELPER_CREATE_BLAST_MASK }        from './../../modules/helper/create_blast_mask'
include { HELPER_BLAST_APPLY_BLOCKLIST }    from './../../modules/helper/blast_apply_blocklist'
include { HELPER_BLAST_STATS }              from './../../modules/helper/blast_stats'
include { HELPER_SAMPLE_COMPO }             from './../../modules/helper/sample_compo'
include { HELPER_ASSIGNEMENT_MULTIQC }      from './../../modules/helper/assignement_multiqc'

workflow BLAST_TAXONOMY {
    take:
    otus        // [ meta, fasta ]
    blast_db    // [ meta, folder ]
    taxdump     // [ nodes, rankedlineage, merged ]
    taxdb       // [ taxdb folder ]
    block_list  // [ blocklist ]

    main:

    ch_versions = Channel.from([])
    ch_qc_files = Channel.from([])
    ch_tax_json = Channel.from([])

    /*
    Take the NCBI taxonomy and create a
    JSON-formatted dictionary for the taxonomic
    subgroup of interest.
    */
    HELPER_FILTER_TAXONOMY(
        taxdump,
        params.taxid_filter
    )
    ch_tax_json = ch_tax_json.mix(HELPER_FILTER_TAXONOMY.out.json)

    /*
    Get all tax ids from this Blast database
    */
    BLAST_TAXONOMY_FROM_DB(
        blast_db
    )

    /*
    Create a list of allowed taxonomy ids based on the
    intersection between the pre-filtered taxonomy database
    and the taxonomy IDs included in the Blast database
    */
    HELPER_CREATE_BLAST_MASK(
        BLAST_TAXONOMY_FROM_DB.out.list,
        params.taxid_filter,
        ch_tax_json
    )
    blast_mask = HELPER_CREATE_BLAST_MASK.out.mask

    /*
    Further filter the blast mask to remove unwanted taxids
    based on a (user-provided) blocklist.
    */
    HELPER_BLAST_APPLY_BLOCKLIST(
        blast_mask,
        block_list.collect()
    )
    blast_mask_blocked = HELPER_BLAST_APPLY_BLOCKLIST.out.mask

    /*
    Take the OTUs and blast them against the selected
    Blast database, using a taxonomy filter to limit
    the search space
    */
    BLAST_BLASTN(
        otus,
        blast_db.collect(),
        taxdb,
        blast_mask_blocked.collect()
    )
    ch_versions     = ch_versions.mix(BLAST_BLASTN.out.versions)

    /*
    Filter the Blast hits to remove low-scoring hits
    */
    HELPER_BLAST_FILTER_BITSCORE(
        BLAST_BLASTN.out.txt
    )

    ch_blast_and_otus = HELPER_BLAST_FILTER_BITSCORE.out.json.join(otus)

    /*
    Find taxonomic consensus for each OTU
    */
    HELPER_FIND_CONSENSUS(
        ch_blast_and_otus,
        params.blast_min_consensus,
        ch_tax_json.collect()
    )

    /*
    BLAST search stats
    */
    HELPER_BLAST_STATS(
        HELPER_BLAST_FILTER_BITSCORE.out.json
    )
    ch_versions = ch_versions.mix(HELPER_BLAST_STATS.out.versions)

    // Assignement MULTIQC
    HELPER_FIND_CONSENSUS.out.json.map { meta, json ->
        json
    }.set { ch_json_nometa }
    
    HELPER_ASSIGNEMENT_MULTIQC(
        ch_json_nometa.collect()
    )
    ch_qc_files = ch_qc_files.mix(HELPER_ASSIGNEMENT_MULTIQC.out.json)

    /*
    Sample composition
    */
    HELPER_SAMPLE_COMPO(
        HELPER_FIND_CONSENSUS.out.json
    )
    ch_versions = ch_versions.mix(HELPER_BLAST_STATS.out.versions)

    emit:
    consensus = HELPER_FIND_CONSENSUS.out.json
    versions = ch_versions
    composition = HELPER_SAMPLE_COMPO.out.tsv
    composition_json = HELPER_SAMPLE_COMPO.out.json
    qc = ch_qc_files
    tax_json = ch_tax_json
    filtered_blast = HELPER_BLAST_FILTER_BITSCORE.out.json
    }
