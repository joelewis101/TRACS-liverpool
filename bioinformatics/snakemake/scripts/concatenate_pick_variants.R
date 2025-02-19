#!/usr/bin/env Rscript

library(argparse)

parser <- ArgumentParser(description= 'Concatenate all pick variant files by searching recursively in a given directoty')

parser$add_argument('--directory', '-d', help= 'directory to look in')
parser$add_argument('--file', '-f', help= 'file name to find')
parser$add_argument('--output', '-o', help= 'output file')

xargs<- parser$parse_args()

suppressMessages(library(dplyr))
suppressMessages(library(readr))
suppressMessages(library(stringr))
suppressMessages(library(tidyr))
suppressMessages(library(purrr))



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
cat(paste0("looking in directory ", xargs$directory, " for files ", xargs$file, "\n"))

files <- list.files(xargs$directory, pattern = xargs$file, recursive = TRUE)
cat("Found:\n")
print(files)

out_df <-
map(paste0(xargs$directory,"/",files),
  \(x) decompose_variants(
    read_tsv(x,
    col_names = c("sample", "gene", "pos", "ref", "alt", "type", "GT", "QUAL", "AO", "RO", "DP")
  ))
) |>
  bind_rows() |>
  select(sample, gene, pos, ref, alt) |>
  group_by(gene,pos, ref, alt) |>
  summarise(samples = paste(sample, collapse = ",")) 

cat(paste0("writing to ", xargs$output, "\n"))
write_tsv(out_df, xargs$output)
#
