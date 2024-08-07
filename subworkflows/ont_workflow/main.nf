/*
Sub workflows
*/
include { DADA2_WORKFLOW }          from './../dada2'
include { CUTADAPT_WORKFLOW }       from './../cutadapt'
include { VSEARCH_ONT_WORKFLOW }    from './../vsearch_ont'

/*
Modules
*/
include { CUTADAPT }            from './../../modules/cutadapt'
include { PORECHOP_ABI }        from './../../modules/porechop/abi'
include { NANOPLOT }            from './../../modules/nanoplot'
include { CAT_FASTQ }           from './../../modules/cat_fastq'

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
    ch_qc       = ch_qc.mix(PORECHOP_ABI.out.log.map { m, l -> l })

    /*
    Merge reads by sample
    */
    PORECHOP_ABI.out.reads.groupTuple().branch { meta, reads ->
        single: reads.size() == 1
            return [ meta, reads.flatten()]
        multi: reads.size() > 1
            return [ meta, reads.flatten()]
    }.set { ch_reads_ont }

    CAT_FASTQ(
        ch_reads_ont.multi
    )
    ch_ont_trimmed = ch_reads_ont.single.mix(CAT_FASTQ.out.reads)

    /*
    Plot read quality after trimming
    */
    NANOPLOT(
        ch_ont_trimmed
    )
    ch_versions = ch_versions.mix(NANOPLOT.out.versions)
    ch_qc = ch_qc.mix(NANOPLOT.out.txt.map { m, t -> t })

    /*
    SUB: Remove PCR primers using
    Cutadapt
    */
    CUTADAPT_WORKFLOW(
        ch_ont_trimmed,
        ch_primers,
    )
    ch_versions = ch_versions.mix(CUTADAPT_WORKFLOW.out.versions)
    ch_qc       = ch_qc.mix(CUTADAPT_WORKFLOW.out.qc)

    if (params.vsearch) {
        VSEARCH_ONT_WORKFLOW(
            CUTADAPT_WORKFLOW.out.trimmed
        )
        ch_otus         = VSEARCH_ONT_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(VSEARCH_ONT_WORKFLOW.out.versions)
        ch_qc           = ch_qc.mix(VSEARCH_ONT_WORKFLOW.out.qc)
    } else {
        /*
        SUB: OTU calling with DADA2
        */
        DADA2_WORKFLOW(
            CUTADAPT_WORKFLOW.out.trimmed
        )
        ch_otus         = DADA2_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(DADA2_WORKFLOW.out.versions)
        ch_qc           = ch_qc.mix(DADA2_WORKFLOW.out.qc)
    }

    emit:
    versions = ch_versions
    otus = ch_otus
    qc = ch_qc
    }
