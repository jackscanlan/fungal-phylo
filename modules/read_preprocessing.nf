process READ_PREPROCESSING {
    def module_name = "read_preprocessing"
    tag "$sample"
    // label:  
    cpus 8

    input:
    tuple val(sample), path(fwd_reads), path(rev_reads)

    output:   
    path("*.fastq.gz")

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