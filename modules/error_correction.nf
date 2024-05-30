process ERROR_CORRECTION {
    def module_name = "error_correction"
    tag "$sample"
    // label:  
    cpus 16

    input:
    tuple val(sample), path(fwd_reads), path(rev_reads), path(merged_reads)

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
        ${sample} \
        ${fwd_reads} \
        ${rev_reads} \
        ${merged_reads}
    
    """

}