//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    samplesheet
        .splitCsv(header:true, sep:'\t')
        .map { row -> fastq_channel(row) }
        .set { reads }

    emit:
    reads // channel: [ val(meta), [ reads ] ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def fastq_channel(LinkedHashMap row) {
    meta = [:]
    meta.sample_id    = row.sample
    meta.platform     = row.platform ? row.platform : 'ILLUMINA'
    meta.single_end   = true

    valid_platforms = [ 'ILLUMINA', 'NANOPORE', 'PACBIO']

    if (!valid_platforms.contains(row.platform)) {
        exit 1, "ERROR: Please check input samplesheet -> incorrect platform provided!\n${row.platform}"
    }
    array = []
    if (!file(row.fq1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fq1}"
    }
    if (meta.platform == 'ILLUMINA') {
        if (!file(row.fq2).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fq2}"
        }
        meta.single_end = false
        array = [ meta, [ file(row.fq1), file(row.fq2)] ]
    } else {
        array = [ meta, [ file(row.fq1)] ]
    }

    return array
}
