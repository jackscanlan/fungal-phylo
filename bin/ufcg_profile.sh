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
    ufcg profile \
    --info ${3},${2},${2} \
    -i ${3} \
    -o . \
    -t $4 \
    --set PRO \
    -f 

