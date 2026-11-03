include { SAVONT_ASV }  from './../../modules/savont/asv'

workflow ONT_CLUSTERING {
  
    take:
    ch_reads

    main:

    ch_versions = channel.from([])

    SAVONT_ASV(
        ch_reads
    )
    ch_versions = ch_versions.mix(SAVONT_ASV.out.versions)

    // get read counts

    emit:
    otu = SAVONT_ASV.out.fasta

}