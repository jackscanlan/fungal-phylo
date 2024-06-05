#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 



module load shifter

# conditional to pull and convert Docker image or not
if shifterimg images | grep -q "ncbi/edirect:20.6"; then
    echo "Docker image already exists."
else 
    # pull docker image and convert
    shifterimg pull docker:ncbi/edirect:20.6
fi

# run entrez tools
shifter \
    --image=ncbi/edirect:20.6 \
    -- \

