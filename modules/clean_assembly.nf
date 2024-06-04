process CLEAN_ASSEMBLY {
    def module_name = "clean_assembly"
    tag "$sample"
    // label:  
    cpus 1

    input:
    tuple val(sample), path(scaffolds)

    output:
    tuple val(sample), path("${2}_scaffolds.final.fasta"), emit: scaffolds


    publishDir "${projectDir}/output/modules/${module_name}", mode: 'copy'

    // when: 

    script:
    def module_script = "${module_name}.sh"
    """
    #!/usr/bin/bash

    ### run module code
    bash ${module_name}.sh \
        ${projectDir} \
        ${sample} \
        ${scaffolds} \
        ${task.cpus}
    
    """

}