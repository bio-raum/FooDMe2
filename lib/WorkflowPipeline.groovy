//
// This file holds several functions specific to this pipeline

class WorkflowPipeline {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {
        if (params.list_primers) {
            println('Pre-configured primer sets:')
            println('===========================')
            params.primers.keySet().each { primer ->
                def info = params.primers[primer].description
                def doi = params.primers[primer].doi
                println("Name: ${primer}\nDescription: ${info}\nReference: doi:${doi}")
                println('---------------------------')
            }
            System.exit(1)
        }
        if (params.list_dbs) {
            println('Available databases:')
            println('===========================')
            params.references.databases.keySet().each { db ->
                def info = params.references.databases[db].description
                println("Name: ${db}\tSource: ${info}")
                println('---------------------------')
            }
            System.exit(1)
        }
        if (!params.run_name) {
            log.info 'Must provide a run_name (--run_name)'
            System.exit(1)
        }
        if (!params.input && !params.build_references) {
            log.info 'This pipeline requires a sample sheet as input (--input)'
            System.exit(1)
        }
        if (!params.reference_base && !params.build_references) {
            log.info 'No local taxonomy reference specified - downloading on-the-fly instead...'
            log.info 'Consider installing the reference(s) as specified in our documentation!'
        }
        if (params.build_references) {
            if (params.build_references && !params.reference_base) {
                log.info 'Requested to build references without specifying the --reference_base'
                System.exit(1)
            }
            if (!params.skip_genbank) {
                log.info 'WARNING: This will install the GenBank core nt database - over 200GB of storage will be required!'
                log.info 'If you do not think that you will need this database, skip it with --skip_genbank'
            }
        } else {
            if (params.primer_set && !params.primers.keySet().contains(params.primer_set)) {
                log.info "The primer set ${params.primer_set} is not currently configured."
                System.exit(1)
            }
            if (!params.primer_set && !params.db && !params.blast_db) {
                log.info 'You have to specify which database you want to use (--db) if you do not use a built-in primer set (--primer_set)'
                System.exit(1)
            }
            if (!params.primer_set && !params.primers_fa) {
                log.info 'No primer set (--primer_set) or custom primers (--primers_fa) provided. Exiting...'
                System.exit(1)
            }
            if (params.pacbio && params.iontorrent || params.pacbio && params.ont || params.ont && params.iontorrent) {
                log.info 'Sequencing technologies are mutually exclusive - please specify only one!'
                System.exit(1)
            }
            if (params.primers_fa && !params.db && !params.blast_db) {
                log.info "Did not provide a database name (--db) - if you wish to use a custom database, please specify with --blast_db!"
                System.exit(1)
            }
            if (params.primers_fa && !params.taxid_filter) {
                log.warn "Must provide a taxonomic group against which to search your sequences (--taxid_filter)"
                System.exit(1)
            }
            if (params.taxid_filter && !params.taxid_filter.toString().isInteger()) {
                log.warn "The argument for --taxid_filter must be numeric (i.e. a taxonomy id from NCBI)!"
                System.exit(1)
            }
        }
    }

}
