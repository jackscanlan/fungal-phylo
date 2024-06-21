process READ_PREPROCESSING {
    def module_name = "read_preprocessing"
    tag "$sample"
    label "high" 

    input:
    tuple val(sample), val(isolate), path(fwd_reads), path(rev_reads)

    output:   
    tuple val(sample), val(isolate), path("*_unmerged_R1.fastq.gz"), path("*_unmerged_R2.fastq.gz"), path("*_merged.fastq.gz"), emit: reads

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
    /// TODO: handle when no merged reads
}