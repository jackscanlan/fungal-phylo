#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = profile_directory
# $3 = alignment_directory
# $4 = threads

# load shifter
module load shifter

# conditional to pull and convert Docker image or not
if shifterimg images | grep -q "endix1029/ufcg:v1.0.6"; then
    echo "Docker image already exists."
else 
    # pull docker image and convert
    shifterimg pull docker:endix1029/ufcg:v1.0.6
fi

# remove old alignments from output dir if present
rm -f ${3}/*

# run ufcg
shifter \
    --image=endix1029/ufcg:v1.0.6 \
    -- \
    ufcg align \
    -i $2 \
    -o . \
    -l label,acc \
    -t $4 \
    -a nucleotide \
    -f 50

# copy final alignments to output dir
cp align/* $3

