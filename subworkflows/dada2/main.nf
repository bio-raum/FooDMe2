include { DADA2_ERROR }                 from './../../modules/dada2/error'
include { DADA2_DENOISING }             from './../../modules/dada2/denoising'
include { DADA2_RMCHIMERA }             from './../../modules/dada2/rmchimera'
include { HELPER_SEQTABLE_TO_FASTA }    from './../../modules/helper/seqtable_to_fasta'
include { HELPER_DADA_STATS }           from './../../modules/helper/dada_stats'

ch_versions = Channel.from([])
ch_qc_files = Channel.from([])

workflow DADA2_WORKFLOW {
    take:
    reads

    main:
    
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

    // Denoising stats
    HELPER_DADA_STATS(
        DADA2_DENOISING.out.mergers,
        DADA2_RMCHIMERA.out.rds
    )
    ch_qc_files = ch_qc_files.mix(HELPER_DADA_STATS.out.json)

    emit:
    otus = HELPER_SEQTABLE_TO_FASTA.out.fasta
    versions = ch_versions
    qc = ch_qc_files
}
