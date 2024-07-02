process HELPER_VSEARCH_MULTIQC {
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/aminoextract:0.3.1--pyhdfd78af_0' :
        'quay.io/biocontainers/aminoextract:0.3.1--pyhdfd78af_0' }"

    input:
    path(jsons) // json reports

    output:
    path('vsearch_mqc.json'), emit: json

    script:

    """
    #!/usr/bin/env python3

    import json

    data = {}
    
    for j in "${jsons}".split(" "):
        with open(j, "r") as fi:
            data.update(json.load(fi))

    config = {
        "id": "custom_cluster_barplot",
        "section_name": "VSearch",
        "description": "Reads merging and dereplication",
        "plot_type": "bargraph",
        "pconfig": {
            "id": "vsearch_barplot",
            "title": "VSearch: read retention",
            "ylab": "# Reads"
        },
        "data": data
        }

    with open("vsearch_mqc.json","w") as fo:
        json.dump(config,fo)
    """
}