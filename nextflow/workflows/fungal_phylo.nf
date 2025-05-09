
/*

TODO:
    - make parameter validation schema
    - make samplesheet validation schema
    - 

*/




//// make genome folder
genome_directory = file("$projectDir/output/genomes").mkdirs()
metadata_directory = file("$projectDir/output/metadata").mkdirs()


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
// include { CUSTOM_MARKERS                                     } from '../subworkflows/custom_markers'
include { REPOSITORY_GENOMES                                     } from '../subworkflows/repository_genomes'
// include { GENOME_ANNOTATION                                     } from '../subworkflows/genome_annotation'
include { GENOME_ASSEMBLY                                     } from '../subworkflows/genome_assembly'
include { LOCAL_GENOMES                                     } from '../subworkflows/local_genomes'
include { PHYLOGENOMICS                                     } from '../subworkflows/phylogenomics'
// include { VISUALISATION                                     } from '../subworkflows/visualisation'





// modules
include { CHANNEL_TO_FILE as META_TO_TSV                                } from '../modules/channel_to_file'



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
    ch_samples_new                      = Channel.empty()
    ch_samples_local                    = Channel.empty()
    ch_samples_repository               = Channel.empty()
    ch_genomes_new                      = Channel.empty()
    ch_ncbi_taxid                       = Channel.empty()
    ch_genomes_repository               = Channel.empty()
    ch_meta_fileinput_new               = Channel.empty()
    ch_meta_fileinput_local             = Channel.empty()
    ch_meta_fileinput_repository        = Channel.empty()
    ch_genomes_local                    = Channel.empty()
    ch_genomes_all                      = Channel.empty()
    ch_custom_markers                   = Channel.empty()
    ch_meta_fileinput                   = Channel.empty()


    /*
    Samplesheet columns:
        - type: 'new', 'local' or 'repository', used to branch channel into the three input channels
        - isolate: strain name (doesn't have to be unique, for resequencing of the same strain etc.)
        - sample: name of sample used for files, must be unique
        - genome_file: path to .fasta or .fna; for 'local' samples only (else put NA)
        - accession: NCBI genome accession (ie. "GCA" or "GCF" prefix), for 'repository' samples only (else put NA)
        - taxid: NCBI taxid, for 'repository' samples only (else put NA)
        - fwd[X]: path to forward-read .fastq for lane X; for 'new' samples only (else put NA)
        - rev[X]: path to reverse-read .fastq for lane X; for 'new' samples only (else put NA)
            - note: you can have as many lanes as you like but they must be paired correctly
    */


    //// parse samplesheet
    Channel.fromPath (params.samplesheet)
        .splitCsv ( header: true )
        .set { ch_samplesheet}

    // ch_samplesheet.view()

    //// populate ch_samples_new
    ch_samplesheet
        .filter { row -> row.type == "new" }  
        .map { row ->
            // concatenate all values from columns/keys starting with 'fwd' into a string delimited by commas
            def fwd_reads = row.findAll { it.key.startsWith('fwd') } .values() .join(",") 
            // concatenate all values from columns/keys starting with 'rev' into a string delimited by commas
            def rev_reads = row.findAll { it.key.startsWith('rev') } .values() .join(",")
            // output tuple
            [ row.sample, row.isolate, file(fwd_reads), file(rev_reads) ]
            }
        .concat ( ch_samples_new )
        .set { ch_samples_new }

    // ch_samples_new .view()

    /// populate ch_samples_local
    ch_samplesheet
        .filter { row -> row.type == "local" }  
        .map { row -> [ row.sample, row.isolate, file(row.genome_file) ]}
        .concat ( ch_samples_local )
        .set { ch_samples_local }

    // ch_samples_local .view()

    /// populate ch_samples_repository
    ch_samplesheet
        .filter { row -> row.type == "repository" }  
        .map { row -> row.accession }
        .concat ( ch_samples_repository )
        .set { ch_samples_repository }

    // ch_samples_repository .view()


    //// parse multi-taxid parameter and add to ch_ncbi_taxid
    if ( params.ncbi_taxid ) {
        Channel.of ( params.ncbi_taxid.toString() )
            .map { taxid -> taxid.tokenize(',') }
            .flatten()
            .concat ( ch_ncbi_taxid )
            .set { ch_ncbi_taxid }
    }
    
    //// pull and process external genomes
    if ( ch_ncbi_taxid || ch_samples_repository ) {
        REPOSITORY_GENOMES ( 
            ch_ncbi_taxid, 
            params.repository_limit,
            ch_samples_repository 
        )

        ch_genomes_repository = REPOSITORY_GENOMES.out.repo_assemblies

        ch_meta_fileinput_repository
            .concat ( REPOSITORY_GENOMES.out.meta_fileinput )
            .set { ch_meta_fileinput_repository }

    }


    //// process internal genomes
    if ( ch_samples_local ) {
        LOCAL_GENOMES (
            ch_samples_local
        )
        
        ch_genomes_local
            .concat ( LOCAL_GENOMES.out.local_assemblies )
            .set { ch_genomes_local }
        ch_meta_fileinput_local
            .concat ( LOCAL_GENOMES.out.meta_fileinput )
            .set { ch_meta_fileinput_local }
    
    }


    // //// assemble new genomes 
    // if ( ch_samples_new ) { // only assemble genomes if ch_samples_new is not empty
    //     GENOME_ASSEMBLY ( 
    //         ch_samples_new 
    //     )
    
    //     ch_genomes_new
    //         .concat ( GENOME_ASSEMBLY.out.new_assemblies )
    //         .set { ch_genomes_new }
    //     ch_meta_fileinput_new
    //         .concat ( GENOME_ASSEMBLY.out.meta_fileinput )
    //         .set { ch_meta_fileinput_new }
    
    //     // //// annotate new genomes
    //     // if ( ch_genomes_new ) {
    //     //     GENOME_ANNOTATION (
    //     //         ch_genomes_new
    //     //     )
    //     // }

    // }

    
 


    // //// produce custom marker profiles
    // if ( params.custom_markers ) { // only make custom m
    //     CUSTOM_MARKERS ( 
    //         params.custom_markers 
    //     )
    // }

    // concat CUSTOM_MARKERS output with empty ch_custom_markers channel



    //// extract sequences, align and build phylogenetic trees
    // concat ch_genomes_new, ch_genomes_internal and ch_genomes_external
    ch_genomes_all
        .concat ( ch_genomes_new )
        .concat ( ch_genomes_local )
        .concat ( ch_genomes_repository )
        .set { ch_genomes_all }



    //// combine metadata input channels
    ch_meta_fileinput
        .concat ( ch_meta_fileinput_new )
        .concat ( ch_meta_fileinput_local )
        .concat ( ch_meta_fileinput_repository )
        .collect ( flat: false )
        .set { ch_meta_fileinput }

    //// comine metadata channels into TSV for ufcg
    META_TO_TSV ( 
        ch_meta_fileinput, 
        "tsv", 
        "filename,label,accession,taxon_name,ncbi_name,strain_name,taxonomy",
        "repository_metadata"
    )

    //// run PHYLOGENOMICS subworkflow
    if ( params.run_phylogenomics ) {
        PHYLOGENOMICS (
            ch_genomes_all, 
            ch_custom_markers, 
            META_TO_TSV.out.metadata
        )
    }


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
