process CLEAN_ASSEMBLY {
    def module_name = "clean_assembly"
    tag "$sample"
    label "medium"

    input:
    tuple val(sample), val(isolate), path(scaffolds)

    output:
    tuple val(sample), val(isolate), path("${sample}_scaffolds.clean.fasta"), emit: scaffolds


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