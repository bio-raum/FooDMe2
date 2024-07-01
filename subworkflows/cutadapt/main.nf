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
        ch_primers
    )
    ch_versions = ch_versions.mix(CUTADAPT.out.versions)
    ch_qc       = ch_qc.mix(CUTADAPT.out.report) 

    CUTADAPT.out.reads.branch { m, r ->
        pass: r[0].countFastq() > params.min_reads
        fail: r[0].countFastq() < params.min_reads
    }.set { ch_cutadapt_with_status }
    
    ch_cutadapt_with_status.fail.subscribe { m, r ->
        log.warn "Too few reads - stopping sample ${m.sample_id} after PCR primer removal!"
    }

    emit:
    trimmed     = ch_cutadapt_with_status.pass
    versions    = ch_versions
    qc          = ch_qc

}