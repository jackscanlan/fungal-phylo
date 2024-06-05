process UFCG_TREE {
    def module_name = "ufcg_tree"
    tag "$params.ncbi_taxid"
    // label:  
    cpus 32
    cache true

    input:
    tuple val(sample), path(ucg)

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