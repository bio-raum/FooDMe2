/*
Import modules
*/
include { INPUT_CHECK }                 from './../modules/input_check'
include { MULTIQC }                     from './../modules/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'
include { UNZIP }                       from './../modules/unzip'

/*
Import sub workflows
*/
include { ILLUMINA_WORKFLOW }           from './../subworkflows/illumina_workflow'
include { BLAST_TAXONOMY }              from './../subworkflows/blast_taxonomy'

/*
Set default channels and values
*/
samplesheet = params.input ? Channel.fromPath(file(params.input, checkIfExists:true)) : Channel.value([])
gene        = null

// TODO: Check if this can go into lib/
/*
Make sure the local reference directory exists
*/
if (params.input) {
    refDir = file(params.reference_base + "/foodme2/${params.reference_version}")
    if (!refDir.exists()) {
        log.info 'The required reference directory was not found on your system, exiting!'
        System.exit(1)
    }
}

/*
Primer sets are either pre-configured or can be supplied by user,
preferably as Ptrimmer config, or as fasta for cutadapt.
*/
if (params.primer_set) {
    ch_ptrimmer_config      = Channel.fromPath(file(params.primers[params.primer_set].ptrimmer_config, checkIfExits: true)).collect()
    gene                    = params.primers[params.primer_set].gene
    ch_primers              = Channel.fromPath(file(params.primers[params.primer_set].fasta, checkIfExits: true)).collect()
    ch_primers_rc           = Channel.fromPath(file(params.primers[params.primer_set].fasta, checkIfExits: true)).collectFile(name: 'primers_rc.fasta')
} else if (params.primers_txt) {
    ch_ptrimmer_config      = Channel.fromPath(file(params.primers_txt, checkIfExists: true)).collect()
    gene                    = params.gene.toLowerCase()
    ch_primers              = Channel.from([])
    ch_primers_rc           = Channel.from([])
} else if (params.primers_fa) {
    ch_ptrimmer_config      = Channel.from([])
    ch_primers              = Channel.fromPath(file(params.primers_fa, checkIfExists: true)).collect()
    ch_primers_rc           = Channel.fromPath(file(params.primers_fa, checkIfExists: true)).collectFile(name: 'primers_rc.fasta')
    gene                    = params.gene.toLowerCase()
}

ch_blast_db     = Channel.from([])
ch_blast_db_zip = Channel.from([])

/*
The taxonomy database for this gene
*/
if (params.reference_base && gene) {
    // We retrieve the database folder and attach a rudimentary meta hash
    Channel.fromPath(params.references.genes[gene].blast_db, checkIfExists: true).map { db ->
        [[id: gene], db]
    }.set { ch_blast_db }
    }

tax_nodes           = params.references.taxonomy.nodes          // ncbi taxnomy node file
tax_rankedlineage   = params.references.taxonomy.rankedlineage  // ncbi rankedlineage file

ch_tax_files        = Channel.of([ tax_nodes, tax_rankedlineage ])

/*
Setting default channels
*/
ch_versions     = Channel.from([]) // all version yml files
multiqc_files   = Channel.from([]) // all files to go to MultiQC
ch_otus         = Channel.from([]) // all the OTUs

workflow FOODME2 {
    main:

    /*
    Validate the input samplesheet and 
    alert users to any formatting issues
    */
    INPUT_CHECK(samplesheet)

    /*
    Branch input reads by sequencing technology so we can decide which data
    to process with which workflow
    */
    INPUT_CHECK.out.reads.branch { m, r ->
        illumina: m.platform == 'ILLUMINA'
        torrent: m.platform == 'TORRENT'
        nanopore: m.platform == 'NANOPORE'
        pacbio: m.platform == 'PACBIO'
    }.set { ch_reads_by_platform }
    // channel: [[ sample_id: xxx, platform: xxx ], [ reads ] ]

    /*
    SUB: Processing of Illumina reads
    */
    ILLUMINA_WORKFLOW(
        ch_reads_by_platform.illumina,
        ch_ptrimmer_config,
        ch_primers,
        ch_primers_rc
    )
    ch_versions     = ch_versions.mix(ILLUMINA_WORKFLOW.out.versions)
    multiqc_files   = multiqc_files.mix(ILLUMINA_WORKFLOW.out.qc)
    ch_otus         = ch_otus.mix(ILLUMINA_WORKFLOW.out.otus)

    /*
    SUB: Take all OTUs and determine taxonomic composition
    */
    BLAST_TAXONOMY(
        ch_otus,
        ch_blast_db.collect(),
        ch_tax_files
    )
    ch_versions     = ch_versions.mix(BLAST_TAXONOMY.out.versions)

    // Create list of software packages used
    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    multiqc_files   = multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml)

    MULTIQC(
        multiqc_files.collect()
    )

    emit:
    qc = MULTIQC.out.html
    }
