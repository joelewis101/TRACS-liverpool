#!/usr/bin/env Rscript

library(argparse)
library(dplyr)
library(readr)
library(stringr)
library(tidyr)

parser <- ArgumentParser(description= 'Generate a list of sites to mask from depth, het sites and low QUAL sites')

parser$add_argument('--depth_file', '-d', help= 'samtools depth tsv')
parser$add_argument('--het_sites_file', '-s', help= 'het sites tsv')
parser$add_argument('--lowQUAL_sites_file', '-q', help= 'low qual sites tsv')
parser$add_argument('--output', '-o', help= 'output file')
parser$add_argument('--lowercutoff', '-l', help= 'lower depth cutoff', type= 'double')
parser$add_argument('--uppercutoff', '-u', help= 'upper depth cutoff', type= 'double')
parser$add_argument('--type', '-t', help= "picks|sweeps")

xargs<- parser$parse_args()


decompose_variants <- function(df) {
  df_nonsnps <-
    df |> filter(nchar(ref) > 1 | nchar(alt) > 1)
  df_out <-
    bind_rows(
      df_nonsnps |>
        ungroup() |>
        split(1:nrow(df_nonsnps)) |>
        map(split_variants) |>
        bind_rows() |>
        as.data.frame(),
      df |>
        filter(nchar(ref) == 1 & nchar(alt) == 1)
    )
  return(df_out)
}

split_variants <- function(row) {
  if (nrow(row) != 1) {
    stop("Tried to hand split_variants more than one row")
  }
  initpos <- row$pos
  row <-
    row |>
    mutate(
      alt = str_pad(
        alt, max(c(nchar(ref), nchar(alt))),
        side = "right", pad = "-"
      ),
      ref = str_pad(
        ref, max(c(nchar(ref), nchar(alt))),
        side = "right", pad = "-"
      )
    )
  row <-
    bind_cols(
      row |>
        mutate(alt = gsub("([ACTG-])(?=[ACTG-])", "\\1,", alt, perl = TRUE)) |>
        select(-c(pos, ref)) |>
        separate_longer_delim(alt, ","),
      row |>
        mutate(ref = gsub("([ACTG-])(?=[ACTG-])", "\\1,", ref, perl = TRUE)) |>
        select(ref) |>
        separate_longer_delim(ref, ",")
    )
  row <-
    bind_cols(
      row,
      pos = c(initpos:(initpos + nrow(row) - 1))
    )
  return(row)
}

cat("loading data\n")

het_sites <- read_tsv(xargs$het_sites_file, 
                      col_names = c("sample", "sequence_type", "gene", "pos", "ref", "alt", "type", "GT", "QUAL", "AO", "RO", "DP")
)

lowqual_sites <- read_tsv(xargs$lowQUAL_sites_file, 
                          col_names = c("sample", "sequence_type", "gene", "pos", "ref", "alt", "type", "GT", "QUAL", "AO", "RO", "DP")
)
depth <-  read_tsv(xargs$depth_file, 
                   col_names = c("sample", "sequence_type", "gene", "pos", "depth")
)

cat("generating mask file\n")
cat(paste0("using lower depth cutoff", xargs$lowercutoff, "\n"))
cat(paste0("using upper depth cutoff", xargs$uppercutoff, "\n"))
cat(paste0("sample type: ", xargs$type, "\n"))

if (xargs$type == "picks") {
  cat("including het variants and low qual variants in mask\n")
  sites_to_mask <-
    bind_rows(
      depth |>
        filter(depth > xargs$lowercutoff & depth < xargs$uppercutoff) |>
        select(-depth),
      # ignore deletions
      het_sites |>
        filter(ref != "-") |>
        select(sample, sequence_type, gene, pos),
      lowqual_sites |>
        filter(ref != "-") |>
        select(sample, sequence_type, gene, pos)
    ) |>
    arrange(sample, sequence_type, gene, pos) |>
    unique()
} else if (xargs$type == "sweeps") {
  cat("including low qual variants in mask\n")
  sites_to_mask <-
    bind_rows(
      depth |>
        filter(depth > xargs$lowercutoff & depth < xargs$uppercutoffppercutoff) |>
        select(-depth),
      # ignore deletions
      lowqual_sites |>
        filter(ref != "-") |>
        select(sample, sequence_type, gene, pos)
    ) |>
    arrange(sample, sequence_type, gene, pos) |>
    unique()
} else {
  stop("sample type must be one of pick or sweep")
}
cat(paste0("writing to ", xargs$output, "\n"))
write_tsv(sites_to_mask, xargs$output)
#
