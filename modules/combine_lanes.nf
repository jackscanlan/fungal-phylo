process COMBINE_LANES {
    def module_name = "combine_lanes"
    // tag "$meta.pcr_primers; $meta.sample_id"
    // label:  

    input:
    tuple val(sample), val(fwd_reads), val(rev_reads)

    output:   
    path("*_R1.fastq.gz"),          emit: fwd_reads
    path("*_R2.fastq.gz"),          emit: rev_reads

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