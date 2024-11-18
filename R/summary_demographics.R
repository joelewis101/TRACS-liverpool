library(tidyverse)
library(here)

cfs <- read_csv(here("data/processed/redcap/cfs_processed20240902-1410.csv"))

demog <- read_csv(here("data/processed/redcap/demographics_processed20240902-1410.csv"))

quantile(
  cfs |>
  group_by(record_id) |>
  arrange(date_cfs) |>
  slice(1) |>
  pull(cfs),
  c(0.25,0.5, 0.75)
)
