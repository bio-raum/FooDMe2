/*
Import modules
*/
include { FASTP as FASTP_METRICS }      from './../../modules/fastp'
include { FASTP as FASTP_TRIM }         from './../../modules/fastp'
include { CAT_FASTQ }                   from './../../modules/cat_fastq'

/*
Import sub workflows
*/
include { VSEARCH_WORKFLOW }    from './../vsearch'
include { DADA2_WORKFLOW }      from './../dada2'
include { CUTADAPT_WORKFLOW }   from './../cutadapt'

/*
Clean, trim and cluster reads for subsequent
taxonomic profiling
*/
workflow ILLUMINA_WORKFLOW {
    take:
    reads       // [ meta, [ reads ] ]
    ch_primers  // [ primers ]

    main:

    ch_versions     = Channel.from([])
    ch_otus         = Channel.from([])
    ch_qc           = Channel.from([])

    /*
    Trim illumina reads
    */
    FASTP_METRICS(
        reads
    )
    ch_versions     = ch_versions.mix(FASTP_METRICS.out.versions)
    ch_qc           = ch_qc.mix(FASTP_METRICS.out.json)

    /*
    Split trimmed reads by sample to find multi-lane data sets
    */
    FASTP_METRICS.out.reads.groupTuple().branch { meta, fastq ->
        single: fastq.size() == 1
            return [ meta, fastq.flatten()]
        multi: fastq.size() > 1
            return [ meta, fastq.flatten()]
    }.set { ch_reads_illumina }

    /*
    We alert users in case that the insert size is larger than the read
    length - if --cutadapt_trim_3p was not specified
    */
    if (!(params.cutadapt_trim_3p || params.cutadapt_trim_flex)) {

        FASTP_METRICS.out.json.branch { m, j ->
            single_end: m.single_end
            paired: !m.single_end
        }.set { reads_by_configuration }

        reads_by_configuration.single_end.subscribe { m, j ->
            log.warn "${m.sample_id} - single-end data typically requires trimming of 3-prime primer sites. Should you perhaps use --cutadapt_trim_3p?"
        }

        reads_by_configuration.paired.map { m, j ->
            def metrics = get_metrics(j)
            def new_meta =  [:]
            new_meta.sample_id = m.sample_id
            new_meta.insert_size = metrics[0]
            new_meta.mean_read_length = metrics[1]
            tuple(new_meta, j)
        }.set { ch_pe_json_with_insert_size }

        ch_pe_json_with_insert_size.filter { m, j -> m.insert_size > (m.mean_read_length - 20) }.subscribe { m, j ->
            log.warn "${m.sample_id} - the mean insert size seems to be close to or greater than the mean read length. Should you perhaps use --cutadapt_trim_3p?"
        }
    }

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
        ch_primers
    )
    ch_versions         = ch_versions.mix(CUTADAPT_WORKFLOW.out.versions)
    ch_reads_trimmed    = CUTADAPT_WORKFLOW.out.trimmed
    ch_qc               = ch_qc.mix(CUTADAPT_WORKFLOW.out.qc)

    /*
    FASTP quality trimming
    */
    FASTP_TRIM(
        ch_reads_trimmed
    )
    ch_versions             = ch_versions.mix(FASTP_TRIM.out.versions)
    ch_reads_full_trimmed   = FASTP_TRIM.out.reads
    ch_qc                   = ch_qc.mix(FASTP_TRIM.out.json)

    /*
    Cluster reads and produce OTUs/ASVs
    */
    if (params.vsearch) {
        VSEARCH_WORKFLOW(
            ch_reads_full_trimmed
        )
        ch_otus         = VSEARCH_WORKFLOW.out.otus
        ch_qc           = ch_qc.mix(VSEARCH_WORKFLOW.out.stats, VSEARCH_WORKFLOW.out.qc)
        ch_versions     = ch_versions.mix(VSEARCH_WORKFLOW.out.versions)
    } else {
        DADA2_WORKFLOW(
            ch_reads_full_trimmed
        )
        ch_otus         = DADA2_WORKFLOW.out.otus
        ch_qc           = ch_qc.mix(DADA2_WORKFLOW.out.qc)
        ch_versions     = ch_versions.mix(DADA2_WORKFLOW.out.versions)
    }

    emit:
    otus           = ch_otus
    versions       = ch_versions
    qc             = ch_qc
}

/*
Read the FastP JSON metrics
to extract insert size and mean read length
*/
def get_metrics(json) {
    def data = file(json).getText()
    def jsonSlurper = new groovy.json.JsonSlurper()
    def object = jsonSlurper.parseText(data)

    def mean_len = object['summary']['after_filtering']['read1_mean_length']
    def isize = ""
    if (object["insert_size"]) {
        isize = object['insert_size']['peak']
    } else {
        isize = mean_len
    }
    
    return [ isize, mean_len ]
}
