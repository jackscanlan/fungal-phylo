process ASSEMBLY {
    def module_name = "assembly"
    tag "$sample"
    label "very_high" 

    input:
    tuple val(sample), val(isolate), path(fwd_reads), path(rev_reads), path(merged_reads), path(unpaired_reads)

    output:
    tuple val(sample), val(isolate), path("*_scaffolds.fasta"),       emit: scaffolds
    tuple val(sample), val(isolate), path("*_assembly.log"),          emit: log

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
        ${unpaired_reads} \
        ${task.cpus}
    
    """

}