#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = sample
# $3 = scaffolds
# $4 = metadata
# $5 = profile_directory
# $6 = threads

module load shifter

# conditional to pull and convert Docker image or not
if shifterimg images | grep -q "endix1029/ufcg:v1.0.6"; then
    echo "Docker image already exists."
else 
    # pull docker image and convert
    shifterimg pull docker:endix1029/ufcg:v1.0.6
fi

# convert symlink to absolute path because ufcg can't handle symlink for metadata file for some reason
META_PATH=$(readlink ${4} -fn)

# run ufcg profile
shifter \
    --image=endix1029/ufcg:v1.0.6 \
    -- \
    ufcg profile \
    --input $3 \
    --metadata $META_PATH \
    --output . \
    -t $6 \
    --set PRO \
    -f \
    -w /tmp/${2} \
    --nocolor \
    -v

# copy final file to output dir
cp *.ucg $5
