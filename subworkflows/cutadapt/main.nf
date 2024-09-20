include { CUTADAPT }            from './../../modules/cutadapt_test'
include { PRIMER_DISAMBIGUATE } from './../../modules/helper/primer_disambiguate'
include { FASTX_REVERSE_COMPLEMENT }    from './../../modules/fastx_toolkit/fastx_reverse_complement'

ch_versions = Channel.from([])
ch_qc  = Channel.from([])

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

    /*
    Samples with low reads should be flagged/removed
    This is controlled by params.min_reads
    */
    CUTADAPT.out.reads.branch { m, r ->
        paired: !m.single_end
        single: m.single_end
    }.set { ch_reads_by_config }

    ch_failed_reads     = Channel.from([])
    ch_pass_reads       = Channel.from([])

    // all paired end samples
    ch_reads_by_config.paired.branch { m, r ->
        pass: file(r[0]).countFastq() >= params.min_reads
        fail: file(r[0]).countFastq() < params.min_reads
    }.set { ch_reads_pe_with_status }

    // all single-end samples
    ch_reads_by_config.single.branch { m, r ->
        pass: file(r).countFastq() >= params.min_reads
        fail: file(r).countFastq() < params.min_reads
    }.set { ch_reads_se_with_status }

    ch_failed_reads     = ch_failed_reads.mix(ch_reads_pe_with_status.fail, ch_reads_se_with_status.fail)
    ch_pass_reads       = ch_pass_reads.mix(ch_reads_pe_with_status.pass, ch_reads_se_with_status.pass)

    // Warn about failed samples based on a minimum number of required sequences
    ch_failed_reads.subscribe { m, r ->
        log.warn "Too few reads - stopping sample ${m.sample_id} after PCR primer removal!"
    }

    emit:
    trimmed     = ch_pass_reads
    versions    = ch_versions
    qc          = ch_qc
    }
