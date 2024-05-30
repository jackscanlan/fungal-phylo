
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

include { COMBINE_LANES                              } from '../modules/combine_lanes'

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
        - 
        - Trim adapters and merge overlapping reads
        - Remove low-quality bases and/or SPAdes error correction
        - Run SPAdes assembly (make sure kmer sizes are appropriate)
        - QUAST assessment
        - Annotation of assembly using related species (Augustus? Other programs?)
        - BUSCO for completeness
        - Metabolite prediction using antiSMASH
        - Pull specific loci from genome for multi-locus phylogeny
        - Analyse key pathogenicity genes in terms of presence/absence, copy-number etc. 
        - Use UFCG to run phylogenomics across all samples
        - Across all genomes, run phylogenetic estimation using multi-loci data and phylogenomic data

    */

    Channel.fromPath(params.samplesheet)
        .splitCsv ( header: true )
        .map { row ->
            // concatenate all values from columns starting with 'fwd' into a string delimited by commas
            def fwd_reads = row.findAll { it.key.startsWith('fwd') } .values() .join(",") 
            // concatenate all values from columns starting with 'rev' into a string delimited by commas
            def rev_reads = row.findAll { it.key.startsWith('rev') } .values() .join(",")
            // output tuple
            [ row.sample, fwd_reads, rev_reads ]
            }
        .set { ch_input }

    // ch_input.view()

    //// if input reads are split across lanes, combine fwd and rev into 
    /// NOTE: Input reads need to be in the ./data directory for the code to work at the moment
    COMBINE_LANES ( ch_input )



}
