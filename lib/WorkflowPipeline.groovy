//
// This file holds several functions specific to this pipeline

class WorkflowPipeline {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {
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
        if (!params.build_references) {
            if (params.primer_set && !params.primers.keySet().contains(params.primer_set)) {
                log.info "The primer set ${params.primer_set} is not currently configured."
                System.exit(1)
            }
            if (!params.primer_set && !params.gene) {
                log.info 'You have to specify which gene you are targeting (--gene) if you do not use a built-in primer set (--primer_set)'
                System.exit(1)
            }
            if (!params.primer_set && !params.primers_txt && !params.primers_fa) {
                log.info 'No primer set (--primer_set) or custom primer configuration (--primers_txt) provided. Exiting...'
                System.exit(1)
            }
            if (!params.primer_set && !params.primers_txt && !params.primers_fa) {
                log.info 'No primer information provided, exiting...'
                System.exit(1)
            }
            if (params.primers_fa && !params.cutadapt) {
                log.info "Provided primer information as Fasta file - this requires the option --cutadapt as well"
                System.exit(1)
            }
        } else {
            if (params.build_references && !params.reference_base) {
                log.info "Requested to build references without specifying the --reference_base"
                System.exit(1)
            }
        }
    }

}
