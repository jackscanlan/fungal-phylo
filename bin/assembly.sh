#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = sample
# $3 = fwd_reads (one or more paths for fwd reads)
# $4 = rev_reads (one or more paths for rev reads)

module load SPAdes/3.15.5-GCC-12.3.0

spades.py \
    --pe-1 1 /group/pathogens/IAWS/Personal/Aimee/Error_correction/Output_EC/$i/corrected/$i\_L001_R1_clean.fastq.00.0_0.cor.fastq.gz \
    --pe-2 1 /group/pathogens/IAWS/Personal/Aimee/Error_correction/Output_EC/$i/corrected/$i\_L001_R2_clean.fastq.00.0_0.cor.fastq.gz \
    --pe-1 2 /group/pathogens/IAWS/Personal/Aimee/Error_correction/Output_EC/$i/corrected/$i\_L002_R1_clean.fastq.00.1_0.cor.fastq.gz \
    --pe-2 2 /group/pathogens/IAWS/Personal/Aimee/Error_correction/Output_EC/$i/corrected/$i\_L002_R2_clean.fastq.00.1_0.cor.fastq.gz \
    --threads 24 \
    --memory 550 \
    --only-assembler \
    -o .