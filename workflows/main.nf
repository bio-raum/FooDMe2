// TODO: rename this file to something matching this workflow, e.g. exome.nf

// Modules
include { INPUT_CHECK }                 from '../modules/input_check'
include { FASTP }                       from '../modules/fastp/main'
include { MULTIQC }                     from './../modules/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'

ch_multiqc_config = params.multiqc_config   ? Channel.fromPath(params.multiqc_config, checkIfExists: true).collect() : Channel.value([])
ch_multiqc_logo   = params.multiqc_logo     ? Channel.fromPath(params.multiqc_logo, checkIfExists: true).collect() : Channel.value([])

ch_versions = Channel.from([])
multiqc_files = Channel.from([])

// TODO: Rename block to something matching this workflow, e.g. EXOME
workflow MAIN {
    take:
    samplesheet

    main:

    // TODO: Make sure this module is compatible with the samplesheet format you create
    INPUT_CHECK(samplesheet)

    FASTP(
        INPUT_CHECK.out.reads
    )

    ch_versions = ch_versions.mix(FASTP.out.versions)
    multiqc_files = multiqc_files.mix(FASTP.out.json)

    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    multiqc_files = multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml)

    MULTIQC(
        multiqc_files.collect(),
        ch_multiqc_config,
        ch_multiqc_logo
    )

    emit:
    qc = MULTIQC.out.html
}
