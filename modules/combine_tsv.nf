process COMBINE_TSV {
    def module_name = "combine_tsv"
    tag "$sample"
    label "very_small"

    input:
    path(tsvs)

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
        ${tsvs}
    
    """

}