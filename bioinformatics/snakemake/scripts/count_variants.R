#!/usr/bin/env Rscript

suppressMessages(library(argparse))
suppressMessages(library(dplyr))
suppressMessages(library(readr))
suppressMessages(library(tidyr))

options(dplyr.summarise.inform = FALSE)

parser <- ArgumentParser(description= 'Count variant differences between picks and sweep')
parser$add_argument('--pick_vs_sweep_variants', '-i', help= 'pick vs sweep variant file')
parser$add_argument('--output', '-o', help= 'output file')

cat("Running count_variants...\n")
xargs<- parser$parse_args()

cat("Loading", xargs$pick_vs_sweep_variants, "\n")
pick_vs_sweep_variants <-
  read_tsv(xargs$pick_vs_sweep_variants, show_col_types = FALSE)

pick_vs_sweep_variants <- pick_vs_sweep_variants %>%
  mutate(Method = case_when(
    is.na(alt_sweep) ~ "Pick only",
    is.na(alt_pick) ~ "Sweep only",
    alt_pick == alt_sweep ~ "Both agree",
    alt_pick != alt_sweep & !is.na(alt_pick) & !is.na(alt_sweep) ~ "Different SNV at same site"))

variant_count <- pick_vs_sweep_variants %>% count(Method)

cat(paste0("writing to ", xargs$output, "\n"))
write_tsv(variant_count, xargs$output)
#
