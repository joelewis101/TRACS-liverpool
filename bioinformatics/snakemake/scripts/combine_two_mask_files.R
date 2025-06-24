#!/usr/bin/env Rscript

library(argparse)
suppressMessages(library(dplyr))
suppressMessages(library(readr))

parser <- ArgumentParser(description= 'Combine two mask files and deduplicate')

parser$add_argument('--file_a', '-a', help= 'file a')
parser$add_argument('--file_b', '-b', help= 'file b')
parser$add_argument('--output', '-o', help= 'output')

xargs<- parser$parse_args()


a <- read_tsv(xargs$file_a, show_col_types = FALSE)
b <- read_tsv(xargs$file_b, show_col_types = FALSE)

write_tsv(
  bind_rows(
    a |>
      select(sample, sequence_type, gene, pos),
    b |>
      select(sample, sequence_type, gene, pos)
  ) |>
    unique() |>
    arrange(gene,pos),
  xargs$output
)

