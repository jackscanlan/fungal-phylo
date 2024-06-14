process FIND_ASSEMBLIES {
    def module_name = "find_assemblies"
    tag "TaxID $ncbi_taxid"
    label "small"

    input:
    val(ncbi_taxid)
    val(limit_external)

    output:
    path("*.fna"), emit: genome
    path("genomes_${ncbi_taxid}.tsv"), emit: tsv

    publishDir "${projectDir}/output/modules/${module_name}", mode: 'copy'

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