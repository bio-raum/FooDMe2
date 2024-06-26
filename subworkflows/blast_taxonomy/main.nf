include { BLAST_BLASTN }                    from './../../modules/blast/blastn'
include { HELPER_BLAST_FILTER_BITSCORE }    from './../../modules/helper/blast_filter_bitscore'
include { HELPER_FILTER_TAXONOMY }          from './../../modules/helper/filter_taxonomy'
include { BLAST_TAXONOMY_FROM_DB }          from './../../modules/helper/blast_taxonomy_from_db'
include { HELPER_FIND_CONSENSUS }           from './../../modules/helper/find_consensus'
include { HELPER_CREATE_BLAST_MASK }        from './../../modules/helper/create_blast_mask'
include { HELPER_BLAST_APPLY_BLOCKLIST }    from './../../modules/helper/blast_apply_blocklist'

ch_versions = Channel.from([])

workflow BLAST_TAXONOMY {
    take:
    otus        // [ meta, fasta ]
    blast_db    // [ meta, folder ]
    taxdump     // [ nodes, rankedlineage, merged ]
    block_list  // [ blocklist ]

    main:

    /*
    Take the NCBI taxonomy and create a
    JSON-formatted dictionary for the taxonomic
    subgroup of interest.
    */
    HELPER_FILTER_TAXONOMY(
        taxdump,
        params.taxid_filter
    )
    tax_json = HELPER_FILTER_TAXONOMY.out.json

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
        tax_json
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
        blast_mask_blocked.collect()
    )
    ch_versions     = ch_versions.mix(BLAST_BLASTN.out.versions)

    /*
    Filter the Blast hits to remove low-scoring hits
    */
    HELPER_BLAST_FILTER_BITSCORE(
        BLAST_BLASTN.out.txt
    )

    /*
    Find taxonomic consensus for each OTU
    */
    HELPER_FIND_CONSENSUS(
        HELPER_BLAST_FILTER_BITSCORE.out.json,
        params.blast_min_consensus,
        tax_json.collect()
    )

    emit:
    bitscore = HELPER_BLAST_FILTER_BITSCORE.out.json
    consensus = HELPER_FIND_CONSENSUS.out.json
    versions = ch_versions
}
