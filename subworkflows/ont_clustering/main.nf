include { SAVONT_ASV }  from './../../modules/savont/asv'
include { HELPER_ONT_CLUSTER_REPORT } from './../../modules/helper/ont_cluster_report'

workflow ONT_CLUSTERING {
  
    take:
    ch_reads

    main:

    ch_versions = channel.from([])
    ch_reports = channel.from([])

    SAVONT_ASV(
        ch_reads
    )
    ch_versions = ch_versions.mix(SAVONT_ASV.out.versions)

    HELPER_ONT_CLUSTER_REPORT(
        SAVONT_ASV.out.log
    )
    ch_versions = ch_versions.mix(HELPER_ONT_CLUSTER_REPORT.out.versions)
    ch_reports = HELPER_ONT_CLUSTER_REPORT.out.json

    emit:
    otu = SAVONT_ASV.out.fasta
    qc = ch_reports
    versions = ch_versions

}