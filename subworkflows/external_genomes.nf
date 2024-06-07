/*
 *  Retrieve and process existing genomes from the NCBI database 
 */


//// modules to import
include { FIND_ASSEMBLIES                                     } from '../modules/find_assemblies'
include { QUAST as QUAST_EXTERNAL                                                } from '../modules/quast'


workflow EXTERNAL_GENOMES {

    take:
    
    ncbi_taxid
    limit_external

    main:

    //// get all genomes assemblies from a specific taxid
    FIND_ASSEMBLIES ( ncbi_taxid, limit_external )

    //// format output channel as [ accession, scaffolds ]
    FIND_ASSEMBLIES.out.genome
        .flatten()
        .tap { assembly_seq_genomes_external }
        .map { file ->
            // get file basename
            def base = file.name.lastIndexOf('.').with {it != -1 ? file.name[0..<it] : file.name}
            // get accession from basename
            def accession = ( base =~ /^(.*?\.\d+)_.*?$/ )[0][1]
            // channel output format
            [ accession, "$projectDir/assets/NO_FILE1", "$projectDir/assets/NO_FILE2", "$projectDir/assets/NO_FILE3", file ]
        }
        .set { ch_genomes_external }

    //// run quast on external assemblies
    QUAST_EXTERNAL ( ch_genomes_external, "old" )


    emit:
    
    assembly_seq_genomes_external
    assembly_report_genomes_external = FIND_ASSEMBLIES.out.tsv
    quast_report_genomes_external = QUAST_EXTERNAL.out.report_tsv
    quast_plot_genomes_external = QUAST_EXTERNAL.out.nx_plot

}