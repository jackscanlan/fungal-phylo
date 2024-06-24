process FIND_ASSEMBLIES_GROUP {
    def module_name = "find_assemblies_group"
    tag "TaxID $ncbi_taxid"
    label "small"
    label "ncbi"

    input:
    val(ncbi_taxid)
    val(limit_external)

    output:
    path("*.fna"), emit: genome
    path("genomes_${ncbi_taxid}.tsv"), emit: tsv

    publishDir "${projectDir}/output/modules/${module_name}", mode: 'copy'
    publishDir "${projectDir}/output/genomes", mode: 'copy', pattern: "*.fna"

    // when: 

    script:
    def module_script = "${module_name}.sh"
    """
    #!/usr/bin/bash

    ### run module code
    bash ${module_name}.sh \
        ${projectDir} \
        ${ncbi_taxid} \
        ${limit_external}

    
    """

}