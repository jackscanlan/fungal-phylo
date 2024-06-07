
/*

TODO:
    - make parameter validation schema
    - make samplesheet validation schema
    - 

*/



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// include functions from nf-schema
include { validateParameters; paramsHelp; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema' 

// Print help message, supply typical command line usage for the pipeline
if (params.help) {
   log.info paramsHelp("nextflow run . --samplesheet samplesheet.csv") // TODO: add typical commands for pipeline
   exit 0
}

// Validate input parameters using schema
// validateParameters( parameters_schema: 'nextflow_schema.json' )

// Print summary of supplied parameters (that differ from defaults)
// log.info paramsSummaryLog(workflow)


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    INPUT AND VARIABLES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/* Inputs and parameters
    Per sample/genome:
        - .fastq input reads (more than one pair)
            - OR accession in repository like NCBI
        - metadata for every genome (required: name, )
    Per pipeline run:
        - Taxonomic group to restrict phylogeny to
        - .fasta files or pHMM of multilocus regions to extract
        - 

*/





/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

    /*
    Subworkflow structure:
        - GENOME_ASSEMBLY takes raw reads and assemblies 'new' genomes
        - GENOME_ANNOTATION takes new genomes and supplied unannotated genomes and annotates using specified high-quality annotated genomes from NCBI
        - CUSTOM_MARKERS takes specified .fasta files and trains UFCG model for use with UFCG profile
        - INTERNAL_GENOMES takes unannotated local assemblies ('internal' genomes) and parses them to feed into GENOME_ANNOTATION and PHYLOGENOMICS
        - EXTERNAL_GENOMES downloads 'external' genomes from NCBI from a particular taxonomic group
            - needs options to limit/prune number of genomes: ie. only keep the best genome (highest N50 or assembly level) per strain or species; 
        - PHYLOGENOMICS takes new, internal and external genome assemblies, as well as custom markers, and extracts sequences, aligns, and makes phylogenetic trees
            - needs options to specify marker genes to be used (core, custom, core + custom, BUSCO etc.)
            - IQTREE2 can use folders of alignments when generating partition and concatenations
    */


// subworkflows
include { CUSTOM_MARKERS                                     } from '../subworkflows/custom_markers'
include { EXTERNAL_GENOMES                                     } from '../subworkflows/external_genomes'
include { GENOME_ANNOTATION                                     } from '../subworkflows/genome_annotation'
include { GENOME_ASSEMBLY                                     } from '../subworkflows/genome_assembly'
include { INTERNAL_GENOMES                                     } from '../subworkflows/internal_genomes'
include { PHYLOGENOMICS                                     } from '../subworkflows/phylogenomics'
// include { VISUALISATION                                     } from '../subworkflows/visualisation'





// modules
include { FIND_ASSEMBLIES                                     } from '../modules/find_assemblies'
include { COMBINE_LANES                             } from '../modules/combine_lanes'
include { READ_PREPROCESSING                        } from '../modules/read_preprocessing'
include { ERROR_CORRECTION                          } from '../modules/error_correction'
include { ASSEMBLY                                  } from '../modules/assembly'
include { CLEAN_ASSEMBLY                                  } from '../modules/clean_assembly'
include { QUAST                                     } from '../modules/quast'
include { UFCG_PROFILE                                     } from '../modules/ufcg_profile'
include { UFCG_ALIGN                                     } from '../modules/ufcg_align'



// utility processes for development and debugging
include { STOP                                      } from '../modules/stop'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow FUNGAL_PHYLO {




    /*
    General ideas for workflow:
        - combine .fastq from different lanes, if necessary
        - Detect adapters with overlapping reads or known adapters using BBDuk
            - tbo and tpe flags
        - Trim adapters and merge overlapping reads
        - Remove low-quality bases and/or SPAdes error correction
        - Run SPAdes assembly (make sure kmer sizes are appropriate)
        - QUAST assessment
        - Annotation of assembly using related species 
            - use BRAKER (which contains AUGUSTUS): https://github.com/Gaius-Augustus/BRAKER 
                - Docker container: https://hub.docker.com/r/teambraker/braker3 
                - "Users have reported that you need to manually copy the AUGUSTUS_CONFIG_PATH contents to a writable location before running our containers from Nextflow. 
                    Afterwards, you need to specify the writable AUGUSTUS_CONFIG_PATH as command line argument to BRAKER in Nextflow."
            - alternatively use funannotate, which is installed in BASC: https://github.com/nextgenusfs/funannotate
                - this also has tools for cleaning and renaming scaffolds: https://funannotate.readthedocs.io/en/latest/prepare.html 
                - use redmask for repeat masking, installed in BASC: redmask/ac36368-foss-2019a-Python-3.7.2 
        - BUSCO for completeness (can interact with funannotate, I think)
        - Metabolite prediction using antiSMASH (can interact with funannotate, I think)
        - Pull specific loci from genome for multi-locus phylogeny
        - Analyse key pathogenicity genes in terms of presence/absence, copy-number etc. 
        - Use UFCG to run phylogenomics across all samples (using container)
        - Across all genomes, run phylogenetic estimation using multi-loci data and phylogenomic data

    */

    //// make empty channels
    ch_genome_reads         = Channel.empty()
    ch_genomes_new          = Channel.empty()
    ch_genomes_external     = Channel.empty()
    ch_genomes_internal     = Channel.empty()
    ch_genomes_all          = Channel.empty()
    ch_custom_markers       = Channel.empty()

    Channel.fromPath(params.samplesheet)
        .splitCsv ( header: true )
        .map { row ->
            // concatenate all values from columns/keys starting with 'fwd' into a string delimited by commas
            def fwd_reads = row.findAll { it.key.startsWith('fwd') } .values() .join(",") 
            // concatenate all values from columns/keys starting with 'rev' into a string delimited by commas
            def rev_reads = row.findAll { it.key.startsWith('rev') } .values() .join(",")
            // output tuple
            [ row.sample, fwd_reads, rev_reads ]
            }
        .concat ( ch_genome_reads )

    /* TODO: '.branch' samplesheet channel into: 
    - 'reads': raw sequencing reads (.fastq files) -- concats with ch_genome_reads
    - 'assembly': existing unannotated assemblies (.fasta or NCBI accession)
    - 'complete': annotated, assembled genomes with NCBI accession (NCBI accession)
    
    */


    //// pull and process external genomes
    if ( params.ncbi_taxid ) {
        EXTERNAL_GENOMES ( 
            params.ncbi_taxid, 
            params.limit_external 
        )
    }


    //// process internal genomes
    if ( ch_genomes_internal ) {
        INTERNAL_GENOMES (
            ch_genomes_internal
        )
    }


    //// assemble new genomes 
    if ( ch_genome_reads ) { // only assemble genomes if ch_genome_reads is not empty
        GENOME_ASSEMBLY ( 
            ch_genome_reads 
        )
    }

    // concat output with empty ch_genomes_new
    ch_genomes_new = 
        ch_genomes_new
        .concat ( assembly_seq_genomes_new )


    //// annotate new genomes
    if ( ch_genomes_new ) {
        GENOME_ANNOTATION (
            ch_genomes_new
        )
    }



    //// produce custom marker profiles
    if ( params.custom_markers ) { // only make custom m
        CUSTOM_MARKERS ( 
            params.custom_markers 
        )
    }

    // concat CUSTOM_MARKERS output with empty ch_custom_markers channel


    //// extract sequences, align and build phylogenetic trees
    // concat ch_genomes_new, ch_genomes_internal and ch_genomes_external
    ch_genomes_all = 
        ch_genomes_all
        .concat ( ch_genomes_new )
        .concat ( ch_genomes_interal )
        .concat ( ch_genomes_external )

    PHYLOGENOMICS (
        // ch_genomes_all
        // ch_custom_markers
        // // channel of .tsv metadata
    )

    // /* 
    // NOTE: UFCG_PROFILE requires all assemblies be placed in a single directory, ideally with a metadata .tsv containing the following:
    // - 'Filename': name of the .fasta of the assembly
    // - 'Label': ID of the strain etc. 
    // - 'Accession': NCBI accession code for the assembly (make this 'NA' for new assemblies)
    
    // This .tsv file is specified with '-m' on the command line.
    // If .tsv metadata is not provided, I think it assumes all the files in the directory it is pointed to are .fasta and will try to extract profiles.
    // */


    // //// make UFCG profile from single genome assembly
    // UFCG_PROFILE ( ch_ufcg_profile_input )

    // UFCG_PROFILE_OLD.out
    //     .concat ( UFCG_PROFILE.out )
    //     .collect ()
    //     .set { ch_ufcg_tree_input }

    // //// combine .ucg profile files into a single channel
    // // UFCG_PROFILE.out.ucg
    // //     .


    // /*
    // ** Phylogenetic modules **
    // - use ufcg align to produce alignments of each gene across the .ucg profiles
    // - check alignments for gaps and remove whole alignments if gaps are above a threshold
    // - concatenate alignments and produce 
    // - 

    // */

    // //// make phylogeny from UFCG profiles
    // UFCG_TREE ( ch_ufcg_tree_input )
    // /* 
    // Use BUSCO sequences, core sequences or rDNA sequences?
    // */

    // //// process that converts UFCG profiles into .fasta (using )


    // //// process that uses ufcg train to build a sequence model of the genes we want to use for the multilocus phylogeny 

}
