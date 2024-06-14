process COMBINE_LANES {
    def module_name = "combine_lanes"
    tag "$sample"
    label "very_small"    

    input:
    tuple val(sample), val(fwd_reads), val(rev_reads)

    output:   
    tuple val(sample), path("*_R1.fastq.gz"), path("*_R2.fastq.gz"),          emit: reads

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
        ${rev_reads} 
    
    """

}