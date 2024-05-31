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

# output is in "corrected" dir in work directory
# for merged + unmerged paired input, you'll get four output files:
# - "${2}_merged.fastq.00.0_1.cor.fastq.gz"
# - "${2}_unmerged_R_unpaired.00.0_1.cor.fastq.gz"
# - "${2}_unmerged_R1.fastq.00.0_0.cor.fastq.gz"
# - "${2}_unmerged_R2.fastq.00.0_0.cor.fastq.gz"
# first and second can be concantenated to produce a single unpaired output file

## concatenate unpaired output files
OUT_MERGED="./corrected/${2}_merged.fastq.00.0_1.cor.fastq.gz"
OUT_UNPAIRED="./corrected/${2}_unmerged_R_unpaired.00.0_1.cor.fastq.gz"

# if both files exist, concatenate them
if [[ -f $OUT_MERGED && -f $OUT_UNPAIRED ]]; then
    cat $OUT_MERGED $OUT_UNPAIRED > ${2}_single.cor.fastq.gz
# if only merged file exists, create copy with output name
elif [[ -f $OUT_MERGED ]]; then
    cp $OUT_MERGED ${2}_single.cor.fastq.gz 
# if only unpaired file exists, create copy with output name
elif [[ -f $OUT_UNPAIRED ]]; then
    cp $OUT_UNPAIRED ${2}_single.cor.fastq.gz 
else 
    echo "Cannot find expected unpaired read files after error correction for sample ${2}!"
    exit 1
fi





