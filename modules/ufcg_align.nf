process UFCG_ALIGN {
    def module_name = "ufcg_align"
    tag "Whole pipeline"
    // label:  
    cpus 32
    cache true

    input:
    // tuple val(sample), path(ucg)

    output:

    publishDir "${projectDir}/output/modules/${module_name}", mode: 'copy'

    // when: 

    script:
    def module_script = "${module_name}.sh"
    """
    #!/usr/bin/bash

    ### run module code
    bash ${module_name}.sh \
        ${projectDir} \
        ${task.cpus}
    
    """

}