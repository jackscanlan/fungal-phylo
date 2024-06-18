#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir
# $2 = sample
# $3 = fwd_reads (.fastq.gz)
# $4 = rev_reads (.fastq.gz)
# $5 = merged_reads (.fastq.gz)
# $6 = threads 
# $7 = 
# $8 = 

module load SPAdes/3.15.5-GCC-12.3.0

## only use merged reads if they exist
if [[ -z $(grep '[^[:space:]]' $5) ]]; then
    # merged reads file is empty or contains only whitespace
    spades.py \
        -1 $3 \
        -2 $4 \
        --threads $6 \
        --memory 480 \
        --only-error-correction \
        -o .
else 
    # merged reads file is not empty
    spades.py \
        -1 $3 \
        -2 $4 \
        --merged $5 \
        --threads $6 \
        --memory 480 \
        --only-error-correction \
        -o .
fi 

# define output files that only sometimes get created
OUT_MERGED="./corrected/${2}_merged.fastq.00.0_1.cor.fastq.gz"
OUT_UNPAIRED0="./corrected/${2}_unmerged_R_unpaired.00.0_0.cor.fastq.gz"
OUT_UNPAIRED1="./corrected/${2}_unmerged_R_unpaired.00.0_1.cor.fastq.gz"

# if any don't exist, create them with 'touch'
if [[ ! -f $OUT_MERGED ]]; then
    touch $OUT_MERGED
fi
if [[ ! -f $OUT_UNPAIRED0 ]]; then
    touch $OUT_UNPAIRED0
fi
if [[ ! -f $OUT_UNPAIRED1 ]]; then
    touch $OUT_UNPAIRED1
fi

# concatenate unpaired files
cat $OUT_UNPAIRED0 $OUT_UNPAIRED1 > ${2}_unpaired.cor.fastq.gz

# copy and rename paired output files
cp ./corrected/${2}_unmerged_R1.fastq.00.0_0.cor.fastq.gz ${2}_R1.cor.fastq.gz 
cp ./corrected/${2}_unmerged_R2.fastq.00.0_0.cor.fastq.gz ${2}_R2.cor.fastq.gz 
cp $OUT_MERGED ${2}_merged.cor.fastq.gz




