#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = sample
# $3 = fwd_reads (one or more paths for fwd reads)
# $4 = rev_reads (one or more paths for rev reads)
# $5 = merged reads
# $6 = unpaired_reads (one path)
# $7 = scaffolds (one path)
# $8 = threads
# $9 = genome_type


module load QUAST/5.3.0-gfbf-2024a

## conditional if genome_type is "new" or "old"
# if assembly is new and therefore has reads associated
if [[ $9 == "new" ]]; then
    # if merged and unpaired are missing
    if [[ -z $(grep '[^[:space:]]' $5) && -z $(grep '[^[:space:]]' $6) ]]; then
        quast.py \
            $7 \
            -o . \
            --pe1 $3 \
            --pe2 $4 \
            --threads $8 \
            --fungus \
            --min-contig 100 \
            --split-scaffolds
    # if only merged missing
    elif [[ -z $(grep '[^[:space:]]' $5) ]]; then
        quast.py \
            $7 \
            -o . \
            --pe1 $3 \
            --pe2 $4 \
            --single $6 \
            --threads $8 \
            --fungus \
            --min-contig 100 \
            --split-scaffolds
    # if neither are missing
    else
        quast.py \
            $7 \
            -o . \
            --pe1 $3 \
            --pe2 $4 \
            --single $5 \
            --single $6 \
            --threads $8 \
            --fungus \
            --min-contig 100 \
            --split-scaffolds
    fi 
# if assembly is internal or external and therefore doesn't have reads associated
elif [[ $9 == "old" ]]; then
    quast.py \
    $7 \
    -o . \
    --threads $8 \
    --fungus \
    --min-contig 100 \
    --split-scaffolds
# throw error if 'genome_type' is not specified correctly
else
    echo "'genome_type' is '${9}' but must be 'old' or 'new'!"
    exit 1
fi


### rename output files with unique names
cp transposed_report.tsv ${2}_report.tsv
cp basic_stats/Nx_plot.pdf ${2}_Nx_plot.pdf 
