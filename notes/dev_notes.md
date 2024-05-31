# Development notes for `fungal-phylo` 

Test data: 

    # copy data for isolate EPFG1 (two pairs of files)
    cp /group/sequencing/230328_A00878_0090_AHLVKMDRX2/Unaligned-double10/Project_PATHOGENS/*EPFG1/* ./data


Running with test data:

    # load cpus
    sinteractive -c16
    # load modules (Nextflow installed locally)
    module load Java/17.0.6
    # run nextflow
    nextflow run . -resume --samplesheet input/samplesheet_test.csv

Running on EPFG1 (~2.3GB of combined data), takes ~1 hour to get to the end of ERROR_CORRECTION
