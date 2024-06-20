process UFCG_PROFILE {
    def module_name = "ufcg_profile"
    tag "$sample"
    label "medium"

    input:
    tuple val(sample), path(scaffolds)
    path(metadata)
    path(profile_directory)

    output:
    path("*.ucg"), emit: ucg
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
        ${sample} \
        ${scaffolds} \
        ${metadata} \
        ${profile_directory} \
        ${task.cpus}
    
    """

}