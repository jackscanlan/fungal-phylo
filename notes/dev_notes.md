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
    nextflow run . -resume --samplesheet input/samplesheet_metatest.csv --ncbi_taxid 5529

Running with test data, testing basc_slurm:

    # start head job
    sinteractive -c2
    # load modules (Nextflow installed locally)
    module load Java/17.0.6
    # run 
    nextflow run . -profile basc_slurm -resume --samplesheet input/samplesheet_metatest.csv --ncbi_taxid 5529

Testing split samplesheet:

    export NXF_VER=23.05.0-edge

    rm -rf work/* output/*

    module load Java/17.0.6
    nextflow run . -profile basc_slurm -resume --samplesheet input/samplesheet_split_test.csv 

    # with single taxid
    nextflow run . -profile basc_slurm -resume --samplesheet input/samplesheet_split_test.csv --ncbi_taxid 5530

    # with multi taxid (no overlap)
    nextflow run . -profile basc_slurm -resume --samplesheet input/samplesheet_split_test.csv --ncbi_taxid 5530,568076
    
    # with multi taxid (overlap)
    nextflow run . -profile basc_slurm -resume --samplesheet input/samplesheet_split_test.csv --ncbi_taxid 5530,5529

    # Clavicipitaceae
    nextflow run . -profile basc_slurm -resume --samplesheet input/samplesheet_split_test.csv --ncbi_taxid 34397 

    # test with small samples
    nextflow run . -profile basc_slurm,test --samplesheet input/samplesheet_split_test.csv --ncbi_taxid 5530

Testing datasets and jq:

    mkdir -p ~/jq_test && cd ~/jq_test

    module load shifter

    shifter \
        --image=staphb/ncbi-datasets:16.15.0 \
        -- \
        datasets \
        download \
        genome \
        taxon 5529 \
        --filename genomes.zip \
        --exclude-atypical \
        --include genome \
        --assembly-source GenBank

    # unzip
    unzip genomes.zip

    # data is in jsonl file here: 'ncbi_dataset/data/assembly_data_report.jsonl'

    # use jq
    shifter \
        --image=ddev/ddev-utilities:latest \
        -- \
        jq . \
        ncbi_dataset/data/assembly_data_report.jsonl \
        > assembly_data_report.txt

    # pull data
    shifter \
        --image=ddev/ddev-utilities:latest \
        -- \
        jq -r \
        '[.organism.organismName, .accession, .organism.organismName, .assemblyInfo.assemblyName, .organism.infraspecificNames.strain, .organism.taxId, .assemblyStats.contigN50, .assemblyStats.contigL50 ] | @tsv' \
        ncbi_dataset/data/assembly_data_report.jsonl \
        > body.tsv


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

Subworkflow '
- `FIND_ASSEMBLIES` finds and downloads genome assembly accessions in NCBI within a specified taxonomic group
    - Tools used: `datasets` to download assemblies from NCBI and `jq` to parse the JSON output to produce a metadata .tsv


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