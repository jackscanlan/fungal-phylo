/*
 *  Assemble and process genomes from raw Illumina reads
 */


//// modules to import
include { ASSEMBLY                                          } from '../modules/assembly'
include { CLEAN_ASSEMBLY                                    } from '../modules/clean_assembly'
include { COMBINE_LANES                                     } from '../modules/combine_lanes'
include { ERROR_CORRECTION                                  } from '../modules/error_correction'
include { QUAST as QUAST_NEW                                } from '../modules/quast'
include { READ_PREPROCESSING                                } from '../modules/read_preprocessing'



workflow GENOME_ASSEMBLY {
    
    take:
    
    genome_reads


    main:

    //// if input reads are split across lanes, combine fwd and rev into just two paired files
    COMBINE_LANES ( genome_reads )

    //// trim adapters, filter contaminants, merge pairs
    READ_PREPROCESSING ( COMBINE_LANES.out.reads )

    //// correct errors in reads using SPAdes
    ERROR_CORRECTION ( READ_PREPROCESSING.out.reads )

    //// assembly genomes using SPAdes
    ASSEMBLY ( ERROR_CORRECTION.out.reads )

    /// remove short, duplicated scaffolds and rename remaining
    CLEAN_ASSEMBLY ( ASSEMBLY.out.scaffolds )

    //// join error-corrected reads with the cleaned assembly scaffolds
    ERROR_CORRECTION.out.reads 
        .join ( CLEAN_ASSEMBLY.out.scaffolds, by: 0 ) 
        .set { ch_quast_new_input } // card: sample, fwd_reads, rev_reads, unpaired_reads, scaffolds

    //// assess assembly quality
    QUAST_NEW ( ch_quast_new_input )

    
    
    emit: 
    
    assembly_seq_genomes_new = CLEAN_ASSEMBLY.out.scaffolds
    quast_report_genomes_new = QUAST_NEW.out.report_tsv
    quast_plot_genomes_new = QUAST_NEW.out.nx_plot
}