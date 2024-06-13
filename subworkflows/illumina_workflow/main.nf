/*
Import modules
*/
include { FASTP }                       from './../../modules/fastp'
include { CAT_FASTQ }                   from './../../modules/cat_fastq'

/*
Import sub workflows
*/
include { VSEARCH_WORKFLOW }            from './../vsearch'
include { REMOVE_PCR_PRIMERS }          from './../remove_pcr_primers'
include { DADA2_ILLUMINA_WORKFLOW }     from './../dada2_illumina'

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
    ch_ptrimmer_config
    ch_primers
    ch_primers_rc

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
    Remove PCR primers - using Ptrimmer if possible,
    or Cutadapt if requested
    */
    REMOVE_PCR_PRIMERS(
        ch_illumina_trimmed,
        ch_ptrimmer_config,
        ch_primers,
        ch_primers_rc
    )
    ch_versions     = ch_versions.mix(REMOVE_PCR_PRIMERS.out.versions)

    /*
    Cluster reads and produce OTUs
    */
    if (params.dada) {
        DADA2_ILLUMINA_WORKFLOW(
            REMOVE_PCR_PRIMERS.out.reads
        )
        ch_otus = DADA2_ILLUMINA_WORKFLOW.out.otus
        ch_versions = ch_versions.mix(DADA2_ILLUMINA_WORKFLOW.out.versions)
    } else {
        VSEARCH_WORKFLOW(
            REMOVE_PCR_PRIMERS.out.reads
        )
        ch_otus = VSEARCH_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(VSEARCH_WORKFLOW.out.versions)
    }
    
    emit:
    otus        = ch_otus
    versions    = ch_versions
    qc          = multiqc_files
    }
