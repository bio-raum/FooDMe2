include { REMOVE_PCR_PRIMERS }  from './../remove_pcr_primers'
include { DADA2_WORKFLOW }      from './../dada2'

include { PORECHOP_ABI }        from './../../modules/porechop/abi'
include { NANOPLOT }            from './../../modules/nanoplot'

ch_versions = Channel.from([])
ch_qc       = Channel.from([])

workflow ONT_WORKFLOW {

    take:
    reads
    ch_ptrimmer_config
    ch_primers
    ch_primers_rc

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
    Ptrimmer or Cutadapt
    */
    REMOVE_PCR_PRIMERS(
        PORECHOP_ABI.out.reads,
        ch_ptrimmer_config,
        ch_primers,
        ch_primers_rc
    )
    ch_versions = ch_versions.mix(REMOVE_PCR_PRIMERS.out.versions)

    /*
    SUB: OTU calling with DADA2
    */
    DADA2_WORKFLOW(
        REMOVE_PCR_PRIMERS.out.reads
    )
    ch_otus         = DADA2_WORKFLOW.out.otus
    ch_versions     = ch_versions.mix(DADA2_WORKFLOW.out.versions)

    emit:
    versions = ch_versions
    otus = ch_otus
    qc = ch_qc
    
}