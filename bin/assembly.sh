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
# $7 = threads

module load SPAdes/4.0.0-GCC-13.3.0

## only use merged and/or unpaired reads if they exist
# if merged and unpaired is empty
if [[ -z $(grep '[^[:space:]]' $5) && -z $(grep '[^[:space:]]' $6) ]]; then
    spades.py \
        -1 $3 \
        -2 $4 \
        --threads $7 \
        --memory 550 \
        --only-assembler \
        --careful \
        -o .
# if only merged is empty
elif [[ -z $(grep '[^[:space:]]' $5) ]]; then
    spades.py \
        -1 $3 \
        -2 $4 \
        -s $6 \
        --threads $7 \
        --memory 550 \
        --only-assembler \
        --careful \
        -o .
# if only unpaired is empty
else 
    spades.py \
        -1 $3 \
        -2 $4 \
        --merged $5 \
        --threads $7 \
        --memory 550 \
        --only-assembler \
        --careful \
        -o .
fi

# create scaffold file with unique name
cp scaffolds.fasta ${2}_scaffolds.fasta

# create log file with unique name
cp spades.log ${2}_assembly.log