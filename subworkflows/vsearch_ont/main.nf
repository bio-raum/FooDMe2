/*
Include Modules
*/
include { VSEARCH_FASTXUNIQUES }        from './../../modules/vsearch/fastxuniques'
include { VSEARCH_SORTBYSIZE }          from './../../modules/vsearch/sortbysize'
include { VSEARCH_CLUSTER_SIZE }        from './../../modules/vsearch/cluster_size'
include { VSEARCH_CLUSTER_UNOISE }      from './../../modules/vsearch/unoise'
include { VSEARCH_UCHIME_DENOVO }       from './../../modules/vsearch/uchime/denovo'
include { HELPER_VSEARCH_STATS }        from './../../modules/helper/vsearch_stats'
include { HELPER_VSEARCH_MULTIQC }      from './../../modules/helper/vsearch_multiqc'

/*
Set default channels
*/
ch_versions = Channel.from([])
ch_qc_files = Channel.from([])
ch_reporting = Channel.from([])

workflow VSEARCH_ONT_WORKFLOW {
    take:
    reads

    main:

    /* 
    Filter reads by size
    */
    

    /*
    Get unique sequences
    */
    VSEARCH_FASTXUNIQUES(
        reads
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTXUNIQUES.out.versions)

    /*
    Cluster unique sequences
    */
    VSEARCH_CLUSTER_UNOISE(
        VSEARCH_FASTXUNIQUES.out.fasta
    )
    ch_versions = ch_versions.mix(VSEARCH_CLUSTER_UNOISE.out.versions)

    /*
    Detect chimeras denovo and remove from OTU set
    */
    VSEARCH_UCHIME_DENOVO(
        VSEARCH_CLUSTER_UNOISE.out.fasta
    )
    ch_versions = ch_versions.mix(VSEARCH_UCHIME_DENOVO.out.versions)
    ch_reporting = ch_reporting.join(VSEARCH_UCHIME_DENOVO.out.fasta)
    
    /*
    Clustering statistics
    */
    HELPER_VSEARCH_STATS(
        ch_reporting
    )

    HELPER_VSEARCH_STATS.out.json.map { meta, json ->
        json
    }.set { ch_json_nometa }

    /*
    MultiQC report
    */
    HELPER_VSEARCH_MULTIQC(
        ch_json_nometa.collect()
    )

    ch_qc_files = ch_qc_files.mix(HELPER_VSEARCH_MULTIQC.out.json)

    emit:
    versions = ch_versions
    otus = VSEARCH_UCHIME_DENOVO.out.fasta
    qc = ch_qc_files
}
