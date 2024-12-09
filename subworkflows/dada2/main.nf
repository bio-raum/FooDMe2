include { DADA2_FILTNTRIM }             from './../../modules/dada2/filterntrim'
include { DADA2_ERROR }                 from './../../modules/dada2/error'
include { DADA2_DENOISING }             from './../../modules/dada2/denoising'
include { DADA2_FILTERSIZE }             from './../../modules/dada2/filtersize'
include { DADA2_RMCHIMERA }             from './../../modules/dada2/rmchimera'
include { HELPER_SEQTABLE_TO_FASTA }    from './../../modules/helper/seqtable_to_fasta'
include { HELPER_DADA_STATS }           from './../../modules/helper/dada_stats'
include { HELPER_DADA_MULTIQC }         from './../../modules/helper/dada_multiqc'

ch_versions = Channel.from([])
ch_qc_files = Channel.from([])
ch_reporting = Channel.from([])
ch_asvs = Channel.from([])

workflow DADA2_WORKFLOW {
    take:
    reads

    main:

    /*
    Filter reads; trimming is done by Cutadapt
    */
    DADA2_FILTNTRIM(
        reads
    )
    ch_versions = ch_versions.mix(DADA2_FILTNTRIM.out.versions)

    /*
    DADA2 Error model calculation
    */
    DADA2_ERROR(
        DADA2_FILTNTRIM.out.filtered_reads
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

    /*
    Filter by merged read size
    */
    DADA2_FILTERSIZE(
        DADA2_DENOISING.out.seqtab
    )

    // Remove chimera
    if (params.remove_chimera) {
        DADA2_RMCHIMERA(
            DADA2_FILTERSIZE.out.seqtab
        )
        ch_versions = ch_versions.mix(DADA2_RMCHIMERA.out.versions)
        ch_asvs = ch_asvs.mix(DADA2_RMCHIMERA.out.rds)
    } else {
        ch_asvs = ch_asvs.mix(DADA2_DENOISING.out.seqtab)
    }
    // Convert Dada2 Seq table to FASTA file
    HELPER_SEQTABLE_TO_FASTA(
        ch_asvs
    )

    ch_reporting = DADA2_DENOISING.out.mergers.join(ch_asvs)

    // Denoising stats
    HELPER_DADA_STATS(
        ch_reporting.filter { m, r, t -> !m.single_end }
    )

    HELPER_DADA_STATS.out.json.map { meta, json ->
        json
    }.set { ch_json_nometa }

    /*
    MultiQC report
    */
    HELPER_DADA_MULTIQC(
        ch_json_nometa.collect()
    )

    ch_qc_files = ch_qc_files.mix(HELPER_DADA_MULTIQC.out.json)

    emit:
    otus = HELPER_SEQTABLE_TO_FASTA.out.fasta
    versions = ch_versions
    qc = ch_qc_files
    }
