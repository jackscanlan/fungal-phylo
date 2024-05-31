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


module load QUAST/5.0.2-foss-2018b-Python-2.7.15

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