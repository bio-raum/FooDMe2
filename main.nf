#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { validateParameters; paramsSummaryLog; paramsSummaryMap; samplesheetToList } from 'plugin/nf-schema'

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
    //Disabled until we manage to mask default dictionaries
    //validateParameters()

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

    def reportFields = [:]
    reportFields['version'] = workflow.manifest.version
    reportFields['session'] = workflow.sessionId
    reportFields['success'] = workflow.success
    reportFields['dateStarted'] = workflow.start
    reportFields['dateComplete'] = workflow.complete
    reportFields['duration'] = workflow.duration
    reportFields['exitStatus'] = workflow.exitStatus
    reportFields['errorMessage'] = (workflow.errorMessage ?: 'None')
    reportFields['errorReport'] = (workflow.errorReport ?: 'None')
    reportFields['commandLine'] = workflow.commandLine
    reportFields['projectDir'] = workflow.projectDir
    reportFields['script_file'] = workflow.scriptFile
    reportFields['launchDir'] = workflow.launchDir
    reportFields['user'] = workflow.userName
    reportFields['Pipeline script hash ID'] = workflow.scriptId
    reportFields['manifest'] = workflow.manifest

    report_info = ''
    reportFields.each { s ->
        report_info += "\n${s.key}: ${s.value}"
    }
    report_info += "\n\n=== Settings ==="
    def summary = paramsSummaryMap(workflow)
    summary.keySet().each { group ->
        report_info += "\nGroup: ${group}"
        def group_params = summary.get(group)
        group_params.each { k,v ->
            report_info += "\n\s\s${k}: ${v}"
        
        }
    }

    outputDir = new File("${params.outdir}/pipeline_info/")
    if (!outputDir.exists()) {
        outputDir.mkdirs()
    }

    outputTf = new File(outputDir, 'pipeline_report.txt')
    outputTf.withWriter { w -> w << report_info }
}