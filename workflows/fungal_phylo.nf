
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

include { COMBINE_LANES                             } from '../modules/combine_lanes'
include { READ_PREPROCESSING                        } from '../modules/read_preprocessing'
include { ERROR_CORRECTION                          } from '../modules/error_correction'
include { ASSEMBLY                                  } from '../modules/assembly'
include { QUAST                                     } from '../modules/quast'
include { UFCG_PROFILE                                     } from '../modules/ufcg_profile'





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
        .set { ch_input }

    /* TODO: '.branch' samplesheet channel into: 
    - 'reads': raw sequencing reads (.fastq files)
    - 'assembly': existing unannotated assemblies (.fasta or NCBI accession)
    - 'complete': annotated, assembled genomes with NCBI accession (NCBI accession)
    
    */

    // ch_input.view()

    //// if input reads are split across lanes, combine fwd and rev into 
    /// NOTE: Input reads need to be in the ./data directory for the code to work at the moment
    COMBINE_LANES ( ch_input )

    //// trim adapters, filter contaminants, merge pairs
    READ_PREPROCESSING ( COMBINE_LANES.out.reads )

    //// correct errors in reads using SPAdes
    ERROR_CORRECTION ( READ_PREPROCESSING.out.reads )

    //// assembly genomes using SPAdes
    ASSEMBLY ( ERROR_CORRECTION.out.reads )

    //// join error-corrected reads with the assembly scaffolds
    ERROR_CORRECTION.out.reads 
        .join ( ASSEMBLY.out.scaffolds, by: 0 )
        .set { ch_quast_input } 

    //// assess assembly quality
    QUAST ( ch_quast_input )

    /* NOTE: Need a process that downloads assemblies from NCBI using accessions from samplesheet
    - use entrezdirect/13.1.20200107-GCCcore-8.2.0 in BASC
    */


    ch_quast_input
        .map { sample, fwd_reads, rev_reads, unpaired_reads, scaffolds ->
             [ sample, scaffolds ] }
        .set { ch_ufcg_profile_input}

    /* 
    NOTE: UFCG_PROFILE requires all assemblies be placed in a single directory, ideally with a metadata .tsv containing the following:
    - 'Filename': name of the .fasta of the assembly
    - 'Label': ID of the strain etc. 
    - 'Accession': NCBI accession code for the assembly (make this 'NA' for new assemblies)
    
    This .tsv file is specified with '-m' on the command line.
    If .tsv metadata is not provided, I think it assumes all the files in the directory it is pointed to are .fasta and will try to extract profiles.
    */

    //// make UFCG profile from single genome assembly
    UFCG_PROFILE ( ch_ufcg_profile_input )

    //// combine .ucg profile files into a single channel
    // UFCG_PROFILE.out.ucg
    //     .

    //// make phylogeny from UFCG profiles
    // UFCG_TREE (  )
    /* 
    Use BUSCO sequences, core sequences or rDNA sequences?
    */

    //// process that converts UFCG profiles into .fasta (using )


    //// process that uses ufcg train to build a sequence model of the genes we want to use for the multilocus phylogeny 

}
