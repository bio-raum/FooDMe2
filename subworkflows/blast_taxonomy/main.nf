include { BLAST_BLASTN }    from './../../modules/blast/blastn'

ch_versions = Channel.from([])
workflow BLAST_TAXONOMY {

    take:
    otus
    blast_db

    main:

    BLAST_BLASTN(
        otus,
        blast_db
    )
    ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions)

    emit:
    results = BLAST_BLASTN.out.txt
    versions = ch_versions
    
}