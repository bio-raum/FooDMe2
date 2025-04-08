//
// This file holds several functions specific to this pipeline
//
class WorkflowMain {

    public static void initialise(workflow, params, log) {
        log.info header(workflow)
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

}
