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
include { NANOFILT }            from './../../modules/nanofilt'
include { CAT_FASTQ }           from './../../modules/cat_fastq'
include { VSEARCH_ORIENT }      from './../../modules/vsearch/orient'

ch_versions = Channel.from([])
ch_qc       = Channel.from([])

workflow ONT_WORKFLOW {
    take:
    reads
    ch_primers
    db

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

    // Filter ONT reads
    NANOFILT(
        CUTADAPT_WORKFLOW.out.trimmed
    )

    // Warn if a sample has only a few reads left after filtering.
    NANOFILT.out.filtreads.filter { m, r ->
        r.countFastq() < 100
    }.subscribe { m, r ->
        log.warn "${m.sample_id} - only few or no reads left after filtering."
    }

    // Make sure reads are consistently oriented
    VSEARCH_ORIENT(
        NANOFILT.out.filtreads,
        db
    )

    if (params.vsearch) {
        VSEARCH_ONT_WORKFLOW(
            VSEARCH_ORIENT.out.reads
        )
        ch_otus         = VSEARCH_ONT_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(VSEARCH_ONT_WORKFLOW.out.versions)
        ch_qc           = ch_qc.mix(VSEARCH_ONT_WORKFLOW.out.qc)
        ch_clusterjsons = VSEARCH_ONT_WORKFLOW.out.qc
    } else {
        /*
        SUB: OTU calling with DADA2
        */
        DADA2_WORKFLOW(
            VSEARCH_ORIENT.out.reads
        )
        ch_otus         = DADA2_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(DADA2_WORKFLOW.out.versions)
        ch_qc           = ch_qc.mix(DADA2_WORKFLOW.out.qc)
        ch_clusterjsons = DADA2_WORKFLOW.out.qc
    }

    emit:
    versions = ch_versions
    otus = ch_otus
    qc = ch_qc
    cutadapt_json = CUTADAPT_WORKFLOW.out.qc
    cluster_json  = ch_clusterjsons
    }
