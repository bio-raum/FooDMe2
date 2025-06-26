/*
Include Modules
*/
include { VSEARCH_FASTQMERGE }          from './../../modules/vsearch/fastqmerge'
include { VSEARCH_FASTQMERGE as VSEARCH_FASTQMERGE_FOR_JOIN } from './../../modules/vsearch/fastqmerge'
include { VSEARCH_FASTQJOIN }           from './../../modules/vsearch/fastqjoin'
include { VSEARCH_DEREPFULL }           from './../../modules/vsearch/derep'
include { VSEARCH_SORTBYSIZE }          from './../../modules/vsearch/sortbysize'
include { VSEARCH_FASTQFILTER }         from './../../modules/vsearch/fastqfilter'
include { VSEARCH_FASTQFILTER_READS }   from './../../modules/vsearch/fastqfilter_reads'
include { VSEARCH_CLUSTER_SIZE  }       from './../../modules/vsearch/cluster_size'
include { VSEARCH_CLUSTER_UNOISE }      from './../../modules/vsearch/unoise'
include { VSEARCH_UCHIME_DENOVO }       from './../../modules/vsearch/uchime/denovo'
include { HELPER_VSEARCH_STATS }        from './../../modules/helper/vsearch_stats'
include { HELPER_VSEARCH_MULTIQC }      from './../../modules/helper/vsearch_multiqc'

workflow VSEARCH_WORKFLOW {
    take:
    reads

    main:

    /*
    Set default channels
    */
    ch_versions = Channel.from([])
    ch_qc_files = Channel.from([])
    ch_reporting = Channel.from([])

    /*
    Quality filtr fastq prior to merging
    */
    VSEARCH_FASTQFILTER_READS(
        reads
    )

    /*
    Find paired-end files
    TODO: Deal with unpaired files
    */
    VSEARCH_FASTQFILTER_READS.out.reads.branch { m, r ->
        paired: !m.single_end
        unpaired: m.single_end
    }.set { ch_trimmed_reads }

    ch_reporting = ch_trimmed_reads

    /*
    Merge PE files
    */
    if (params.non_overlapping) {
        // Join reads when reads are not overlapping
        // this should be avoided by using longer read lengths!

        // First, all mergable reads are merged
        VSEARCH_FASTQMERGE_FOR_JOIN(
            ch_trimmed_reads.paired.map { m, r -> [m, r[0], r[1]] }
        )
        ch_merged_reads = VSEARCH_FASTQMERGE_FOR_JOIN.out.fastq

        // then all unmergable reads are joined
        VSEARCH_FASTQJOIN(
            VSEARCH_FASTQMERGE_FOR_JOIN.out.unmerged_reads
        )
        ch_joined_reads = VSEARCH_FASTQJOIN.out.fastq
        ch_versions = ch_versions.mix(VSEARCH_FASTQJOIN.out.versions)
        ch_reporting = ch_reporting.join(VSEARCH_FASTQJOIN.out.fastq)

        // Combine merged and joined reads into one fastq file
        // this loses us the meta hash, but we get it back later...
        ch_merged_reads
        .mix(ch_joined_reads)
        .collectFile { meta, fastq ->
            [ "${meta.sample_id}.combined.fastq", fastq ]
        }.map { fastq ->
            [ fastq.simpleName ,fastq]
        }.set { ch_all_reads }

        // Rejoin the merged reads with the meta hash
        ch_trimmed_reads.paired.map { m,r -> 
            [ m.sample_id, m]
        }.join(ch_all_reads).map { key,m,f ->
            [ m,f ]
        }.set { ch_merged_reads }

    } else {
        // merge overlapping reads - this should be the default
        VSEARCH_FASTQMERGE(
            ch_trimmed_reads.paired.map { m, r -> [m, r[0], r[1]] }
        )
        ch_versions = ch_versions.mix(VSEARCH_FASTQMERGE.out.versions)
        ch_reporting = ch_reporting.join(VSEARCH_FASTQMERGE.out.fastq)
        ch_merged_reads = VSEARCH_FASTQMERGE.out.fastq
    }

    /*
    paired and unpaired reads after optional merging and read name tagging
    we now have [ meta, fastq ]
    */
    ch_merged_reads = ch_merged_reads.mix(ch_trimmed_reads.unpaired)

    /*
    Filter merged reads using static parameters
    This is not ideal and could be improved!
    */
    VSEARCH_FASTQFILTER(
        ch_merged_reads
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTQFILTER.out.versions)
    ch_reporting = ch_reporting.join(VSEARCH_FASTQFILTER.out.fasta)

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
    If we do not want to detect chimeria, we short-circuit this step
    and just pass the filtered fasta file; the reporting script has been updated
    to be able to deal with that. 
    */
    if (params.remove_chimera) {
        VSEARCH_UCHIME_DENOVO(
            VSEARCH_CLUSTER_SIZE.out.fasta
        )
        ch_versions = ch_versions.mix(VSEARCH_UCHIME_DENOVO.out.versions)
        ch_reporting = ch_reporting.join(VSEARCH_UCHIME_DENOVO.out.fasta)
    } else {
        ch_reporting = ch_reporting.join(VSEARCH_FASTQFILTER.out.fasta)
    }

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
    otus = VSEARCH_CLUSTER_SIZE.out.fasta
    stats = HELPER_VSEARCH_STATS.out.json
    qc = ch_qc_files
    }
