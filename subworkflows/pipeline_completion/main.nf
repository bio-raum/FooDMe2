include { paramsSummaryMap } from 'plugin/nf-schema'

workflow PIPELINE_COMPLETION {

    main:

    def summary = paramsSummaryMap(workflow)

    workflow.onComplete = {
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

        def report_info = ''
        reportFields.each { s ->
            report_info += "\n${s.key}: ${s.value}"
        }
        report_info += "\n\n=== Settings ==="
        summary.keySet().each { group ->
            report_info += "\nGroup: ${group}"
            def group_params = summary.get(group)
            group_params.each { k,v ->
                report_info += "\n\s\s${k}: ${v}"
            }
        }
        def outputDir = new File("${params.outdir}/pipeline_info/")
        if (!outputDir.exists()) {
            outputDir.mkdirs()
        }

        def outputTf = new File(outputDir, 'pipeline_report.txt')
        outputTf.withWriter { w -> w << report_info }
    }

}