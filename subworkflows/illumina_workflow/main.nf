/*
Import modules
*/
include { FASTP }               from './../../modules/fastp'
include { CAT_FASTQ }           from './../../modules/cat_fastq'
include { CUTADAPT }            from './../../modules/cutadapt'

/*
Import sub workflows
*/
include { VSEARCH_WORKFLOW }    from './../vsearch'
include { DADA2_WORKFLOW }      from './../dada2'
include { CUTADAPT_WORKFLOW }   from './../cutadapt'

ch_versions     = Channel.from([])
multiqc_files   = Channel.from([])
ch_jsons        = Channel.from([])
ch_otus         = Channel.from([])

/*
Clean, trim and cluster reads for subsequent
taxonomic profiling
*/
workflow ILLUMINA_WORKFLOW {
    take:
    reads
    ch_primers

    main:

    /*
    Trim illumina reads
    */
    FASTP(
        reads
    )
    ch_versions     = ch_versions.mix(FASTP.out.versions)
    multiqc_files   = multiqc_files.mix(FASTP.out.json)

    /*
    Split trimmed reads by sample to find multi-lane data sets
    */
    FASTP.out.reads.groupTuple().branch { meta, reads ->
        single: reads.size() == 1
            return [ meta, reads.flatten()]
        multi: reads.size() > 1
            return [ meta, reads.flatten()]
    }.set { ch_reads_illumina }

    /*
    Concatenate samples with multiple PE files
    */
    CAT_FASTQ(
        ch_reads_illumina.multi
    )
    ch_illumina_trimmed = ch_reads_illumina.single.mix(CAT_FASTQ.out.reads)

    /*
    Remove PCR primers using Cutadapt
    */
    CUTADAPT_WORKFLOW(
        ch_illumina_trimmed,
        ch_primers,
    )
    ch_versions         = ch_versions.mix(CUTADAPT_WORKFLOW.out.versions)
    multiqc_files       = multiqc_files.mix(CUTADAPT_WORKFLOW.out.qc) 
    ch_reads_trimmed    = CUTADAPT_WORKFLOW.out.trimmed

    /*
    Cluster reads and produce OTUs/ASVs
    */
    if (params.vsearch) {
        VSEARCH_WORKFLOW(
            ch_reads_trimmed
        )
        ch_otus         = VSEARCH_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(VSEARCH_WORKFLOW.out.versions)
    } else {
        DADA2_WORKFLOW(
            ch_reads_trimmed
        )
        ch_otus         = DADA2_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(DADA2_WORKFLOW.out.versions)
    }

    emit:
    otus        = ch_otus
    versions    = ch_versions
    qc          = multiqc_files
    }
