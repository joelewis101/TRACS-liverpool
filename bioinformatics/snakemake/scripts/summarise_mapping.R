#!/usr/bin/env Rscript

library(argparse)

parser <- ArgumentParser(description= 'Summarise mapping stats')
parser$add_argument('--samtools_depth', '-s', help= 'samtools depth file')
parser$add_argument('--het_variants', '-he', help= 'het variants file')
parser$add_argument('--problem_snps', '-p', help= 'problem snps (from sliding window)')
parser$add_argument('--high_qual_snps_unfilt', '-hqu', help= 'high qual snps unfiltered')
parser$add_argument('--high_qual_snps_filt', '-hqf', help= 'high qual snps filtered')
parser$add_argument('--low_qual_snps', '-lq', help= 'low qual snps')
parser$add_argument('--output', '-o', help= 'output file')

xargs<- parser$parse_args()

suppressMessages(library(dplyr))
suppressMessages(library(readr))
suppressMessages(library(tidyr))
options(dplyr.summarise.inform = FALSE)

    col_names <- c("sample", "sequence_type", "gene", "pos", "ref", "alt", "type", "GT", "QUAL", "AO", "RO", "DP")

cat("\nTRACS pipeline variant summary script.\n")

cat(paste0("Loading samtools depth file: ", xargs$samtools_depth, "\n"))
df_samtools <-
  read_tsv(xargs$samtools_depth, show_col_types = FALSE, 
  col_names = c("sample", "sequence_type", "gene", "pos", "dep")
)

cat(paste0("Loading het variants file: ", xargs$het_variants, "\n"))
df_hetvar <-
  read_tsv(xargs$het_variants,
    show_col_types = FALSE,
    col_names = col_names
  )

cat(paste0("Loading highqual snps file (unfiltered): ", xargs$high_qual_snps_unfilt, "\n"))
df_high_qual_snps_unfilt <-
  read_tsv(xargs$high_qual_snps_unfilt,
    show_col_types = FALSE,
    col_names = col_names
  )

cat(paste0("Loading highqual snps file (filtered): ", xargs$high_qual_snps_filt, "\n"))
df_high_qual_snps_filt <-
  read_tsv(xargs$high_qual_snps_filt,
    show_col_types = FALSE,
    col_names = col_names
    )

cat(paste0("Loading low_qual_snps: ", xargs$low_qual_snps, "\n"))
df_low_qual_snps <-
  read_tsv(xargs$low_qual_snps,
    show_col_types = FALSE,
    col_names = col_names
    )

cat(paste0("Loading problem snps file: ", xargs$problem_snps, "\n"))
df_problem <-
  read_tsv(xargs$problem_snps,
    show_col_types = FALSE,
  )

df_out <-
  df_samtools |>
  group_by(sample, sequence_type, gene) |>
  summarise(
    mapped = sum(dep > 0),
    unmapped = sum(dep == 0),
    samtools_lowcov = sum(dep < 20)
  ) |>
  left_join(
    df_hetvar |>
      group_by(sample, sequence_type, gene) |>
      summarise(
        het_var = n()
      ),
    by = join_by(sample, sequence_type, gene)
  ) |>
  left_join(
    df_high_qual_snps_unfilt |>
      group_by(sample, sequence_type, gene) |>
      summarise(
        high_qual_var = n()
      ) |>
      left_join(
        df_low_qual_snps |>
          group_by(sample, sequence_type, gene) |>
          summarise(
            low_qual_var = n()
          ),
        by = join_by(sample, sequence_type, gene)
      ) |>
      mutate(variants = high_qual_var + low_qual_var),
    by = join_by(sample, sequence_type, gene)
  ) |>
  left_join(
    df_problem |>
      group_by(sample, sequence_type, gene) |>
      summarise(
        sliding_window_problem_snps = n()
      ),
    by = join_by(sample, sequence_type, gene)
  ) |>
  select(sample, sequence_type, gene, mapped, unmapped, samtools_lowcov, variants, het_var, low_qual_var, sliding_window_problem_snps)


cat(paste0("Writing output tsv: ", xargs$output, "\n"))
write_tsv(df_out, xargs$output)

