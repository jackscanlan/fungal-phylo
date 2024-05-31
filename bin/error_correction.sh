#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir
# $2 = sample
# $3 = fwd_reads (.fastq.gz)
# $4 = rev_reads (.fastq.gz)
# $5 = merged_reads (.fastq.gz)
# $6 = 
# $7 = 
# $8 = 

module load SPAdes/3.15.5-GCC-12.3.0

## only use merged reads if they exist
if [[ -z $(grep '[^[:space:]]' $5) ]]; then
    # merged reads file is empty or contains only whitespace
    spades.py \
        -1 $3 \
        -2 $4 \
        --threads 16 \
        --memory 480 \
        --only-error-correction \
        -o .
else 
    # merged reads file is not empty
    spades.py \
        -1 $3 \
        -2 $4 \
        -s $5 \
        --threads 16 \
        --memory 480 \
        --only-error-correction \
        -o .
fi 