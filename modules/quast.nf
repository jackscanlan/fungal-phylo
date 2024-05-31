process QUAST {
    def module_name = "quast"
    tag "$sample"
    // label:  
    cpus 4

    input:
    tuple val(sample), path(fwd_reads), path(rev_reads), path(unpaired_reads), path(scaffolds)

    output:
    tuple val(sample), path("*_scaffolds.fasta"),       emit: scaffolds
    tuple val(sample), path("*_assembly.log"),          emit: log

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
        ${unpaired_reads} \
        ${scaffolds} \
        ${task.cpus}
    
    """

}