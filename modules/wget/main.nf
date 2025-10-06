process WGET {
    tag "$url"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/wget:1.21.4' :
        'quay.io/biocontainers/wget:1.21.4' }"

    input:
    tuple val(meta), val(url)

    output:
    tuple val(meta), path("*.zip")  , emit: download
    path 'versions.yml'             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args  = task.ext.args ?: ''
    def local = url.split("/")[-1]
    """

    if [ -n "\${HTTPS_PROXY}" ]; then
        PROXY_OPTIONS="-e use_proxy=yes -e https_proxy=\$HTTPS_PROXY"
    else
        PROXY_OPTIONS=""
    fi

    echo Using \$PROXY_OPTIONS

    wget \$PROXY_OPTIONS $args -O $local $url 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(echo \$(wget --version 2>&1) | sed 's/^.*(GNU Wget) //; s/ built on linux-gnu\$//')
    END_VERSIONS
    """
}
