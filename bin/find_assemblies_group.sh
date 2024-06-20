#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = params.ncbi_taxid
# $3 = params.limit_external



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
    --include genome \
    --assembly-source GenBank

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
### TODO: add N50 and assembly level in there to compare assemblies
### list of required elements:
# - 'Filename' (can get from file, don't extract)
# - 'Label' (.organism.organismName)
# - 'Accession' (.accession)
# - 'Taxon name' (.organism.organismName)
# - 'NCBI name' (.assemblyInfo.assemblyName)
# - 'Strain name' (.organism.infraspecificNames.strain)
# - 'Taxonomy' (probably can't get this)
# - contigN50 (.assemblyStats.contigN50)
# - contigL50 (.assemblyStats.contigL50)

# create .tsv
shifter \
    --image=ddev/ddev-utilities:latest \
    -- \
	jq -r \
    '[.organism.organismName, .accession, .organism.organismName, .assemblyInfo.assemblyName, .organism.infraspecificNames.strain, .organism.taxId, .assemblyStats.contigN50, .assemblyStats.contigL50 ] | @tsv' \
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

# check that no GCA or GCF accessions share the same code (as they are the same)
# if they do, subset to only keep GCF

# add headers to .tsv
HEADER="Label\tAccession\tTaxon name\tNCBI name\tStrain name\tTaxonomy\tcontigN50\tcontigL50"
echo -e "$HEADER" | cat - genomes_${2}_body.tsv > genomes_${2}.all.tsv


### TODO: if $3 (limit_external) is true, pare genomes down to one per 'Taxid' value
if [[ $3 == "true" ]]; then
    
    # conditional to pull and convert Docker image or not
    if shifterimg images | grep -q "rocker/tidyverse:4.4.0"; then
        echo "rocker/tidyverse Docker image already exists."
    else 
        # pull docker image and convert
        shifterimg pull docker:rocker/tidyverse:4.4.0
    fi

    # use R::tidyverse to subset data (could maybe do it in bash but complicated)
    shifter \
        --image=rocker/tidyverse:4.4.0 \
        -- \
        Rscript --vanilla \
        limit_external.R \
        genomes_${2}.all.tsv \
        genomes_${2}.tsv \
        genomes_cull.txt

    # remove assemblies in genomes_cull.txt


elif [[ $3 == "false" ]]; then
    # rename all file to output file
    mv genomes_${2}.all.tsv genomes_${2}.tsv
else 
    echo "$3 must be 'true' or 'false'."
    exit 1
fi

# pull genomes out of directory structure
while read i; do 
    mv ./genomes_${2}/ncbi_dataset/data/${i}/${i}* . 
done <genomes_${2}.lst
