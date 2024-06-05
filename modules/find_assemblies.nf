process FIND_ASSEMBLIES {
    def module_name = "find_assemblies"
    tag "$sample"
    // label:  
    cpus 1

    input:

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

    
    """

}