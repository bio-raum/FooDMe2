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
    multiqc_files   = Channel.from([])
    ch_clusterjsons = Channel.from([])
    ch_otus         = Channel.from([])

    /*
    Trim illumina reads
    */
    FASTP_METRICS(
        reads
    )
    ch_versions     = ch_versions.mix(FASTP_METRICS.out.versions)
    multiqc_files   = multiqc_files.mix(FASTP_METRICS.out.json.map { m, j -> j })


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
        FASTP_METRICS.out.json.filter { m, j -> !m.single_end }.map { m, j ->
            def metrics = get_metrics(j)
            def new_meta =  [:]
            new_meta.sample_id = m.sample_id
            new_meta.insert_size = metrics[0]
            new_meta.mean_read_length = metrics[1]
            tuple(new_meta, j)
        }.set { ch_json_with_insert_size }

        ch_json_with_insert_size.filter { m, j -> m.insert_size > (m.mean_read_length - 20) }.subscribe { m, j ->
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
    multiqc_files       = multiqc_files.mix(CUTADAPT_WORKFLOW.out.qc.map { m,j -> j })
    ch_reads_trimmed    = CUTADAPT_WORKFLOW.out.trimmed

    /*
    FASTP quality trimming
    */
    FASTP_TRIM(
        ch_reads_trimmed
    )
    ch_versions             = ch_versions.mix(FASTP_TRIM.out.versions)
    multiqc_files           = multiqc_files.mix(FASTP_TRIM.out.json.map { m, j -> j })
    ch_reads_full_trimmed   = FASTP_TRIM.out.reads

    /*
    Cluster reads and produce OTUs/ASVs
    */
    if (params.vsearch) {
        VSEARCH_WORKFLOW(
            ch_reads_full_trimmed
        )
        ch_otus         = VSEARCH_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(VSEARCH_WORKFLOW.out.versions)
        multiqc_files   = multiqc_files.mix(VSEARCH_WORKFLOW.out.qc)
        ch_clusterjsons = VSEARCH_WORKFLOW.out.qc
    } else {
        DADA2_WORKFLOW(
            ch_reads_full_trimmed
        )
        ch_otus         = DADA2_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(DADA2_WORKFLOW.out.versions)
        multiqc_files   = multiqc_files.mix(DADA2_WORKFLOW.out.qc)
        ch_clusterjsons = DADA2_WORKFLOW.out.qc
    }

    emit:
    otus           = ch_otus
    versions       = ch_versions
    qc             = multiqc_files
    cutadapt_json  = CUTADAPT_WORKFLOW.out.qc
    cluster_json   = ch_clusterjsons
    fastp_json     = FASTP_METRICS.out.json
    post_trim_json = FASTP_TRIM.out.json
}

/*
Read the FastP JSON metrics
to extract insert size and mean read length
*/
def get_metrics(json) {
    def data = file(json).getText()
    def jsonSlurper = new groovy.json.JsonSlurper()
    def object = jsonSlurper.parseText(data)

    def isize = object['insert_size']['peak']
    def mean_len = object['summary']['after_filtering']['read1_mean_length']

    return [ isize, mean_len ]
}
