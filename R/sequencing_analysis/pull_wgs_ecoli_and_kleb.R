library(tidyverse)
library(here)

manifest <- read_csv(here("data/raw/sanger/TRACS_sequencing_sample_metadata20250716.csv"))

sample_qc <-
  read_csv(here("data/processed/sequencing/final_qc.csv"))


write_lines(
  sample_qc |>
    filter(kraken_assignment == "Klebsiella") |>
    filter(!contaminated, !incomplete, !low_n50, !wrong_length) |>
    pull(sample),
  here("data/processed/sequencing/tracs_wgs_kleb_lanes.txt")
)


write_lines(
  sample_qc |>
    filter(kraken_assignment == "Escherichia") |>
    filter(!contaminated, !incomplete, !low_n50, !wrong_length) |>
    pull(sample),
  here("data/processed/sequencing/tracs_wgs_ecoli_lanes.txt")
)


write_lines(
  sample_qc |>
    filter(kraken_assignment == "Escherichia") |>
    filter(!contaminated, !incomplete, !low_n50, !wrong_length) |>
    mutate(sample = paste0(sample, ".assembly.fa")) |>
    pull(sample),
  here("data/processed/sequencing/tracs_wgs_ecoli_assemblies.txt")
)


write_lines(
  sample_qc |>
    filter(kraken_assignment == "Klebsiella") |>
    filter(!contaminated, !incomplete, !low_n50, !wrong_length) |>
    mutate(sample = paste0(sample, ".assembly.fa")) |>
    pull(sample),
  here("data/processed/sequencing/tracs_wgs_kleb_assemblies.txt")
)
