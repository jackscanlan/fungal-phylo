process UFCG_ALIGN {
    def module_name = "ufcg_align"
    tag "Whole pipeline"
    label "very_high" 
    cache false

    input:
    val(ready)

    output:
    path("align/"), emit: alignment_dir


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