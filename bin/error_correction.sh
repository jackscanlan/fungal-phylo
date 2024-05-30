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

spades.py \
    -1 $3 \
    -2 $4 \
    -s $5 \
    --threads 24 \
    --memory 480 \
    --only-error-correction \
    -o .