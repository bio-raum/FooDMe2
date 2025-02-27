include { HELPER_GENERATE_SAMPLESHEET } from './../modules/helper/generate_samplesheet'

ch_read_folder = params.generate_samplesheet ? Channel.fromPath(params.generate_samplesheet, checkIfExists: true) : Channel.from([])

workflow GENERATE_SAMPLESHEET {

    main:

    HELPER_GENERATE_SAMPLESHEET(
        ch_read_folder
    )

    HELPER_GENERATE_SAMPLESHEET.out.tsv.map { s ->
        parse_samplesheet(s)
    }

    emit:
    tsv = HELPER_GENERATE_SAMPLESHEET.out.tsv
}

def parse_samplesheet(ss) {

    lines = file(ss).readLines()
    samples = lines.size()-1
    log.info "Found $samples samples - please make sure this is correct!"
    
}