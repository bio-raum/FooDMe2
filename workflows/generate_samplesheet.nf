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
    header = lines.pop()
    samples = []
    // a sample may have more than one pair of files, so we count unique sample ids rather than just lines
    lines.each { line ->
        sample = line.split("\t")[0]
        samples << sample
    }
    nsamples = samples.unique().size()
    log.info "Found $nsamples samples - please make sure this is correct!"
    
}