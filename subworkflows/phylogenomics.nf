/*
 *  Extract profile genes
 */


//// modules to import



workflow PHYLOGENOMICS {
    
    take:
    
    genomes
    custom_markers
    genomes_metadata

    main:


    //// conditional on presence/absense of custom marker input channel
    if (custom_markers) {

    }


    emit: 




}