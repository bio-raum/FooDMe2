include { BLAST_BLASTN }                from './../../modules/blast/blastn'
include { BLAST_FILTER_BITSCORE }       from './../../modules/helper/blast_filter_bitscore'
include { HELPER_FILTER_TAXONOMY }      from './../../modules/helper/filter_taxonomy'
include { BLAST_TAXONOMY_FROM_DB }      from './../../modules/helper/blast_taxonomy_from_db'
include { HELPER_FIND_CONSENSUS }       from './../../modules/helper/find_consensus'
include { HELPER_CREATE_BLAST_MASK }    from './../../modules/helper/create_blast_mask'

ch_versions = Channel.from([])

workflow BLAST_TAXONOMY {
    take:
    otus
    blast_db
    taxdump // [ nodes, rankedlineage, merged]

    main:

    /*
    taxid 32524 is the default, else 
    we recompute the taxonomy list
    */
    HELPER_FILTER_TAXONOMY(
        taxdump,
        params.taxid_filter
    )
    tax_json = HELPER_FILTER_TAXONOMY.out.json

    BLAST_TAXONOMY_FROM_DB(
        blast_db
    )

    HELPER_CREATE_BLAST_MASK(
        BLAST_TAXONOMY_FROM_DB.out.list,
        params.taxid_filter,
        tax_json
    )
    blast_mask = HELPER_CREATE_BLAST_MASK.out.mask

    /*
    Take the OTUs and blast it against the selected
    Blastn database
    */
    BLAST_BLASTN(
        otus,
        blast_db.collect(),
        blast_mask.collect()
    )
    ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions)

    /*
    Filter the Blast hits 
    */
    BLAST_FILTER_BITSCORE(
        BLAST_BLASTN.out.txt
    )

    // Find taxonomic consensus for each OTU
    HELPER_FIND_CONSENSUS(
        BLAST_FILTER_BITSCORE.out.tsv,
        params.blast_min_consensus,
        tax_json.collect()
    )

    // Blast stats

    // Merge Blast stats

    // Taxonomy stats

    // Merge Taxonomy stats

    // Summerize results

    emit:
    results = BLAST_BLASTN.out.txt
    versions = ch_versions
}
