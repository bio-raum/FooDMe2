include { DADA2_ILLUMINA }  from './../../modules/dada2/illumina'

ch_versions = Channel.from([])

workflow DADA2_ILLUMINA_WORKFLOW {
    take:
    otus

    main:
    DADA2_ILLUMINA(
        otus
    )
    ch_versions = ch_versions.mix(DADA2_ILLUMINA.out.versions)

    emit:
    otus = DADA2_ILLUMINA.out.otus
    versions = ch_versions
}
