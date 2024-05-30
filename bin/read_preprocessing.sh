#!/bin/bash
set -e
set -u
## args are the following:
# $1 = 
# $2 = 
# $3 = 
# $4 = 
# $5 = 
# $6 = 
# $7 = 
# $8 = 

module load BBMap/38.98-GCC-11.2.0

# repair reads that might be broken
repair.sh \
    in1=broken1.fq \
    in2=broken2 \
    out1=fixed1.fq \
    out2=fixed2.fq \
    outs=singletons.fq \
    repair

# adapter trimming (BBDuk)
bbduk.sh \
    in=reads.fq \
    in2= \
    out=clean.fq \
    ref=adapters.fa \
    ktrim=r \
    k=23 \
    mink=11 \
    hdist=1 \
    tpe \
    tbo

# contaminant filtering


# human contaminant removal


# paired-read merging

bbmerge.sh in=reads.fq outa=adapters.fa