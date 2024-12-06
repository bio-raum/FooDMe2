include { CUTADAPT }            from './../../modules/cutadapt_test'
include { PRIMER_DISAMBIGUATE } from './../../modules/helper/primer_disambiguate'
include { FASTX_REVERSE_COMPLEMENT }    from './../../modules/fastx_toolkit/fastx_reverse_complement'

ch_versions = Channel.from([])
ch_qc  = Channel.from([])
ch_reads = Channel.from([])

workflow CUTADAPT_WORKFLOW {
    take:
    reads
    ch_primers

    main:

    // Disambiguate degenerate primer sequences
    PRIMER_DISAMBIGUATE(
        ch_primers
    )
    ch_primers_disambiguated = PRIMER_DISAMBIGUATE.out.fasta
    ch_versions = ch_versions.mix(PRIMER_DISAMBIGUATE.out.versions)

    // Generate a reverse complement
    FASTX_REVERSE_COMPLEMENT(
        ch_primers_disambiguated
    )
    ch_primers_rc = FASTX_REVERSE_COMPLEMENT.out.fasta
    ch_versions = ch_versions.mix(FASTX_REVERSE_COMPLEMENT.out.versions)

    // Run Cutadapt to remove PCR primers
    CUTADAPT(
        reads,
        ch_primers_disambiguated.collect(),
        ch_primers_rc.collect()
    )
    ch_versions         = ch_versions.mix(CUTADAPT.out.versions)
    ch_qc               = ch_qc.mix(CUTADAPT.out.report)
    ch_reads            = ch_reads.mix(CUTADAPT.out.reads)


    emit:
    trimmed     = ch_reads
    versions    = ch_versions
    qc          = ch_qc
    }
