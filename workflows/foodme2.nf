/*
Import modules
*/
include { INPUT_CHECK }                 from './../modules/input_check'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'
include { UNZIP }                       from './../modules/unzip'

/*
Import sub workflows
*/
include { ILLUMINA_WORKFLOW }           from './../subworkflows/illumina_workflow'
include { BLAST_TAXONOMY }              from './../subworkflows/blast_taxonomy'
include { ONT_WORKFLOW }                from './../subworkflows/ont_workflow'
include { REPORTING }                   from './../subworkflows/reporting'

/*
Set default channels and values
*/
samplesheet = params.input ? Channel.fromPath(file(params.input, checkIfExists:true)) : Channel.value([])
reads       = params.reads ? Channel.fromFilePairs(params.reads, size: -1) : Channel.value([])
database    = null
ch_blast_db = Channel.from([])

/*
We make this conditional on input being specified so as to not create issues with
the competing --build_references workflow during which all this would be evaluated also
*/
if (params.input || params.reads) {
    /*
    Make sure the local reference directory exists
    */
    refDir = file(params.reference_base + "/foodme2/${params.reference_version}")
    if (!refDir.exists()) {
        log.info 'The required reference directory was not found on your system, exiting!'
        System.exit(1)
    }

    /*
    Primer sets are either pre-configured or can be supplied by user in FASTA format
    */
    // If we have a pre-configured primer set, get options from config
    if (params.primer_set) {
        database                = params.primers[params.primer_set].database
        ch_primers              = Channel.fromPath(file(params.primers[params.primer_set].fasta, checkIfExits: true)).collect()
        blast_db                = file(params.references.databases[database].blast_db, checkIfExists: true)
        fasta                   = file(params.references.databases[database].fasta, checkIfExists: true)
        version                 = params.references.databases[database].version

    // If the users specifies a custom primer set as FASTA instead
    } else if ((params.input || params.reads) && params.primers_fa) {
        ch_primers              = Channel.fromPath(file(params.primers_fa, checkIfExists: true)).collect()

        // If the user requests one of the installed databases
        if (params.db) {
            database    = params.db
            blast_db    = file(params.references.databases[database].blast_db, checkIfExists: true)
            fasta       = file(params.references.databases[database].fasta, checkIfExists: true)
            version     = params.references.databases[database].version
        // Or allow users to provide their own database
        } else if (params.blast_db) {
            database    = file(params.blast_db).getSimpleName()
            blast_db    = file(params.blast_db, checkIfExists: true)
            version     = 'NA'
            fasta       = null
        }
    }
    Channel.fromPath(blast_db, checkIfExists: true).map { db ->
        [[id: database, version: version], db]
    }.set { ch_blast_db }

    /*
    The taxonomy database for this gene
    */

    if (params.reference_base) {
        tax_nodes           = file(params.references.taxonomy.nodes, checkIfExists: true)          // ncbi taxnomy node file
        tax_rankedlineage   = file(params.references.taxonomy.rankedlineage, checkIfExists: true)  // ncbi rankedlineage file
        tax_merged          = file(params.references.taxonomy.merged, checkIfExists: true)         // ncbi merged file

        ch_tax_files        = Channel.of([ tax_nodes, tax_rankedlineage, tax_merged ])

        ch_taxdb            = Channel.fromPath(params.references.taxonomy.taxdb, checkIfExists: true)
    }

}

/*
Set a taxonomy block list to remove unwanted taxa
*/
ch_blocklist        = Channel.fromPath(params.blocklist, checkIfExists: true)

/*
Set the Jinja template for the HTML report
*/
ch_template         = Channel.fromPath(params.template, checkIfExists: true).collect()

/*
Setting default channels
*/
ch_versions      = Channel.from([]) // all version yml files
ch_otus          = Channel.from([]) // all the OTUs
ch_bitscore      = Channel.from([]) // all the blast reports
ch_consensus     = Channel.from([]) // all consensus
ch_trimfil_json  = Channel.from([]) // all cutadapt mqc reports
ch_cluster_json  = Channel.from([]) // all clustering mqc reports
ch_fastp_json    = Channel.from([]) // all FastP Json reports

workflow FOODME2 {
    main:

    /*
    Validate the input samplesheet and
    alert users to any formatting issues
    */
    if (params.input) {
        INPUT_CHECK(samplesheet)
        ch_reads = INPUT_CHECK.out.reads
    } else if (params.reads) {
        reads.map { s,r ->
            def meta = [:]
            meta.sample_id = s
            meta.single_end = r.size() == 1 ? true : false
            tuple(meta,r)
        }.set { ch_reads }
    }

    // Check if we have single-end data that likely requires 3prime trimming.
    if (!params.cutadapt_trim_3p) {
        ch_reads.filter { m, r -> m.single_end }.count().filter { c -> c > 0 }.map { c ->
            log.warn "$c read sets are classified as single-end - this typically requires --cutadapt_trim_3p."
        }
    }

    /*
    SUB: Processing of reads
    */
    // reads are Pacbio HiFi
    if (params.pacbio) {
    // Pacbio workflow here
    // reads are ONT
    } else if (params.ont) {
        ONT_WORKFLOW(
            ch_reads,
            ch_primers,
            fasta
        )
        ch_versions     = ch_versions.mix(ONT_WORKFLOW.out.versions)
        ch_otus         = ch_otus.mix(ONT_WORKFLOW.out.otus)
        ch_trimfil_json = ch_trimfil_json.mix(ONT_WORKFLOW.out.cutadapt_json)
        ch_cluster_json = ch_cluster_json.mix(ONT_WORKFLOW.out.cluster_json)
    // reads are IonTorrent
    } else if (params.iontorrent) {
        ILLUMINA_WORKFLOW(
            ch_reads,
            ch_primers
        )
        ch_versions     = ch_versions.mix(ILLUMINA_WORKFLOW.out.versions)
        ch_otus         = ch_otus.mix(ILLUMINA_WORKFLOW.out.otus)
        ch_fastp_json   = ch_fastp_json.mix(ILLUMINA_WORKFLOW.out.fastp_json)
        ch_trimfil_json = ch_trimfil_json.mix(ILLUMINA_WORKFLOW.out.cutadapt_json)
        ch_cluster_json = ch_cluster_json.mix(ILLUMINA_WORKFLOW.out.cluster_json)
    // reads are Illumina (or Illumina-like)
    } else {
        ILLUMINA_WORKFLOW(
            ch_reads,
            ch_primers
        )
        ch_versions     = ch_versions.mix(ILLUMINA_WORKFLOW.out.versions)
        ch_otus         = ch_otus.mix(ILLUMINA_WORKFLOW.out.otus)
        ch_trimfil_json = ch_trimfil_json.mix(ILLUMINA_WORKFLOW.out.cutadapt_json)
        ch_fastp_json   = ch_fastp_json.mix(ILLUMINA_WORKFLOW.out.fastp_json)
        ch_cluster_json = ch_cluster_json.mix(ILLUMINA_WORKFLOW.out.cluster_json)
    }

    /*
    SUB: Take each set of OTUs and determine taxonomic composition
    */
    BLAST_TAXONOMY(
        ch_otus,
        ch_blast_db.collect(),
        ch_tax_files.collect(),
        ch_taxdb.collect(),
        ch_blocklist.collect()
    )
    ch_versions    = ch_versions.mix(BLAST_TAXONOMY.out.versions)
    ch_consensus   = ch_consensus.mix(BLAST_TAXONOMY.out.consensus)

    // Create list of software packages used
    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    /*
    Reporting sub workflow
    */
    REPORTING(
        BLAST_TAXONOMY.out.tax_json,
        BLAST_TAXONOMY.out.composition,
        BLAST_TAXONOMY.out.composition_json,
        ch_trimfil_json,
        ch_cluster_json,
        BLAST_TAXONOMY.out.filtered_blast,
        BLAST_TAXONOMY.out.consensus,
        CUSTOM_DUMPSOFTWAREVERSIONS.out.yml,
        ch_fastp_json,
        ch_template,
    )

    emit:
    report = REPORTING.out.report
    xlsx   = REPORTING.out.xlsx
}
