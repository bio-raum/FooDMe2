/*
Sub workflows
*/
include { DADA2_WORKFLOW }      from './../dada2'
include { CUTADAPT_WORKFLOW }   from './../cutadapt'

/*
Modules
*/
include { CUTADAPT }            from './../../modules/cutadapt'
include { PORECHOP_ABI }        from './../../modules/porechop/abi'
include { NANOPLOT }            from './../../modules/nanoplot'

ch_versions = Channel.from([])
ch_qc       = Channel.from([])

workflow ONT_WORKFLOW {

    take:
    reads
    ch_primers

    main:

    /*
    Remove Nanopore adapters
    */
    PORECHOP_ABI(
        reads
    )
    ch_versions = ch_versions.mix(PORECHOP_ABI.out.versions)
    ch_qc       = ch_qc.mix(PORECHOP_ABI.out.log.map { m,l -> l })

    /*
    Plot read quality after trimming
    */
    NANOPLOT(
        PORECHOP_ABI.out.reads
    )
    ch_versions = ch_versions.mix(NANOPLOT.out.versions)
    ch_qc = ch_qc.mix(NANOPLOT.out.txt.map {m,t -> t })

    /* 
    SUB: Remove PCR primers using
    Cutadapt
    */
    CUTADAPT_WORKFLOW(
        PORECHOP_ABI.out.reads,
        ch_primers,
    )
    ch_versions = ch_versions.mix(CUTADAPT_WORKFLOW.out.versions)
    ch_qc       = ch_qc.mix(CUTADAPT_WORKFLOW.out.qc) 

    /*
    SUB: OTU calling with DADA2
    */
    DADA2_WORKFLOW(
        CUTADAPT_WORKFLOW.out.trimmed
    )
    ch_otus         = DADA2_WORKFLOW.out.otus
    ch_versions     = ch_versions.mix(DADA2_WORKFLOW.out.versions)

    emit:
    versions = ch_versions
    otus = ch_otus
    qc = ch_qc
    
}