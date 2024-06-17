process FIND_ASSEMBLIES_SINGLE {
    def module_name = "find_assemblies_single"
    tag "TaxID $ncbi_taxid"
    label "small"

    input:
    val(sample)

    output:
    path("*.fna"), emit: genome
    path("genome_${sample}.tsv"), emit: tsv

    publishDir "${projectDir}/output/modules/${module_name}", mode: 'copy'

    // when: 

    script:
    def module_script = "${module_name}.sh"
    """
    #!/usr/bin/bash

    ### run module code
    bash ${module_name}.sh \
        ${projectDir} \
        ${sample}

    
    """

}