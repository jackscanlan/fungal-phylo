process QUAST {
    def module_name = "quast"
    tag "$sample"
    label "high"

    input:
    tuple val(sample), path(fwd_reads), path(rev_reads), path(merged_reads), path(unpaired_reads), path(scaffolds)
    val(genome_type) // must be "new" or "old"

    output:
    tuple val(sample), path("${sample}_report.tsv"), emit: report_tsv
    tuple val(sample), path("${sample}_Nx_plot.pdf"), emit: nx_plot

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
        ${scaffolds} \
        ${task.cpus} \
        ${genome_type}
    
    """

}