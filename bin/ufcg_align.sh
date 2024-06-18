#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = threads

module load shifter

# conditional to pull and convert Docker image or not
if shifterimg images | grep -q "endix1029/ufcg:v1.0.5"; then
    echo "Docker image already exists."
else 
    # pull docker image and convert
    shifterimg pull docker:endix1029/ufcg:v1.0.5
fi

# run ufcg
shifter \
    --image=endix1029/ufcg:v1.0.5 \
    -- \
    ufcg align \
    -i ${1}/output/modules/ufcg_profile \
    -o . \
    -t $2 \
    -a nucleotide 


