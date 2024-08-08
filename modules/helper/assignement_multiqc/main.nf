process HELPER_ASSIGNEMENT_MULTIQC {
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/aminoextract:0.3.1--pyhdfd78af_0' :
        'quay.io/biocontainers/aminoextract:0.3.1--pyhdfd78af_0' }"

    input:
    path(jsons) // json reports

    output:
    path('assignement_mqc.json'), emit: json

    script:

    """
    #!/usr/bin/env python3

    import json
    import os
    from collections import Counter

    data = {}

    for j in "${jsons}".split(" "):
        with open(j, "r") as fi:
            dict= json.load(fi)

        sample = os.path.split(j)[1].split(".")[0]
        ranks = [d["rank"] for d in dict]
        data.update({sample: Counter(ranks)})

    config = {
        "id": "custom_assignement_barplot",
        "section_name": "BLAST",
        "description": "Taxonomic assignement of sequence clusters",
        "plot_type": "bargraph",
        "pconfig": {
            "id": "assignemnt_barplot",
            "title": "Taxonomic assignement: consensus",
            "ylab": "# Cluster"
        },
        "data": data
    }

    with open("assignement_mqc.json","w") as fo:
        json.dump(config,fo)
    """
}
