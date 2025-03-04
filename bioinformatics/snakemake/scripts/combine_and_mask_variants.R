#!/usr/bin/env Rscript

library(argparse)

parser <- ArgumentParser(description= 'Concatenate all pick variant files by searching recursively in a given directoty')

parser$add_argument('--pick_variants', '-p', help= 'pick variant file')
parser$add_argument('--sweep_variants', '-s', help= 'sweep variant file')
parser$add_argument('--mask', '-m', help=  'mask file')
parser$add_argument('--output', '-o', help= 'output file')

xargs<- parser$parse_args()

suppressMessages(library(dplyr))
suppressMessages(library(readr))
suppressMessages(library(stringr))
suppressMessages(library(tidyr))
suppressMessages(library(purrr))

pick_vars <-
  read_tsv(xargs$pick_variants)

sweep_vars <-
  read_tsv(xargs$sweep_variants)

mask <-
  read_tsv(xargs$mask)


df_out <-
  full_join(
    pick_vars |>
      # ignore insertions, deletions
      filter(ref != alt, ref != "-", alt != "-") |>
      anti_join(
        mask,
        by = join_by(gene == gene, pos == pos)
      ),
    sweep_vars |>
      filter(ref != alt, ref != "-", alt != "-") |>
      anti_join(
        mask,
        by = join_by(gene == gene, pos == pos)
      ),
    by = join_by(gene == gene, pos == pos, ref == ref),
    suffix = c("_pick", "_sweep")
  )



cat(paste0("writing to ", xargs$output, "\n"))
write_tsv(df_out, xargs$output)
#
