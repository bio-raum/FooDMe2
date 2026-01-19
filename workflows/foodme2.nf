/*
Import modules
*/
include { INPUT_CHECK }                 from './../modules/input_check'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'
include { UNZIP }                       from './../modules/unzip'
include { STAGE as STAGE_SAMPLESHEET }  from './../modules/helper/stage'

/*
Import sub workflows
*/
include { ILLUMINA_WORKFLOW }           from './../subworkflows/illumina_workflow'
include { ILLUMINA_WORKFLOW as IONTORRENT_WORKFLOW } from './../subworkflows/illumina_workflow'
include { BLAST_TAXONOMY }              from './../subworkflows/blast_taxonomy'
include { ONT_WORKFLOW }                from './../subworkflows/ont_workflow'
include { REPORTING }                   from './../subworkflows/reporting'
include { BENCHMARK }                   from './../subworkflows/benchmark'

include { paramsSummaryMap } from 'plugin/nf-schema'

workflow FOODME2 {
    main:

    /*
    Set default channels and values
    */
    samplesheet = params.input ? Channel.fromPath(file(params.input, checkIfExists:true)) : Channel.value([])
    reads       = params.reads ? Channel.fromFilePairs(params.reads, size: -1) : Channel.value([])
    ch_truthtable = params.ground_truth ? Channel.fromPath(file(params.ground_truth, checkIfExists:true)) : Channel.value([])
    database    = null
    ch_blast_db = Channel.from([])
    ch_reads    = Channel.from([])
    ch_primers  = Channel.from([])
    ch_tax_files = Channel.from([])
    ch_taxdb   = Channel.from([])
    ch_reporting = Channel.from([])

    pipeline_info = Channel.fromPath(dumpParametersToJSON(params.outdir)).collect()

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
            log.info "The required reference directory (version ${params.reference_version}) was not found on your system, exiting!"
            System.exit(1)
        }

        /*
        Primer sets are either pre-configured or can be supplied by user in FASTA format
        */
        // If we have a pre-configured primer set, get options from config
        if (params.primer_set) {
            database                = params.database
            ch_primers              = Channel.fromPath(file(params.fasta, checkIfExits: true)).collect()
            blast_db                = set_blast_db(database)
            fasta                   = params.references.databases[database].fasta ? Channel.from(file(params.references.databases[database].fasta, checkIfExists: true)) : null
            version                 = params.references.databases[database].version
            // use a pre-configured primer but with a different database
            if (params.db) {
                log.info "You chose a pre-configured primer set but are overriding the database - this may lead to problems!"
                database    = params.db
                blast_db    = set_blast_db(database)
                fasta       = params.references.databases[database].fasta ? Channel.from(file(params.references.databases[database].fasta, checkIfExists: true)) : null
                version     = params.references.databases[database].version
            }
        // If the users specifies a custom primer set as FASTA instead
        } else if ((params.input || params.reads) && params.primers_fa) {
            ch_primers              = Channel.fromPath(file(params.primers_fa, checkIfExists: true)).collect()

            // If the user requests one of the installed databases
            if (params.db) {
                database    = params.db
                // Check if that database is configured
                blast_db    = set_blast_db(database)
                fasta       = params.references.databases[database].fasta ? Channel.from(file(params.references.databases[database].fasta, checkIfExists: true)) : null
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
    Set the Quarto template for the HTML report
    */
    if (params.ont) {
        ch_template = Channel.fromPath("${baseDir}/assets/quarto/foodme2_ONT_template.qmd", checkIfExists: true).collect()
    } else {
        ch_template = Channel.fromPath("${baseDir}/assets/quarto/foodme2_ILM_template.qmd", checkIfExists: true).collect()
    }

    /*
    Setting default channels
    */
    ch_versions          = Channel.from([]) // all version yml files
    ch_otus              = Channel.from([]) // all the OTUs
    ch_consensus         = Channel.from([]) // all consensus

    /*
    Validate the input samplesheet and
    alert users to any formatting issues
    */
    if (params.input) {
        // store the samplesheet in results/pipeline_info
        STAGE_SAMPLESHEET(
            samplesheet.map { ss ->
                def meta = [:]
                meta.target = "Samplesheet"
                meta.tool = params.run_name
                tuple(meta,ss)
            }
        )
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
    if (!params.cutadapt_trim_3p & !params.cutadapt_ont) {
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
        ch_reporting    = ch_reporting.mix(ONT_WORKFLOW.out.qc)
        ch_otus         = ch_otus.mix(ONT_WORKFLOW.out.otus)
    // reads are IonTorrent
    } else if (params.iontorrent) {
        IONTORRENT_WORKFLOW(
            ch_reads,
            ch_primers
        )
        ch_versions           = ch_versions.mix(IONTORRENT_WORKFLOW.out.versions)
        ch_reporting          = ch_reporting.mix(IONTORRENT_WORKFLOW.out.qc)
        ch_otus               = ch_otus.mix(IONTORRENT_WORKFLOW.out.otus)
    // reads are Illumina (or Illumina-like)
    } else {
        ILLUMINA_WORKFLOW(
            ch_reads,
            ch_primers
        )
        ch_versions           = ch_versions.mix(ILLUMINA_WORKFLOW.out.versions)
        ch_reporting          = ch_reporting.mix(ILLUMINA_WORKFLOW.out.qc)
        ch_otus               = ch_otus.mix(ILLUMINA_WORKFLOW.out.otus)
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
    ch_reporting   = ch_reporting.mix(BLAST_TAXONOMY.out.composition, BLAST_TAXONOMY.out.composition_json, BLAST_TAXONOMY.out.filtered_blast, BLAST_TAXONOMY.out.consensus)

    // Create list of software packages used
    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    /*
    Reporting sub workflow
    */
    REPORTING(
        BLAST_TAXONOMY.out.tax_json,
        CUSTOM_DUMPSOFTWAREVERSIONS.out.yml,
        ch_template, // Quarto template
        ch_reporting, // contains all the sample level reports from upstream
        pipeline_info
    )

    /*
    SUB: Run benchmark if a ground truth is provided
    */
    if (params.ground_truth) {
        BENCHMARK(
            BLAST_TAXONOMY.out.composition,
            BLAST_TAXONOMY.out.tax_json,
            ch_truthtable
        )
    }

    emit:
    report = REPORTING.out.report
    xlsx   = REPORTING.out.xlsx
}

// Set the correct blast database or throw an error if unknown
def set_blast_db(database) {
    if (!params.references.databases.keySet().contains(database)) {
        log.warn "Provided an unknown database (--db ${database})\nPlease check valid options with --list_dbs\nExiting."
        System.exit(1)
    }
    def blast_db = file(params.references.databases[database].blast_db, checkIfExists: true)

    if (params.ont && !params.references.databases[database].fasta) {
        log.warn "We do not have a FASTA version of this database; it is not currently possible to use it in combination with Nanopore data."
        System.exit(1)
    }
    
    return blast_db
}

// turn the summaryMap to a JSON file
def dumpParametersToJSON(outdir) {
    def timestamp = new java.util.Date().format('yyyy-MM-dd_HH-mm-ss')
    def filename  = "params_${timestamp}.json"
    def temp_pf   = new File(workflow.launchDir.toString(), ".${filename}")
    def jsonStr   = groovy.json.JsonOutput.toJson(params)
    temp_pf.text  = groovy.json.JsonOutput.prettyPrint(jsonStr)

    nextflow.extension.FilesEx.copyTo(temp_pf.toPath(), "${outdir}/pipeline_info/params_${timestamp}.json")
    temp_pf.delete()
    return file("${outdir}/pipeline_info/params_${timestamp}.json")
}