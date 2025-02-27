include { HELPER_GENERATE_SAMPLESHEET } from './../modules/helper/generate_samplesheet'

ch_read_folder = params.read_folder ? Channel.fromPath(params.read_folder, checkIfExists: true) : Channel.from([])

workflow GENERATE_SAMPLESHEET {

    main:

    HELPER_GENERATE_SAMPLESHEET(
        ch_read_folder
    )

    emit:
    tsv = HELPER_GENERATE_SAMPLESHEET.out.tsv
}