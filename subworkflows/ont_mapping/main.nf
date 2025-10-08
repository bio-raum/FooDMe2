/*
Modules
*/
include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_DB }         from './../../modules/minimap2/align'
include { MINIMAP2_ALIGN as MINIMAP2_ALIGN_CONSENSUS }  from './../../modules/minimap2/align'
include { SAMTOOLS_CONSENSUS }                          from './../../modules/samtools/consensus'
include { SAMTOOLS_STATS as  SAMTOOLS_STATS_DB }        from './../../modules/samtools/stats'
include { SAMTOOLS_COVERAGE }                           from './../../modules/samtools/coverage'
include { SAMTOOLS_STATS as  SAMTOOLS_STATS_CONSENSUS } from './../../modules/samtools/stats'
include { SAMTOOLS_VIEW as SAMTOOLS_FILTER }            from './../../modules/samtools/view'
include { HELPER_FASTA_FILTER_CONSENSUS }               from './../../modules/helper/fasta_filter_consensus'
include { HELPER_FASTA_SIZE_FROM_COVERAGE }             from './../../modules/helper/fasta_size_from_coverage'
include { CDHIT_CDHITEST }                              from './../../modules/cdhit/cdhitest'
include { HELPER_ONT_MAPPING_REPORT }                   from './../../modules/helper/ont_mapping_report'

/*
This workflow takes ONT reads, maps them against
a reference database, computes locus-level consensus sequences
which are then refined to form pseudo-OTUs. Through remapping, 
these OTUs are then quantified and passed on to the taxonomic 
assignment step
*/
workflow ONT_MAPPING {

    take:
    reads
    db

    main:

    ch_versions = Channel.from([])
    ch_reports = Channel.from([])

    // Align the reads to the reference database
    MINIMAP2_ALIGN_DB(
        reads.combine(db)
    )
    ch_versions = ch_versions.mix(MINIMAP2_ALIGN_DB.out.versions)

    // Get alignment stats
    SAMTOOLS_STATS_DB(
        MINIMAP2_ALIGN_DB.out.bam
    )
    ch_versions = ch_versions.mix(SAMTOOLS_STATS_DB.out.versions)
    ch_reports = ch_reports.mix(SAMTOOLS_STATS_DB.out.stats)

    // Build consensus from BAM alignment
    SAMTOOLS_CONSENSUS(
        MINIMAP2_ALIGN_DB.out.bam
    )
    ch_versions = ch_versions.mix(SAMTOOLS_CONSENSUS.out.versions)

    // Remove bad consensus sequences based on N content
    HELPER_FASTA_FILTER_CONSENSUS(
        SAMTOOLS_CONSENSUS.out.fasta
    )
    ch_versions = ch_versions.mix(HELPER_FASTA_FILTER_CONSENSUS.out.versions)

    // Cluster the consensus sequences
    CDHIT_CDHITEST(
        HELPER_FASTA_FILTER_CONSENSUS.out.fasta
    )
    ch_versions = ch_versions.mix(CDHIT_CDHITEST.out.versions)

    // Remap reads against clustered consensus sequences
    MINIMAP2_ALIGN_CONSENSUS(
        reads.join(CDHIT_CDHITEST.out.fasta)
    )
    ch_versions = ch_versions.mix(MINIMAP2_ALIGN_CONSENSUS.out.versions)

    // Get alignment stats on final set
    SAMTOOLS_STATS_CONSENSUS(
        MINIMAP2_ALIGN_CONSENSUS.out.bam
    )
    ch_versions = ch_versions.mix(SAMTOOLS_CONSENSUS.out.versions)
    ch_reports = ch_reports.mix(SAMTOOLS_STATS_CONSENSUS.out.stats)

    // Remove MapQ 0 alignments
    SAMTOOLS_FILTER(
        MINIMAP2_ALIGN_CONSENSUS.out.bam
    )
    ch_versions = ch_versions.mix(SAMTOOLS_FILTER.out.versions)

    // Compute coverages
    SAMTOOLS_COVERAGE(
        SAMTOOLS_FILTER.out.bam
    )
    ch_versions = ch_versions.mix(SAMTOOLS_COVERAGE.out.versions)

    // Attach size to the pseudo OTUs
    HELPER_FASTA_SIZE_FROM_COVERAGE(
        CDHIT_CDHITEST.out.fasta.join(SAMTOOLS_COVERAGE.out.txt)
    )
    ch_versions = ch_versions.mix(HELPER_FASTA_SIZE_FROM_COVERAGE.out.versions)

    HELPER_ONT_MAPPING_REPORT(
        ch_reports.groupTuple()
    )

    emit:
    otu = HELPER_FASTA_SIZE_FROM_COVERAGE.out.fasta
    bam = MINIMAP2_ALIGN_DB.out.bam
    qc = HELPER_ONT_MAPPING_REPORT.out.json
    versions = ch_versions
}