#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = sample
# $3 = scaffolds
# $4 = threads

module load shifter

# conditional to pull and convert Docker image or not
if shifterimg images | grep -q "nextgenusfs/funannotate:v1.8.17"; then
    echo "Docker image already exists."
else 
    # pull docker image and convert
    shifterimg pull docker:nextgenusfs/funannotate:v1.8.17
fi

## rename scaffolds
# run funannotate sort
shifter \
    --image=nextgenusfs/funannotate:v1.8.17 \
    -- \
    funannotate sort \
    --input $3 \
    --out ${2}_scaffolds.sorted.fasta \
    --base scaffold \
    --minlen 500

## remove short (<500 bp) and/or duplicated contigs from assembly
# run funannotate clean
shifter \
    --image=nextgenusfs/funannotate:v1.8.17 \
    -- \
    funannotate clean \
    --input ${2}_scaffolds.sorted.fasta \
    --out ${2}_scaffolds.clean.fasta \
    --cpus ${4} \
    --pident 99 \
    --cov 99 \
    --minlen 500 

