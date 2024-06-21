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
        .join ( CLEAN_ASSEMBLY.out.scaffolds, by: [0,1] )  // card: sample, isolate, fwd_reads, rev_reads, merged_reads, unpaired_reads, scaffolds
        .map { sample, isolate, fwd_reads, rev_reads, merged_reads, unpaired_reads, scaffolds ->
            [ sample, fwd_reads, rev_reads, merged_reads, unpaired_reads, scaffolds ] }
        .set { ch_quast_new_input }


    //// assess assembly quality
    QUAST_NEW ( ch_quast_new_input, "new" )

    //// format metadata
    CLEAN_ASSEMBLY.out.scaffolds
        .map { sample, isolate, file ->
            // channel output format
            [ file.getName(), sample, isolate, "unknown", "unknown", isolate, "unknown" ] }
        .set { ch_new_meta }
    
    emit: 
    meta_fileinput = ch_new_meta
    new_assemblies = CLEAN_ASSEMBLY.out.scaffolds.map { sample, isolate, scaffolds -> [ sample, scaffolds ] }
    quast_report_genomes_new = QUAST_NEW.out.report_tsv
    quast_plot_genomes_new = QUAST_NEW.out.nx_plot
}