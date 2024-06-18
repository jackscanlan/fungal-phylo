process ERROR_CORRECTION {
    def module_name = "error_correction"
    tag "$sample"
    label "very_high"

    input:
    tuple val(sample), path(fwd_reads), path(rev_reads), path(merged_reads)

    output:   
    tuple val(sample), path("*_R1.cor.fastq.gz"), path("*_R2.cor.fastq.gz"), path("*_merged.cor.fastq.gz"), path("*_unpaired.cor.fastq.gz"), emit: reads

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
        ${merged_reads} \
        ${task.cpus}
    
    """

}