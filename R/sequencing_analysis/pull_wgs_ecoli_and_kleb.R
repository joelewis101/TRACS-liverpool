library(tidyverse)
library(here)

manifest <- read_csv(here("data/raw/sanger/TRACS_sequencing_sample_metadata20250716.csv"))




write_lines(
  manifest |>
    filter(grepl("Klebsiella", sample_common_name)) |>
    pull(ID),
  here("data/processed/sequencing/tracs_wgs_kleb_lanes.txt")
)


write_lines(
  manifest |>
    filter(grepl("Escherichia", sample_common_name)) |>
    pull(ID),
  here("data/processed/sequencing/tracs_wgs_ecoli_lanes.txt")
)
