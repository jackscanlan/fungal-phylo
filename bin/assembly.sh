#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = sample
# $3 = fwd_reads (one or more paths for fwd reads)
# $4 = rev_reads (one or more paths for rev reads)
# $5 = unpaired_reads (one path)
# $6 = threads

module load SPAdes/3.15.5-GCC-12.3.0

## only use unpaired reads if they exist
if [[ -z $(grep '[^[:space:]]' $5) ]]; then
    # unpaired reads file is empty or contains only whitespace
    spades.py \
        -1 $3 \
        -2 $4 \
        --threads $6 \
        --memory 550 \
        --only-assembler \
        --careful \
        -o .
else
    # unpaired reads file is not empty
    spades.py \
        -1 $3 \
        -2 $4 \
        -s $5 \
        --threads $6 \
        --memory 550 \
        --only-assembler \
        --careful \
        -o .
fi

# create scaffold file with unique name
cp scaffolds.fasta ${2}_scaffolds.fasta

# create log file with unique name
cp spades.log ${2}_assembly.log