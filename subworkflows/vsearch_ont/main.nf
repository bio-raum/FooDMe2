/*
Include Modules
*/
include { VSEARCH_FASTXUNIQUES }        from './../../modules/vsearch/fastxuniques'
include { VSEARCH_FASTQFILTER }         from './../../modules/vsearch/fastqfilter'
include { VSEARCH_SORTBYSIZE }          from './../../modules/vsearch/sortbysize'
include { VSEARCH_CLUSTER_SIZE }        from './../../modules/vsearch/cluster_size'
include { VSEARCH_CLUSTER_UNOISE }      from './../../modules/vsearch/unoise'
include { VSEARCH_DEREPFULL }           from './../../modules/vsearch/derep'
include { VSEARCH_UCHIME_DENOVO }       from './../../modules/vsearch/uchime/denovo'
include { HELPER_VSEARCH_STATS }        from './../../modules/helper/vsearch_stats'
include { HELPER_VSEARCH_MULTIQC }      from './../../modules/helper/vsearch_multiqc'

workflow VSEARCH_ONT_WORKFLOW {
    take:
    reads

    main:

    /*
    Set default channels
    */
    ch_versions = Channel.from([])
    ch_qc_files = Channel.from([])
    ch_reporting = Channel.from([])
    ch_empty = Channel.from([]) // always empty, used to make the stats moduel work

    ch_reporting = reads
    /*
    Filter reads - this doesn't do much but is needed for compatibility across platforms
    */
    VSEARCH_FASTQFILTER(
        reads
    )
    /*
    Dereplicate FastQ reads directly
    */
    VSEARCH_FASTXUNIQUES(
        VSEARCH_FASTQFILTER.out.fasta
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTXUNIQUES.out.versions)

    /*
    Cluster unique sequences
    */
    VSEARCH_CLUSTER_SIZE(
       VSEARCH_FASTXUNIQUES.out.fasta
    )
    ch_versions = ch_versions.mix(VSEARCH_CLUSTER_SIZE.out.versions)

    // Remove OTUs with coverage below theshold
    VSEARCH_SORTBYSIZE(
        VSEARCH_CLUSTER_SIZE.out.fasta
    )
    ch_versions = ch_versions.mix(VSEARCH_SORTBYSIZE.out.versions)

    /*
    Cluster unique sequences
    */
    // VSEARCH_CLUSTER_UNOISE(
    //    VSEARCH_FASTXUNIQUES.out.fasta
    //)
    //ch_versions = ch_versions.mix(VSEARCH_CLUSTER_UNOISE.out.versions)

    /*
    Detect chimeras denovo and remove from OTU set
    */
    VSEARCH_UCHIME_DENOVO(
        VSEARCH_SORTBYSIZE.out.fasta
    )
    ch_versions = ch_versions.mix(VSEARCH_UCHIME_DENOVO.out.versions)
    ch_reporting = ch_reporting.join(VSEARCH_UCHIME_DENOVO.out.fasta)

    /*
    Clustering statistics
    */
    reads.join(
        ch_empty, remainder: true
    ).join(
        VSEARCH_FASTQFILTER.out.fasta
    ).join(
        VSEARCH_UCHIME_DENOVO.out.fasta
    ).set { ch_input_stats }
    
    HELPER_VSEARCH_STATS(
        ch_input_stats
    )
    ch_versions = ch_versions.mix(HELPER_VSEARCH_STATS.out.versions)
    ch_qc_files = ch_qc_files.mix(HELPER_VSEARCH_STATS.out.json)

    emit:
    versions = ch_versions
    otus = VSEARCH_UCHIME_DENOVO.out.fasta
    qc = ch_qc_files
    }
