/*
Include Modules
*/
include { VSEARCH_FASTQMERGE }          from './../../modules/vsearch/fastqmerge'
include { VSEARCH_DEREPFULL }           from './../../modules/vsearch/derep'
include { VSEARCH_SORTBYSIZE }          from './../../modules/vsearch/sortbysize'
include { VSEARCH_FASTQFILTER }         from './../../modules/vsearch/fastqfilter'
include { VSEARCH_CLUSTER_SIZE  }       from './../../modules/vsearch/cluster_size'
include { VSEARCH_CLUSTER_UNOISE }      from './../../modules/vsearch/unoise'
include { VSEARCH_UCHIME_DENOVO }       from './../../modules/vsearch/uchime/denovo'
include { HELPER_VSEARCH_STATS }        from './../../modules/helper/vsearch_stats'

/*
Set default channels
*/
ch_versions = Channel.from([])
ch_qc_files = Channel.from([])

workflow VSEARCH_WORKFLOW {
    take:
    reads

    main:

    /*
    Find paired-end files
    TODO: Deal with unpaired files
    */
    reads.branch { m, r ->
        paired: !m.single_end
        unpaired: m.single_end
    }.set { ch_trimmed_reads }

    /*
    Merge PE files
    */
    VSEARCH_FASTQMERGE(
        ch_trimmed_reads.paired.map { m, r -> [m, r[0], r[1]] }
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTQMERGE.out.versions)

    /*
    paired and unpaired reads after optional merging and read name tagging
    we now have [ meta, fastq ]
    */
    ch_merged_reads = VSEARCH_FASTQMERGE.out.fastq

    /*
    Filter merged reads using static parameters
    This is not ideal and could be improved!
    */
    VSEARCH_FASTQFILTER(
        VSEARCH_FASTQMERGE.out.fastq
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTQFILTER.out.versions)

    /*
    Dereplicate the filtered reads
    */
    VSEARCH_DEREPFULL(
        VSEARCH_FASTQFILTER.out.fasta
    )
    ch_versions = ch_versions.mix(VSEARCH_DEREPFULL.out.versions)

    /*
    Cluster dereplicated sequences
    */
    VSEARCH_CLUSTER_SIZE(
        VSEARCH_DEREPFULL.out.fasta
    )
    ch_versions = ch_versions.mix(VSEARCH_CLUSTER_SIZE.out.versions)

    /*
    Detect chimeras denovo and remove from OTU set
    */
    VSEARCH_UCHIME_DENOVO(
        VSEARCH_CLUSTER_SIZE.out.fasta
    )
    ch_versions = ch_versions.mix(VSEARCH_UCHIME_DENOVO.out.versions)

    /*
    Clustering statistics
    */
    HELPER_VSEARCH_STATS(
        ch_trimmed_reads.paired.map { m, r -> [m, r[0], r[1]] },
        VSEARCH_FASTQMERGE.out.fastq,
        VSEARCH_FASTQFILTER.out.fasta,
        VSEARCH_CLUSTER_SIZE.out.fasta
    )
    ch_qc_files = ch_qc_files.mix(HELPER_VSEARCH_STATS.out.json)

    emit:
    versions = ch_versions
    otus = VSEARCH_CLUSTER_SIZE.out.fasta
    qc = ch_qc_files
    }
