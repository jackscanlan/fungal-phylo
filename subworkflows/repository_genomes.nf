/*
 *  Retrieve and process existing genomes from the NCBI database 
 */


//// modules to import
include { FIND_ASSEMBLIES_SINGLE                                     } from '../modules/find_assemblies_single'
include { FIND_ASSEMBLIES_GROUP                                     } from '../modules/find_assemblies_group'
include { QUAST as QUAST_REPOSITORY                           } from '../modules/quast'


workflow REPOSITORY_GENOMES {

    take:
    
    ncbi_taxid
    limit_repository
    samples

    main:

    //// define channels as empty
    ch_genomes_found_single = Channel.empty()
    ch_genomes_found_group  = Channel.empty()

    //// get all genome assemblies specified in samplesheet
    if ( samples ) {
        FIND_ASSEMBLIES_SINGLE ( samples )
        
        ch_genomes_found_single
            .concat ( FIND_ASSEMBLIES_SINGLE.out.genome )
            .set { ch_genomes_found_single }
    }

    //// get all genomes assemblies from a specific taxid, if specified using params.ncbi_taxid
    if ( ncbi_taxid ) {
        FIND_ASSEMBLIES_GROUP ( ncbi_taxid, limit_repository )
        
        ch_genomes_found_group
            .concat ( FIND_ASSEMBLIES_GROUP.out.genome )
            .set { ch_genomes_found_group }
    }

    //// combine ch_genomes_found_single and ch_genomes_found_group, removing duplicates
    ch_genomes_found_single
        .concat ( ch_genomes_found_group )
        .unique ()
        .set { ch_genomes_found }

    //// format output channel as [ accession, scaffolds ]
    ch_genomes_found
        .flatten()
        .tap { assembly_seq_genomes_repository }
        .map { file ->
            // get file basename
            def base = file.name.lastIndexOf('.').with {it != -1 ? file.name[0..<it] : file.name}
            // get accession from basename
            def accession = ( base =~ /^(.*?\.\d+)_.*?$/ )[0][1]
            // channel output format
            [ accession, "$projectDir/assets/NO_FILE1", "$projectDir/assets/NO_FILE2", "$projectDir/assets/NO_FILE3", file ]
        }
        .set { ch_genomes_repository }

    //// run quast on repository assemblies
    QUAST_REPOSITORY ( ch_genomes_repository, "old" )


    emit:
    
    assembly_seq_genomes_repository
    // assembly_report_genomes_repository = FIND_ASSEMBLIES_GROUP.out.tsv
    quast_report_genomes_repository = QUAST_REPOSITORY.out.report_tsv
    quast_plot_genomes_repository = QUAST_REPOSITORY.out.nx_plot

}