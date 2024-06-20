process BUILD_TREE {
    def module_name = "build_tree"
    tag "Whole pipeline"
    label "high" 

    input:
    path(alignment_dir)

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
        ${task.cpus} \
        ${alignment_dir}
    
    """

}