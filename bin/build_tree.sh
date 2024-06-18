#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = threads
# $3 = alignment_dir


### copy alignment directory to current directory
cp -r $3 ./alignments_local

### remove alignment files if they contain less than 3 sequences
# list files in './alignments_local'
ALIGNMENTS_LIST=$( ls ./alignments_local )
# remove files that contain 2 or fewer sequences
for i in $ALIGNMENTS_LIST; do
    if [[ $(grep -o '>' ./alignments_local/$i | wc -l) < 3 ]]; then
        rm ./alignments_local/$i
        echo "*** Removed alignment file $i as < 3 sequences ***"
    fi
done

### do phylogenetics
module load shifter

# conditional to pull and convert Docker image or not
if shifterimg images | grep -q "staphb/iqtree2:2.3.4"; then
    echo "Docker image already exists."
else 
    # pull docker image and convert
    shifterimg pull docker:staphb/iqtree2:2.3.4
fi

## following this: http://www.iqtree.org/doc/Concordance-Factor

# produce concat alignment, make partition file, make tree for concat
shifter \
    --image=staphb/iqtree2:2.3.4 \
    -- \
    iqtree2 \
    -p ./alignments_local \
    --prefix concat \
    -B 1000 \
    -T $2 \
    -keep-ident

# make loci-specific trees
shifter \
    --image=staphb/iqtree2:2.3.4 \
    -- \
    iqtree2 \
    -S ./alignments_local \
    --prefix loci \
    -T $2

# calculate gene concondance factor (gCF) 
shifter \
    --image=staphb/iqtree2:2.3.4 \
    -- \
    iqtree2 \
    -t concat.treefile \
    --gcf loci.treefile \
    --prefix concord \
    -T $2

# calculate site concordance factor (sFC)
shifter \
    --image=staphb/iqtree2:2.3.4 \
    -- \
    iqtree2 \
    -te concat.treefile \
    -p ./alignments_local \
    --scfl 100 \
    --prefix concord2 \
    -T $2