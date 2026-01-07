library(tidyverse)
library(readxl)
library(here)
library(janitor)
library(patchwork)


lcl <- bind_rows(
  read_csv(here("data/raw/LCL_whiston_data/rluh_isol_final_withtracsid.csv")),
  read_csv(here("data/raw/LCL_whiston_data/rluh_sens_isolates_for_sequencing_second_sample_round.csv")) |>
    mutate(site_of_specimen = as.character(site_of_specimen))
)

whiston <-
  read_csv(here("data/raw/LCL_whiston_data/whiston_isolates_for_sequencing.csv"))


sanger <-
  read_csv(here("data/raw/sanger/TRACS_sequencing_sample_metadata20250716.csv"))

df <-
  sanger |>
  mutate(
    sweep_or_wgs = if_else(grepl("Sweep", sample_supplier_name), "sweep", "wgs"),
    study = case_when(
      grepl("LCL", sample_supplier_name) ~ "LCL",
      grepl("WH", sample_supplier_name) ~ "Whiston",
      grepl("CA", sample_supplier_name) ~ "Companion animal",
      TRUE ~ "TRACS"
    ),
    sample_source = case_when(
      study == "LCL" ~ "blood",
      study == "Whiston" ~ "blood",
      study == "Companion animal" ~ NA,
      grepl("ES", sample_supplier_name) ~ "environmental",
      TRUE ~ "stool"
    ),
    linking_id = case_when(
      study == "LCL" ~ str_extract(sample_supplier_name, "(?<=_)[0-9]+$"),
      study == "Whiston" ~ str_extract(sample_supplier_name, "(?<=_)M.+$"),
      sweep_or_wgs == "sweep" ~ gsub("_Sweep", "", sample_supplier_name),
      TRUE ~ sample_supplier_name
    )
  )

df |>
  pull(linking_id)

dfout <-
  df |>
  filter(sweep_or_wgs == "wgs") |>
  transmute(
    studyid = study_id,
    runid = id_run,
    laneid = lane,
    plexid = tag_index
  )

write_csv(
  dfout,
  here("data/processed/sequencing/tracs_single_colony_wgs_manifest.csv")
)

write_csv(df, "data/processed/sequencing/tracs_samples_manifest.csv")


df |>
  filter(sweep_or_wgs == "wgs") |>
  filter(study == "Companion animal") |>
  transmute(
    studyid = study_id,
    runid = id_run,
    laneid = lane,
    plexid = tag_index
  ) |>
  write_csv("data/processed/sequencing/tracs_companion_animals_manifest.csv")
