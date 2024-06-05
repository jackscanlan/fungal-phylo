# Development notes for `fungal-phylo` 

Test data: 

    # copy data for isolate EPFG1 (two pairs of files)
    cp /group/sequencing/230328_A00878_0090_AHLVKMDRX2/Unaligned-double10/Project_PATHOGENS/*EPFG1/* ./data


Running with test data:

    # load cpus
    sinteractive -c16
    # load modules (Nextflow installed locally)
    module load Java/17.0.6
    # run nextflow one one sample
    nextflow run . -resume --samplesheet input/samplesheet_test.csv
    # run nextflow on three samples
    nextflow run . -resume --samplesheet input/samplesheet_metatest.csv


    ## testing ufcg
    module load shifter
    shifter --image=endix1029/ufcg:v1.0.5 -- ufcg --help


    ## testing entrez retrieval with metarhizium (whole genus is ID 5529)
    nextflow run . -resume --samplesheet input/samplesheet_metatest.csv --ncbi_taxid 5530


Total data:

    # put data in `/home/js7t/personal/fungal-phylo/raw_data/aimee_epf/reads`
    while read i; do 
       cp $i . 
    done <reads.lst


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
- `CLEAN_ASSEMBLY` to clean assemblies of duplicated scaffolds/contigs, and rename sequences
    - Starting from the shortest scaffold, removes a scaffold if >=99% of the length has >=99% identity to a larger scaffold. Removes all scaffolds <500bp in length
    - Renames all scaffolds to the form "scaffold_1", starting with the longest scaffold
    - Tools used: `funannotate`
- `QUAST` assesses the quality of the genome assembly, optionally with a reference genome
    - Not sure the best genomes to use for most purposes, so ue of reference is not implemented yet
    - TODO: rename to  `QUAST_NEW` as it only gets used for new genomes
- `UFCG_PROFILE` runs `ufcg profile` using container on a single sample, pulling out default core genes

### To-add


- `FIND_ASSEMBLIES` finds genome assembly accessions in NCBI within a specified taxonomic group
- `RETRIEVE_ASSEMBLIES` retrieves genome assemblies from NCBI based on a list of accessions
    - Tools used: `entrezdirect` (`entrezdirect/13.1.20200107-GCCcore-8.2.0` in BASC)
        - or use official NCBI Docker image: https://github.com/ncbi/docker/tree/master/edirect 
- `UFCG_METADATA` creates a .tsv file of metadata for the UFCG pipeline
    - Tools used: probably just `bash` 
- `QUAST_EXISTING` runs `quast` on genomes that were not assembled using this pipeline
- `ASSEMBLY_VIZ` uses outputs from `quast` processes to produce plots comparing the contiguity and quality of your new genomes and your supplied genomes



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