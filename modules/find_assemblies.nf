process FIND_ASSEMBLIES {
    def module_name = "find_assemblies"
    tag "TaxID $ncbi_taxid"
    // label:  
    cpus 1
    cache true

    input:
    val(ncbi_taxid)

    output:
    path("*.fna"), emit: genomes
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
        ${ncbi_taxid}

    
    """

}