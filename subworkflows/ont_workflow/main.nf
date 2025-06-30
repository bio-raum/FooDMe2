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
include { NANOPLOT as NANOPLOT_ADAPTER } from './../../modules/nanoplot'
include { NANOPLOT as NANOPLOT_TRIM } from './../../modules/nanoplot'
include { CAT_FASTQ }           from './../../modules/cat_fastq'
include { VSEARCH_ORIENT }      from './../../modules/vsearch/orient'
include { GUNZIP as GUNZIP_NANOPLOT_ADAPTER } from './../../modules/gunzip'
include { GUNZIP as GUNZIP_NANOPLOT_TRIM } from './../../modules/gunzip'
include { FASTPLONG as FASTPLONG_METRICS } from './../../modules/fastplong'
include { FASTPLONG as FASTPLONG_TRIM } from './../../modules/fastplong'

workflow ONT_WORKFLOW {
    take:
    reads
    ch_primers
    db

    main:

    ch_versions = Channel.from([])
    ch_qc       = Channel.from([])
    ch_stats    = Channel.from([])

    /*
    Remove Nanopore adapters - or not
    */

    if (params.skip_porechop) {
        ch_trimmed_reads = reads
    } else {
        PORECHOP_ABI(
            reads
        )
        ch_versions         = ch_versions.mix(PORECHOP_ABI.out.versions)
        ch_trimmed_reads    = PORECHOP_ABI.out.reads.map { m,r -> [ m, [ r]]}
    }
    /*
    Merge reads by sample
    */
    
    ch_trimmed_reads.groupTuple(by: 0).branch { meta, fastq ->
        single: fastq.size() == 1
            return [ meta, fastq.flatten()]
        multi: fastq.size() > 1
            return [ meta, fastq.flatten()]
    }.set { ch_reads_ont }

    CAT_FASTQ(
        ch_reads_ont.multi
    )
    ch_ont_trimmed = ch_reads_ont.single.mix(CAT_FASTQ.out.reads) 

    // Run Fastplong for pre-trimming
    FASTPLONG_METRICS(
        ch_ont_trimmed
    )
    ch_qc = ch_qc.mix(FASTPLONG_METRICS.out.json)
    ch_versions = ch_versions.mix(FASTPLONG_METRICS.out.versions)

    // get metric
    NANOPLOT_ADAPTER(
        FASTPLONG_METRICS.out.reads
    )
    ch_versions = ch_versions.mix(NANOPLOT_ADAPTER.out.versions)

    GUNZIP_NANOPLOT_ADAPTER(
        NANOPLOT_ADAPTER.out.tsv
    )
    ch_qc = ch_qc.mix(GUNZIP_NANOPLOT_ADAPTER.out.gunzip)
    ch_versions = ch_versions.mix(GUNZIP_NANOPLOT_ADAPTER.out.versions)
    
    /*
    SUB: Remove PCR primers using
    Cutadapt
    */
    CUTADAPT_WORKFLOW(
        FASTPLONG_METRICS.out.reads,
        ch_primers,
    )
    ch_versions = ch_versions.mix(CUTADAPT_WORKFLOW.out.versions)
    ch_qc       = ch_qc.mix(CUTADAPT_WORKFLOW.out.qc)

    // Filter ONT reads
    FASTPLONG_TRIM(
        CUTADAPT_WORKFLOW.out.trimmed
    )
    ch_versions = ch_versions.mix(FASTPLONG_TRIM.out.versions)
    ch_qc = ch_qc.mix(FASTPLONG_TRIM.out.json)
   
   /*
    Plot read quality after trimming
    */
    NANOPLOT_TRIM(
        FASTPLONG_TRIM.out.reads
    )
    ch_versions = ch_versions.mix(NANOPLOT_TRIM.out.versions)

    // The TSV output from Nanoplot is gzipped, need it unzipped
    GUNZIP_NANOPLOT_TRIM(
        NANOPLOT_TRIM.out.tsv
    )
    ch_versions = ch_versions.mix(GUNZIP_NANOPLOT_TRIM.out.versions)
    ch_qc = ch_qc.mix(GUNZIP_NANOPLOT_TRIM.out.gunzip)
        
    // Warn if a sample has only a few reads left after filtering.
    FASTPLONG_TRIM.out.reads.filter { m, r ->
        r.countFastq() < 100
    }.subscribe { m, r ->
        log.warn "${m.sample_id} - only few or no reads left after filtering."
    }

    // Make sure reads are consistently oriented
    VSEARCH_ORIENT(
        FASTPLONG_TRIM.out.reads,
        db
    )
    ch_versions = ch_versions.mix(VSEARCH_ORIENT.out.versions)

    if (params.vsearch) {
        VSEARCH_ONT_WORKFLOW(
            VSEARCH_ORIENT.out.reads
        )
        ch_otus         = VSEARCH_ONT_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(VSEARCH_ONT_WORKFLOW.out.versions)
        ch_qc           = ch_qc.mix(VSEARCH_ONT_WORKFLOW.out.qc)
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
    }

    emit:
    versions = ch_versions
    otus = ch_otus
    qc = ch_qc
    stats = ch_stats
    }
