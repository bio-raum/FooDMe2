include { CUTADAPT }    from './../../modules/cutadapt'

ch_versions = Channel.from([])
ch_qc  = Channel.from([])

workflow CUTADAPT_WORKFLOW {

    take:
    reads
    ch_primers

    main:

    CUTADAPT(
        reads,
        ch_primers.collect()
    )
    ch_versions         = ch_versions.mix(CUTADAPT.out.versions)
    ch_qc               = ch_qc.mix(CUTADAPT.out.report) 
    
    CUTADAPT.out.reads.branch { m, r -> 
        paired: !m.single_end
        single: m.single_end
    }.set { ch_reads_by_config }

    ch_failed_reads     = Channel.from([])
    ch_pass_reads       = Channel.from([])

    // all paired end samples
    ch_reads_by_config.paired.branch { m, r ->
        pass: file(r[0]).countFastq() > params.min_reads
        fail: file(r[0]).countFastq() < params.min_reads
    }.set { ch_reads_pe_with_status }

    // all single-end samples
    ch_reads_by_config.single.branch { m, r ->
        pass: file(r).countFastq() > params.min_reads
        fail: file(r).countFastq() < params.min_reads
    }.set { ch_reads_se_with_status }

    ch_failed_reads     = ch_failed_reads.mix(ch_reads_pe_with_status.fail, ch_reads_se_with_status.fail)
    ch_pass_reads       = ch_pass_reads.mix(ch_reads_pe_with_status.pass, ch_reads_se_with_status.pass)
    
    ch_failed_reads.subscribe { m, r ->
        log.warn "Too few reads - stopping sample ${m.sample_id} after PCR primer removal!"
    }

    emit:
    trimmed     = ch_pass_reads
    versions    = ch_versions
    qc          = ch_qc

}