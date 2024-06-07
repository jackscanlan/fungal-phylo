#!/usr/bin/env Rscript

# test if there is at least one argument: if not, return an error
if (!length(args)==3) {
  stop("Two arguments must be supplied (input file; output file; cull file).n", call.=FALSE)
} 

# load tidyverse
library(tidyverse)

# load .tsv
genomes <- readr::read_tsv(args[1])

#
genomes %>% 
    dplyr::group_by()