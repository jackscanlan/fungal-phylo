#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir
# $2 = tsvs

### handle list of .tsvs
TSV_LIST=$( echo $2 | tr -d '[] ' | sed 's#,#\n#g')



## remove header
for i in $TSV_LIST; do 
    cp $i . 
done

## concat files

## remove duplicate lines with 'sort'
sort -u myfile.csv -o myfile.csv

## append header