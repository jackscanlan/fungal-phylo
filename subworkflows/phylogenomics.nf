/*
 *  Extract profile genes, align and build trees
 */


//// modules to import
include { UFCG_PROFILE                                     } from '../modules/ufcg_profile'
include { UFCG_ALIGN                                     } from '../modules/ufcg_align'
include { BUILD_TREE                                     } from '../modules/build_tree'



workflow PHYLOGENOMICS {
    
    take:
    
    genomes
    custom_markers
    genomes_metadata

    main:


    //// conditional on presence/absense of custom marker input channel
    if ( custom_markers ) {

    }

    //// run ufcg profile to extract profiles 
    UFCG_PROFILE ( genomes )

    //// produce ready signal for UFCG_ALIGN
    UFCG_PROFILE.out.ready_signal
        .collect()
        .flatten()
        .unique()
        .set { ch_ready }

    //// run ufcg align to align sequences from profiles
    UFCG_ALIGN ( ch_ready )

    //// build phylogenetic tree
    BUILD_TREE ( UFCG_ALIGN.out.alignment_dir )

    emit: 

    UFCG_PROFILE.out.ucg



}