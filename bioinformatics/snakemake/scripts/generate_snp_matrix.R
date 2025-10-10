#!/usr/bin/env Rscript

suppressMessages(library(argparse))

parser <- ArgumentParser(description= 'Take the pick_vs_sweep_variants.tsv file and generate a pairwise snp matrix')
parser$add_argument('--pick_vs_sweep_variants', '-i', help= 'pick vs sweep variant file')
parser$add_argument('--output', '-o', help= 'output file')

xargs<- parser$parse_args()

suppressMessages(library(dplyr))
suppressMessages(library(readr))
suppressMessages(library(tidyr))
options(dplyr.summarise.inform = FALSE)

cat(paste0("\nLoading ", xargs$pick_vs_sweep_variants, "\n"))
df <-
  read_tsv(xargs$pick_vs_sweep_variants, show_col_types = FALSE)
cat("\nGenerating pairwise SNP matrix\n")


# generate df of all snps from the masked pick and sweep variants
df2 <-
  bind_rows(
    df |>
      transmute(
        gene = gene,
        pos = pos,
        ref = ref,
        alt = alt_pick,
        sample = samples_pick
      ) |>
      separate_longer_delim(
        delim = ",",
        cols = "sample"
      ) |>
      filter(!is.na(alt)) |>
      unique(),
    df |>
      transmute(
        gene = gene,
        pos = pos,
        ref = ref,
        alt = alt_sweep,
        sample = samples_sweep
      ) |>
      separate_longer_delim(
        delim = ",",
        cols = "sample"
      ) |>
      filter(!is.na(alt)) |>
      unique()
  ) |>
  # for every position where there is a snp in one sample, add a row for other
  # samples with ref allele - ie convert implicit to explicit missing snps
  group_by(gene, ref) |>
  complete(pos, sample) |>
  mutate(alt = if_else(is.na(alt), ref, alt)) |>
  arrange(gene, pos)

# make pairwise comparison
snp_matrix <-
  full_join(df2, df2,
            by = join_by(
              gene == gene,
              pos == pos,
              ref == ref
            ),
            relationship = "many-to-many"
  ) |>
  # filter(sample.x != sample.y) |>
  group_by(gene, pos, ref, sample.x, sample.y) |>
  # there is a snp if at any site at least one alt allele in sample x doesn't
  # match sample - ie all alt alleles in sample x must be present in sample y
  # and all alt alleles in sample xmust be present in sample y
  summarise(snp = !(all(alt.x %in% alt.y) & all(alt.y %in% alt.x))) |>
  group_by(sample.x, sample.y) |>
  summarise(n = sum(snp)) |>
  pivot_wider(id_cols = sample.x, names_from = sample.y, values_from = n)
cat("\n")
print(as.data.frame(snp_matrix))

cat(paste0("\nWriting to ", xargs$output, "\n"))
write_tsv(snp_matrix, xargs$output)
