process CUSTOM_DUMPSOFTWAREVERSIONS {
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.19--pyhdfd78af_0' :
        'quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0' }"

    input:
    path versions

    output:
    path 'software_versions.yml'    , emit: yml
    path 'software_versions_mqc.yml', emit: mqc_yml
    path 'versions.yml'             , emit: versions

    script:
    template 'dumpsoftwareversions.py'
}
