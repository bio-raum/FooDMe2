include { BLAST_BLASTN }            from './../../modules/blast/blastn'
include { BLAST_FILTER_BITSCORE }   from './../../modules/helper/blast_filter_bitscore'

ch_versions = Channel.from([])

workflow BLAST_TAXONOMY {
    take:
    otus
    blast_db

    main:

    /*
    Take the OTUs and blast it against the selected
    Blastn database
    */
    BLAST_BLASTN(
        otus,
        blast_db
    )
    ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions)

    /*
    Filter the Blast hits 
    */
    BLAST_FILTER_BITSCORE(
        BLAST_BLASTN.out.txt
    )

    // Find Consensus

    // Blast stats

    // Merge Blast stats

    // Taxonomy stats

    // Merge Taxonomy stats

    // Summerize results

    emit:
    results = BLAST_BLASTN.out.txt
    versions = ch_versions
}
