process HELPER_BENCHMARK_XLSX {
    tag 'XLSX'
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbiotools:4.0.2--pyhdfd78af_0' :
        'quay.io/biocontainers/pbiotools:4.0.2--pyhdfd78af_0' }"

    input:
    path(results)       // report in json

    output:
    path('*.xlsx')      , emit: xlsx
    path 'versions.yml' , emit: versions

    script:
    def prefix = task.ext.prefix ?: params.run_name

    """
    benchmark_xlsx.py \\
    --results ${results} \\
    --output ${prefix}_benchmark.xlsx

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python3: \$(python3 --version  | sed -e "s/Python //")
    END_VERSIONS
    """
}
