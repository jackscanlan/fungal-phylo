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

Timing:
- Running on EPFG1 (~2.3GB of combined data) with 16 cpus, takes ~1.5 hour to get to the end of ERROR_CORRECTION
- Same data but 32 cpus, takes ~51 min to get to the end of ERROR_CORRECTION
- ASSEMBLY is very fast with 32 threads, so can afford to reduce this
    - took 22 min with 32 threads without `--careful`
    - took 55 min with 32 threads with `--careful`

### Current progress

- `COMBINE_LANES` concatenates input .fastq files that are split across multiple lanes (eg. two pairs of fwd and rev reads due to being sequenced on two lanes)
    - Tools used: none
- `READ_PREPROCESSING` discovers adapters by pair overlap, trims adapters, removes phiX spike-in contamination, and merges mergable paired-end reads (using `vstrict` option)
    - Tools used: `BBMap` (`bbmerge.sh` and `bbduk.sh`)
- `ERROR_CORRECTION` tries to correct errors in the reads (`--only-error-correction`)
    - If paired reads become unpaired due to rejection of one end, these get combined with the merged reads, if present, to produce a single 'single-end' .fastq for assembly
    - Tools used: `SPAdes`
- `ASSEMBLY` assembles a genome *de novo* (`--only-assembler`)
    - Uses `--careful` mode to polish scaffolds
    - Tools used: `SPAdes`
- `QUAST` assesses the quality of the genome assembly, optionally with a reference genome
    - Not sure the best genomes to use for most purposes, so ue of reference is not implemented yet

### Samplesheet notes

Workflow Groovy code currently parses the samplesheet like so:
- `sample` as the only meta field
- multiple paired read files can be specified with `fwd` and `rev` fields, with additional pairs specified like `fwd2`/`rev2`
    - Groovy code combines all keys with `fwd` together and the same with `rev`, creating comma-delimited lists that are parsed by `COMBINE_LANES` into a single pair of read files

Future samplesheet could have following:
- field that signifies if it is raw reads to be assembled into a genome, or an NCBI genome assembly that needs to be downloaded
    - perhaps `assembled` (`true`/`false`)
- taxonomic information 

Other inputs:
- list of genome accessions to run the UFCG pipeline on, in addition