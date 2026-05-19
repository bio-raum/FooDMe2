process HELPER_READ_LENGTH {
    tag 'Read length histogram'

    label 'long_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bioinfokit:2.1.3--pyh7cba7a3_0' :
        'quay.io/biocontainers/bioinfokit:2.1.3--pyh7cba7a3_0' }"

    input:
    tuple val(meta), path(reads)  // the fastq to measure
    val suffix

    output:
    tuple val(meta), path('*.hist.txt'), emit: hist

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"

    r1 = reads.first()
    hist = prefix + "." + "${suffix}" + ".hist.txt"

    if (meta.single_end) {
        """
        zcat ${r1} | \
        awk 'NR%4 == 2 {lengths[length(\$0)]++} END {for (l in lengths) {print l, lengths[l]}}' | \
        sort -n > ${hist}
        sed -i '1i length count' ${hist}
        """
    } else {
        r2 = reads[1]
        """
        zcat ${r1} ${r2} | \
        awk 'NR%4 == 2 {lengths[length(\$0)]++} END {for (l in lengths) {print l, lengths[l]}}' | \
        sort -n > ${hist}
        sed -i '1i length count' ${hist}
        """
    }
}
