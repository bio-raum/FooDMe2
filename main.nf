#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'

//
/**
===============================
FooDMe2 Pipeline
===============================

This Pipeline performs taxonomic profiling of eukaryotes from mitochondrial amplicon data - for example in food safety analysis.

### Homepage / git
git@github.com:bio-raum/foodme2.git

**/

// Pipeline version
params.version = workflow.manifest.version


include { FOODME2 }                 from './workflows/foodme2'
include { BUILD_REFERENCES }        from './workflows/build_references'

workflow {

    // Validate input parameters
    validateParameters()

    // Print summary of supplied parameters
    log.info paramsSummaryLog(workflow)

    log.info """
            ███████╗ ██████╗  ██████╗ ██████╗ ███╗   ███╗███████╗██████╗ 
            ██╔════╝██╔═══██╗██╔═══██╗██╔══██╗████╗ ████║██╔════╝╚════██╗
            █████╗  ██║   ██║██║   ██║██║  ██║██╔████╔██║█████╗   █████╔╝
            ██╔══╝  ██║   ██║██║   ██║██║  ██║██║╚██╔╝██║██╔══╝  ██╔═══╝ 
            ██║     ╚██████╔╝╚██████╔╝██████╔╝██║ ╚═╝ ██║███████╗███████╗
            ╚═╝      ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝
    """

    qc_report = Channel.from([])

    if (!workflow.containerEngine) {
        log.info "\033[1;31mRunning with Conda is not recommended in production!\033[0m\n\033[0;31mConda environments are not guaranteed to be reproducible - for a discussion, see https://pubmed.ncbi.nlm.nih.gov/29953862/.\033[0m"
    }

    WorkflowMain.initialise(workflow, params, log)

    WorkflowPipeline.initialise(params, log)

    if (params.build_references) {
        BUILD_REFERENCES()
    } else {
        FOODME2()
        qc_report = qc_report.mix(FOODME2.out.report).toList()
    }

}