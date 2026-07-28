process BLAST_MAKEBLASTDB {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0c/0c86cbb145786bf5c24ea7fb13448da5f7d5cd124fd4403c1da5bc8fc60c2588/data':
        'community.wave.seqera.io/library/blast:2.17.0--d4fb881691596759' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("${prefix}"), emit: db
    tuple val("${task.process}"), val("makeblastdb"), eval("makeblastdb -version 2>&1 | sed 's/^.*makeblastdb: //; s/ .*\$//'"), topic: versions, emit: versions_makeblastdb

    when:
    task.ext.when == null || task.ext.when

    script:
    def args           = task.ext.args ?: ''
    prefix             = task.ext.prefix ?: "${meta.id}"
    def is_compressed  = fasta.getExtension() == "gz" ? true : false
    def fasta_name     = is_compressed ? fasta.getBaseName() : fasta
    """
    if [ "${is_compressed}" == "true" ]; then
        gzip -c -d ${fasta} > ${fasta_name}
        in_fasta="${fasta_name}"
    elif [ -d "${fasta_name}" ]; then
        in_fasta=\$(find -L "${fasta_name}" -maxdepth 2 -type f \\( -name "*.fasta" -o -name "*.fa" -o -name "*.fna" -o -name "*.ffn" \\) | head -1)
    else
        in_fasta="${fasta_name}"
    fi

    mkdir -p ${prefix}

    makeblastdb \\
        -in \${in_fasta} \\
        -out ${prefix}/${prefix} \\
        ${args}

    """

    stub:
    prefix             = task.ext.prefix ?: "${meta.id}"
    def is_compressed  = fasta.getExtension() == "gz" ? true : false
    def fasta_name     = is_compressed ? fasta.getBaseName() : fasta
    """
    mkdir -p ${prefix}
    touch ${prefix}/${prefix}.ndb
    touch ${prefix}/${prefix}.nhr
    touch ${prefix}/${prefix}.nin
    touch ${prefix}/${prefix}.njs
    touch ${prefix}/${prefix}.not
    touch ${prefix}/${prefix}.nsq
    touch ${prefix}/${prefix}.ntf
    touch ${prefix}/${prefix}.nto

    """
}
