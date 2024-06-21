process BUILD_TREE {
    def module_name = "build_tree"
    tag "Whole pipeline"
    label "very_high" 

    input:
    path(alignment_directory)
    val(ready)

    output:
    path("*.treefile")
    path("*.iqtree")
    path("*.log")
    path("*.tree"), emit: trees

    publishDir "${projectDir}/output/modules/${module_name}", mode: 'copy'

    // when: 

    script:
    def module_script = "${module_name}.sh"
    """
    #!/usr/bin/bash

    ### run module code
    bash ${module_name}.sh \
        ${projectDir} \
        ${alignment_directory} \
        ${task.cpus}
    
    
    """

}