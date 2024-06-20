#!/bin/bash
set -e
set -u
## args are the following:
# $1 = projectDir
# $2 = channel_data
# $3 = file_type
# $4 = header
# $5 = file_name (without extension)


### $2 (channel_data) is a nested groovy list: each element is in [] and the whole list is in [], items separated by comma and quoted in ''

### $3 (file_type) is 'csv' or 'tsv', indicating the type of file to be produced

### $4 (header) is a comma-separated header string

if [[ $3 == "csv" ]]; then

    HEADER="${4}"

    # remove leading '[[' and trailing ']]', convert '], [' to new lines, remove whitespace around commas
    echo $2 \
        | sed -E 's/^\[\[//' \
        | sed -E 's/\]\]$//' \
        | sed -E 's/\], \[/\n/g' \
        | sed -E 's/\s?,\s?/,/g' \
        > body.${3}

    # append header
    echo "$HEADER" | cat - body.${3} > ${5}.${3}

elif [[ $3 == "tsv" ]]; then

    # convert commas in header to \t
    HEADER=$( echo "${4}" | sed 's/,/\t/g' )

    # remove leading '[[' and trailing ']]', convert '], [' to new lines, remove whitespace around commas then conver to tabs
    echo $2 \
        | sed -E 's/^\[\[//' \
        | sed -E 's/\]\]$//' \
        | sed -E 's/\], \[/\n/g' \
        | sed -E 's/\s?,\s?/\t/g' \
        > body.${3}

    # append header
    echo "$HEADER" | cat - body.${3} > ${5}.${3}

else 
    echo "file_type was ${3}, but must be 'csv' or 'tsv'"
    exit 1
fi


