//
// This file holds several functions specific to this pipeline
//
class WorkflowMain {

    public static void initialise(workflow, params, log) {
        log.info header(workflow)

        // Print help text to screen if requested
        if (params.help) {
            log.info help(workflow)
            System.exit(0)
        }
    }

    public static String header(workflow) {
        def headr = ''
        def infoLine = "${workflow.manifest.description} | version ${workflow.manifest.version}"
        headr = """
    ===============================================================================
    ${infoLine}
    ===============================================================================
    """
        return headr
    }

    public static String help(workflow) {
        def command = "nextflow run ${workflow.manifest.name} --input some_file.csv --email me@gmail.com"
        def helpString = ''
        // Help message
        helpString = """

            Usage: $command

            Required parameters:
            --input                        The primary pipeline input (typically a CSV file)
            --email                        Email address to send reports to (enclosed in '')
            Optional parameters:
            --run_name                     A descriptive name for this pipeline run
            --primer_set                   A pre-configured primer set 
            Output:
            --outdir                       Local directory to which all output is written (default: results)
        """
        return helpString
    }

}
