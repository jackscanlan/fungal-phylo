#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = sample
# $3 = fwd_reads (one or more paths for fwd reads)
# $4 = rev_reads (one or more paths for rev reads)

#### if reads are split across multiple lanes, merge them together; else just rename

## concatenate fwd reads
# convert commas to new lines in input string
FWD_READS_FILES=$(sed 's#,#\n#g' <<< $3)
# append projectDir at the start of each new line to produce absolute file paths
FWD_READS_FILES=$(sed "s#^#${1}/#g" <<< "${FWD_READS_FILES}")
# convert new lines to tabs for use with cat
FWD_READS_FILES=$(sed "s#/\n#\t#g" <<< "${FWD_READS_FILES}")
# concatenate files into a single file
cat $FWD_READS_FILES > ${2}_R1.fastq.gz

## concatenate rev reads
# convert commas to new lines in input string
REV_READS_FILES=$(sed 's#,#\n#g' <<< $4)
# append projectDir at the start of each new line to produce absolute file paths
REV_READS_FILES=$(sed "s#^#${1}/#g" <<< "${REV_READS_FILES}")
# convert new lines to tabs for use with cat
REV_READS_FILES=$(sed "s#/\n#\t#g" <<< "${REV_READS_FILES}")
# concatenate files into a single file
cat $REV_READS_FILES > ${2}_R2.fastq.gz

### TODO: make conditional code for handling uncompressed inputs, 
###       as well as input file paths that are already absolute 