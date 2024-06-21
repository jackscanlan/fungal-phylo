/*
 *  Process existing genomes available locally
 */


//// modules to import
include { QUAST as QUAST_LOCAL                             } from '../modules/quast'



workflow LOCAL_GENOMES {
    
    take:

    local_genomes


    main:

    /// format channel
    local_genomes
        .map { sample, isolate, file ->
            [ sample, file ] }
        .tap { local_assemblies }
        .map { sample, file ->
            [ sample, "$projectDir/assets/NO_FILE1", "$projectDir/assets/NO_FILE2", "$projectDir/assets/NO_FILE3", "$projectDir/assets/NO_FILE4", file ] }
        .set { quast_input_local } 



    //// run quast 
    QUAST_LOCAL ( quast_input_local, "old" )

    //// format metadata
    local_genomes
        .map { sample, isolate, file ->
            // channel output format
            [ file.getName(), sample, isolate, "unknown", "unknown", isolate, "unknown" ] }
        .set { ch_local_meta }

    emit: 

    local_assemblies
    meta_fileinput = ch_local_meta

}