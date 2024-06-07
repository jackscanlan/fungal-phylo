#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = sample
# $3 = fwd_reads (one or more paths for fwd reads)
# $4 = rev_reads (one or more paths for rev reads)
# $5 = unpaired_reads (one path)
# $6 = scaffolds (one path)
# $7 = threads
# $8 = genome_type


module load QUAST/5.0.2-foss-2018b-Python-2.7.15

## conditional if genome_type is "new" or "old"
# if assembly is new and therefore has reads associated
if [[ $8 == "new" ]]; then
    ## only use unpaired reads if they exist
    if [[ -z $(grep '[^[:space:]]' $5) ]]; then
        quast.py \
            $6 \
            -o . \
            --pe1 $3 \
            --pe2 $4 \
            --threads $7 \
            --fungus \
            --min-contig 100 \
            --split-scaffolds
    else 
        quast.py \
            $6 \
            -o . \
            --pe1 $3 \
            --pe2 $4 \
            --single $5 \
            --threads $7 \
            --fungus \
            --min-contig 100 \
            --split-scaffolds
    fi 
# if assembly is internal or external and therefore doesn't have reads associated
elif [[ $8 == "old" ]]; then
    quast.py \
    $6 \
    -o . \
    --threads $7 \
    --fungus \
    --min-contig 100 \
    --split-scaffolds
# throw error if 'genome_type' is not specified correctly
else
    echo "'genome_type' must be 'old' or 'new'!"
    exit 1
fi


### rename output files with unique names
cp transposed_report.tsv ${2}_report.tsv
cp basic_stats/Nx_plot.pdf ${2}_Nx_plot.pdf 
