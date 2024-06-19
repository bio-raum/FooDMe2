include { DADA2_ILLUMINA }              from './../../modules/dada2/illumina'
include { DADA2_ERROR }                 from './../../modules/dada2/error'
include { DADA2_DENOISING }             from './../../modules/dada2/denoising'
include { DADA2_RMCHIMERA }             from './../../modules/dada2/rmchimera'
include { HELPER_SEQTABLE_TO_FASTA }    from './../../modules/helper/seqtable_to_fasta'

ch_versions = Channel.from([])

workflow DADA2_ILLUMINA_WORKFLOW {
    take:
    reads

    main:
    DADA2_ILLUMINA(
        reads
    )
    ch_versions = ch_versions.mix(DADA2_ILLUMINA.out.versions)

    /*
    DADA2 Error model calculation
    */
    DADA2_ERROR(
        reads
    )
    ch_versions = ch_versions.mix(DADA2_ERROR.out.versions)

    // Join reads with the corresponding error model
    ch_reads_with_errors = reads.join(DADA2_ERROR.out.errormodel)

    /*
    DADA2 denoise and merge reads
    */
    DADA2_DENOISING(
        ch_reads_with_errors
    )
    ch_versions = ch_versions.mix(DADA2_DENOISING.out.versions)

    // Remove chimera
    DADA2_RMCHIMERA(
        DADA2_DENOISING.out.seqtab
    )
    ch_versions = ch_versions.mix(DADA2_RMCHIMERA.out.versions)

    // Convert Dada2 Seq table to FASTA file
    HELPER_SEQTABLE_TO_FASTA(
        DADA2_RMCHIMERA.out.rds
    )

    emit:
    otus = DADA2_ILLUMINA.out.otus
    versions = ch_versions
}
