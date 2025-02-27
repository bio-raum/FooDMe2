#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

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

summary = [:]

run_name = (params.run_name == false) ? "${workflow.sessionId}" : "${params.run_name}"

WorkflowMain.initialise(workflow, params, log)

WorkflowPipeline.initialise(params, log)

include { FOODME2 }                 from './workflows/foodme2'
include { BUILD_REFERENCES }        from './workflows/build_references'
include { GENERATE_SAMPLESHEET }    from './workflows/generate_samplesheet'

qc_report = Channel.from([])

workflow {
    if (params.build_references) {
        BUILD_REFERENCES()
    } else if (params.generate_samplesheet) {
        GENERATE_SAMPLESHEET()
    } else {
        FOODME2()
        qc_report = qc_report.mix(FOODME2.out.report).toList()
    }
}

workflow.onComplete {
    if (params.primer_set) {
        summary['PrimerSet'] = params.primer_set
    }

    if (params.primers_fa) {
        summary['PrimerFasta'] = params.primers_fa
    }

    summary['Input'] = params.input

    hline = '========================================='
    log.info hline
    log.info "Duration: $workflow.duration"
    log.info hline

    emailFields = [:]
    emailFields['version'] = workflow.manifest.version
    emailFields['session'] = workflow.sessionId
    emailFields['runName'] = run_name
    emailFields['Database'] = params.db
    if (params.primer_set) {
        emailFields['PrimerSet'] = params.primer_set
    }
    if (params.primers_fa) {
        emailFields['Primers'] = params.primers_fa
    }
    emailFields['success'] = workflow.success
    emailFields['dateStarted'] = workflow.start
    emailFields['dateComplete'] = workflow.complete
    emailFields['duration'] = workflow.duration
    emailFields['exitStatus'] = workflow.exitStatus
    emailFields['errorMessage'] = (workflow.errorMessage ?: 'None')
    emailFields['errorReport'] = (workflow.errorReport ?: 'None')
    emailFields['commandLine'] = workflow.commandLine
    emailFields['projectDir'] = workflow.projectDir
    emailFields['script_file'] = workflow.scriptFile
    emailFields['launchDir'] = workflow.launchDir
    emailFields['user'] = workflow.userName
    emailFields['Pipeline script hash ID'] = workflow.scriptId
    emailFields['manifest'] = workflow.manifest
    emailFields['summary'] = summary

    email_info = ''
    for (s in emailFields) {
        email_info += "\n${s.key}: ${s.value}"
    }

    outputDir = new File("${params.outdir}/pipeline_info/")
    if (!outputDir.exists()) {
        outputDir.mkdirs()
    }

    outputTf = new File(outputDir, 'pipeline_report.txt')
    outputTf.withWriter { w -> w << email_info }

    // make txt template
    engine = new groovy.text.GStringTemplateEngine()

    tf = new File("$baseDir/assets/email_template.txt")
    txtTemplate = engine.createTemplate(tf).make(emailFields)
    emailText = txtTemplate.toString()

    // make email template
    hf = new File("$baseDir/assets/email_template.html")
    htmlTemplate = engine.createTemplate(hf).make(emailFields)
    emailHtml = htmlTemplate.toString()

    subject = "Pipeline finished ($run_name)."

    if (params.email) {
        qcReport = null
        try {
            if (workflow.success ) {
                qcReport = qc_report.getVal()
                if (qcReport.getClass() == ArrayList) {
                    log.warn "[FooDMe2] Found multiple reports from process 'report', will use only one"
                    qcReport = qcReport[0]
                }
            }
        } catch (all) {
            log.warn '[FooDMe2] Could not attach MultiQC report to summary email'
        }

        smailFields = [ email: params.email, subject: subject, emailText: emailText,
            emailHtml: emailHtml, baseDir: "$baseDir", mqcFile: qcReport,
            mqcMaxSize: params.maxMultiqcEmailFileSize.toBytes()
        ]
        sf = new File("$baseDir/assets/sendmailTemplate.txt")
        sendmailTemplate = engine.createTemplate(sf).make(smailFields)
        sendmailHtml = sendmailTemplate.toString()

        try {
            if (params.plaintext_email) { throw GroovyException('Send plaintext e-mail, not HTML') }
            // Try to send HTML e-mail using sendmail
            [ 'sendmail', '-t' ].execute() << sendmailHtml
        } catch (all) {
            // Catch failures and try with plaintext
            [ 'mail', '-s', subject, params.email ].execute() << emailText
        }
    }
}

