#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir 
# $2 = sample (accession)


### remove square brackets from sample
SAMPLE=$( echo $2 | tr -d '[],' )



module load shifter

# conditional to pull and convert Docker image or not
if shifterimg images | grep -q "staphb/ncbi-datasets:16.15.0"; then
    echo "ncbi-datasets Docker image already exists."
else 
    # pull docker image and convert
    shifterimg pull docker:staphb/ncbi-datasets:16.15.0
fi

# retrieve data for specified genome accession
shifter \
    --image=staphb/ncbi-datasets:16.15.0 \
    -- \
    datasets \
    download \
    genome \
    accession $SAMPLE \
    --filename genome_${SAMPLE}.zip \
    --include genome \
    --assembly-source GenBank

# unzip 
unzip genome_${SAMPLE}.zip -d genome_${SAMPLE}
rm genome_${SAMPLE}.zip

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
# create .tsv
shifter \
    --image=ddev/ddev-utilities:latest \
    -- \
	jq -r \
    '[.organism.organismName, .accession, .organism.organismName, .assemblyInfo.assemblyName, .organism.infraspecificNames.strain, .organism.taxId, .assemblyStats.contigN50, .assemblyStats.contigL50 ] | @tsv' \
	./genome_${SAMPLE}/ncbi_dataset/data/assembly_data_report.jsonl \
    > genome_${SAMPLE}_body.tsv


# add headers to .tsv
HEADER="Label\tAccession\tTaxon name\tNCBI name\tStrain name\tTaxonomy\tcontigN50\tcontigL50"
echo -e "$HEADER" | cat - genome_${SAMPLE}_body.tsv > genome_${SAMPLE}.tsv

# pull genome out of directory structure
mv ./genome_${SAMPLE}/ncbi_dataset/data/${SAMPLE}/${SAMPLE}* . 

