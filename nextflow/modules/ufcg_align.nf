process UFCG_ALIGN {
    def module_name = "ufcg_align"
    tag "Whole pipeline"
    label "high" 

    input:
    path(profile_directory)
    val(ready)
    path(alignment_directory)

    output:
    path("align/"), emit: alignment_dir
    val(true), emit: ready_signal


    publishDir "${projectDir}/output/modules/${module_name}", mode: 'copy'

    // when: 

    script:
    def module_script = "${module_name}.sh"
    """
    #!/usr/bin/bash

    ### run module code
    bash ${module_name}.sh \
        ${projectDir} \
        ${profile_directory} \
        ${alignment_directory} \
        ${task.cpus}
    
    """

}