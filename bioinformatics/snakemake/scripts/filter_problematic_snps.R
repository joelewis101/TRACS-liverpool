#!/usr/bin/env Rscript

library(argparse)

parser <- ArgumentParser(description= 'Take a TSV of variants and filter for problematic SNPs based on spatial clustering. INDELS are ignored.')

parser$add_argument('--highQUAL_sites_file', '-v',required = TRUE,  help= 'input variant file as tsv (formatted as output from pipeline rule high_QUAL_var)')
parser$add_argument('--output-problem', '-p', required = TRUE, help= 'output problem snp file')
parser$add_argument('--output-filtered', '-f', required = TRUE, help= 'output filtered snp file')
parser$add_argument('--ref', '-r', required = TRUE, help= "reference fasta")

xargs<- parser$parse_args()


suppressMessages(library(dplyr))
suppressMessages(library(readr))
suppressMessages(library(stringr))
suppressMessages(library(tidyr))
suppressMessages(library(phylotools))
suppressMessages(library(purrr))
suppressMessages(library(zoo))


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

cat("Reading table of variants ", xargs$highQUAL_sites_file, "\n")

highqual_sites <- read_tsv(xargs$highQUAL_sites_file,
  col_names = c(
    "sample",
    "sequence_type",
    "gene",
    "pos",
    "ref",
    "alt",
    "type",
    "GT",
    "QUAL",
    "AO",
    "RO",
    "DP"
  ),
  show_col_types = FALSE
)

cat("Reading reference fasta ", xargs$ref,"\n")
ref <- phylotools::read.fasta(xargs$ref)

# highqual_sites <-
#   read_tsv(
#     "/Users/joseph.lewis/projects/TRACS/analysis/TRACS-liverpool/bioinformatics/snakemake/out/sweeps/PS-58_ST999/output_files/high_QUAL_variants.tsv",
#     col_names = c(
#       "sample",
#       "sequence_type",
#       "gene",
#       "pos",
#       "ref",
#       "alt",
#       "type",
#       "GT",
#       "QUAL",
#       "AO",
#       "RO",
#       "DP"
#     )
#   ) 
#
# ref <- phylotools::read.fasta("~/projects/TRACS/analysis/TRACS-liverpool/bioinformatics/snakemake/Reference.fasta")

ref_lengths <-
  ref |>
  transmute(
    gene = str_split(seq.name, " ")[[1]][1],
    length = str_length(seq.text)
  )

total_ref_length <- sum(ref_lengths$length)

cat("Reference contains", nrow(ref_lengths), "record(s)\n")
cat("Total reference length:", total_ref_length, "\n")
cat("Variant file contains", nrow(highqual_sites), "variants\n")

# ignore insertions, deletions
highqual_sites <-
  highqual_sites |>
  decompose_variants() |>
  filter(ref != alt, ref != "-", alt != "-")

total_number_of_snps <-
  highqual_sites |>
  nrow()

cat("Following decomposition and removal of indels,", total_number_of_snps, "SNPs remain\n")

window_size <- round(total_ref_length /total_number_of_snps,0)

cat("Rolling window size:", window_size, "\n")

threshold <- qbinom(0.05/total_ref_length, window_size, 1/window_size, lower.tail = FALSE)
cat("Threshold SNPs for defining problematic region: ", threshold, "\n")
cat("Applying rolling window ... ")

full_genome_snps <-
  ref_lengths |>
  group_by(gene) |>
  reframe(pos = 1:length) |>
  left_join(
    highqual_sites,
    by = join_by(gene == gene, pos == pos)
  ) |>
  ungroup() |>
  mutate(snp = if_else(is.na(alt), 0, 1)) |>
  group_by(gene, pos) |>
  summarise(snp = any(snp == 1), .groups = "keep") |>
  ungroup() |>
  mutate(
    n_snps_in_window =
      rollapply(snp, width = window_size, sum, partial = TRUE)
  )
cat("Done\n")

problematic_snps <-
  highqual_sites |>
  semi_join(
    full_genome_snps |>
      filter(n_snps_in_window >= threshold),
    by = join_by(gene == gene, pos == pos)
  )

cat("Identfied", problematic_snps |> nrow(), "problematic SNPs\n")

problem_snps_outfile <- paste0(gsub("\\.tsv","", xargs$highQUAL_sites_file), "problem_snps.tsv")

cat("Writing problematic SNPs to", xargs$output_problem,"...")
write_tsv(problematic_snps, xargs$output_problem)
cat("Done\n")

cat("Writing filtered SNPs to", xargs$output_filtered, "...")
write_tsv(
  highqual_sites |>
    anti_join(
      full_genome_snps |>
        filter(n_snps_in_window >= threshold),
      by = join_by(gene == gene, pos == pos)
    ),
  xargs$output_filtered
)
cat("Done\n")
cat("Finished.\n")
