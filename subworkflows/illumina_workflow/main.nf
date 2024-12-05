import groovy.json.JsonSlurper

/*
Import modules
*/
include { FASTP }               from './../../modules/fastp'
include { CAT_FASTQ }           from './../../modules/cat_fastq'

/*
Import sub workflows
*/
include { VSEARCH_WORKFLOW }    from './../vsearch'
include { DADA2_WORKFLOW }      from './../dada2'
include { CUTADAPT_WORKFLOW }   from './../cutadapt'

ch_versions     = Channel.from([])
multiqc_files   = Channel.from([])
ch_clusterjsons = Channel.from([])
ch_otus         = Channel.from([])

/*
Clean, trim and cluster reads for subsequent
taxonomic profiling
*/
workflow ILLUMINA_WORKFLOW {
    take:
    reads       // [ meta, [ reads ] ]
    ch_primers  // [ primers ]

    main:

    /*
    Trim illumina reads
    */
    FASTP(
        reads
    )
    ch_versions     = ch_versions.mix(FASTP.out.versions)
    multiqc_files   = multiqc_files.mix(FASTP.out.json.map { m, j -> j })


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
    We alert users in case that the insert size is larger than the read
    length - if --cutadapt_trim_3p was not specified
    */
    if (!params.cutadapt_trim_3p) {
        FASTP.out.json.filter { m, j -> !m.single_end }.map { m, j ->
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
    Cluster reads and produce OTUs/ASVs
    */
    if (params.vsearch) {
        VSEARCH_WORKFLOW(
            ch_reads_trimmed
        )
        ch_otus         = VSEARCH_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(VSEARCH_WORKFLOW.out.versions)
        multiqc_files   = multiqc_files.mix(VSEARCH_WORKFLOW.out.qc)
        ch_clusterjsons = VSEARCH_WORKFLOW.out.qc
    } else {
        DADA2_WORKFLOW(
            ch_reads_trimmed
        )
        ch_otus         = DADA2_WORKFLOW.out.otus
        ch_versions     = ch_versions.mix(DADA2_WORKFLOW.out.versions)
        multiqc_files   = multiqc_files.mix(DADA2_WORKFLOW.out.qc)
        ch_clusterjsons = DADA2_WORKFLOW.out.qc
    }

    emit:
    otus          = ch_otus
    versions      = ch_versions
    qc            = multiqc_files
    cutadapt_json = CUTADAPT_WORKFLOW.out.qc
    cluster_json  = ch_clusterjsons
    fastp_json    = FASTP.out.json
}

/*
Read the FastP JSON metrics
to extract insert size and mean read length
*/
def get_metrics(json) {
    data = file(json).getText()
    def jsonSlurper = new JsonSlurper()
    def object = jsonSlurper.parseText(data)

    def isize = object['insert_size']['peak']
    def mean_len = object['summary']['after_filtering']['read1_mean_length']

    return [ isize, mean_len ]
}
