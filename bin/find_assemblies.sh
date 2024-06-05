#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = params.ncbi_taxid



module load shifter

# conditional to pull and convert Docker image or not
if shifterimg images | grep -q "staphb/ncbi-datasets:16.15.0"; then
    echo "ncbi-datasets Docker image already exists."
else 
    # pull docker image and convert
    shifterimg pull docker:staphb/ncbi-datasets:16.15.0
fi

# retrieve data for specified taxon (params.ncbi_taxid)
shifter \
    --image=staphb/ncbi-datasets:16.15.0 \
    -- \
    datasets \
    download \
    genome \
    taxon $2 \
    --filename genomes_${2}.zip \
    --exclude-atypical \
    --include genome 

# unzip 
unzip genomes_${2}.zip -d genomes_${2}
rm genomes_${2}.zip

## parse json file with jq
# conditional to pull and convert Docker image or not
if shifterimg images | grep -q "ddev/ddev-utilities:latest"; then
    echo "ddev Docker image already exists."
else 
    # pull docker image and convert
    shifterimg pull docker:ddev/ddev-utilities:latest
fi

## use jq to extract relevant fields
# create .tsv
shifter \
    --image=ddev/ddev-utilities:latest \
    -- \
	jq -r \
    '[.organism.organismName, .accession, .assemblyInfo.assemblyName, .organism.taxId] | @tsv' \
	./genomes_${2}/ncbi_dataset/data/assembly_data_report.jsonl \
    > genomes_${2}_body.tsv

# create list of accessions
shifter \
    --image=ddev/ddev-utilities:latest \
    -- \
	jq -r \
    '.accession' \
	./genomes_${2}/ncbi_dataset/data/assembly_data_report.jsonl \
    > genomes_${2}.lst

# add headers to .tsv
HEADER="Label\tAccession\tTaxon name\tTaxid"
echo -e "$HEADER" | cat - genomes_${2}_body.tsv > genomes_${2}.tsv

# pull genomes out of directory structure
while read i; do 
       mv ./genomes_${2}/ncbi_dataset/data/${i}/${i}* . 
    done <genomes_${2}.lst
