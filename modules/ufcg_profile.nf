process UFCG_PROFILE {
    def module_name = "ufcg_profile"
    tag "$sample"
    // label:  
    cpus 16
    cache false

    input:
    tuple val(sample), path(scaffolds)

    output:
    tuple val(sample), path("${sample}.ucg"), emit: ucg

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