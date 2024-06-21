#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = alignment_dir
# $3 = threads

### copy alignment directory to current directory
cp -r $2 ./alignments_local

### remove alignment files if they contain less than 3 sequences
# list files in './alignments_local'
ALIGNMENTS_LIST=$( ls ./alignments_local )
# remove files that contain 3 or fewer sequences
for i in $ALIGNMENTS_LIST; do
    if [[ "$(grep -o '>' ./alignments_local/$i | wc -l)" -lt "4" ]]; then
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
    -T AUTO \
    -keep-ident

# make loci-specific trees
shifter \
    --image=staphb/iqtree2:2.3.4 \
    -- \
    iqtree2 \
    -S ./alignments_local \
    --prefix loci \
    -T AUTO

# calculate gene concondance factor (gCF) 
shifter \
    --image=staphb/iqtree2:2.3.4 \
    -- \
    iqtree2 \
    -t concat.treefile \
    --gcf loci.treefile \
    --prefix gcf \
    -T $3

# calculate site concordance factor (sCF)
shifter \
    --image=staphb/iqtree2:2.3.4 \
    -- \
    iqtree2 \
    -te concat.treefile \
    -p ./alignments_local \
    --scfl 100 \
    --prefix scf \
    -T $3