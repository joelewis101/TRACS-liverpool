library(tidyverse)
library(here)
library(janitor)

redcap_sample_df <-
  read_csv(here("data/processed/redcap/samples_processed20250717-1055.csv"))

redcap_adm_df <-
  read_csv(here("data/processed/redcap/admission_processed20250717-1055.csv"))

micro_results_df <-
  read_csv(here("data/processed/micro/micro_processed20240828-1524.csv"))

env_loc_df <-
  read_csv(here("data/processed/micro/micro_env_sample_loc20240828-1752.csv"))

fastq_manifest <- 
  read_csv(here("data/processed/sequencing/tracs_samples_manifest.csv"))

# link micro with loc ----------------------------------

# missing samples in micro results df, that are present in the environment
# location log - needs a look at

env_loc_df |>
  anti_join(
    select(micro_results_df, tracs_id, e_coli, k_pn),
    by = join_by(swab_number == tracs_id)
)

# TODO - investigate these missing samples

micro_results_df |>
  filter(sample_type == "Environmental") |>
  select(tracs_id, e_coli, k_pn) |>
  anti_join(
  env_loc_df,
    by = join_by(tracs_id == swab_number)
)

df_out_env <-
  env_loc_df |>
  left_join(
    select(micro_results_df, sample_type, tracs_id, e_coli, k_pn),
    by = join_by(swab_number == tracs_id)
  ) |>
  select(
    location,
    site_number,
    ward,
    room,
    swab_site,
    swab_number,
    date,
    e_coli,
    k_pn
  ) |>
  transmute(
    record_id = paste0(site_number, "_", location, if_else(!is.na(ward), paste0("_", ward), "")),
    sample_number = swab_number,
    source = "Environment",
    type_of_sample = "Environment",
    date_collected = date,
    location = location,
    ward = ward,
    room = room,
    swab_site = swab_site,
    e_coli = e_coli,
    k_pn = k_pn
  ) |>
  mutate(source = "Environment")

# get patient location linked to sample -------------------------------------------

# any missing samples in the micro results frame that are present in the redcap
# sampling df?

redcap_sample_df |>
  anti_join(
    select(micro_results_df, tracs_id, e_coli, k_pn),
    by = join_by(sample_number == tracs_id)
)

# A few that are presumably lost samples
# Yep - TDOD look in to missing sample results for patient samples

# and the othe rway round

micro_results_df |>
  filter(sample_type == "Stool" | sample_type == "Rectal swab") |>
  select(tracs_id, e_coli, k_pn) |>
  anti_join(
  redcap_sample_df,
    by = join_by(tracs_id == sample_number))

# fewer that dont link

# irst, get facility 

# does each participant only have one facility?

redcap_adm_df |>
  select(record_id, location) |>
  unique() |>
  group_by(record_id) |>
  filter(n() > 1)

# yep - link this in to the sample df

df_out_pt <-
redcap_sample_df |>
#   pull(record_id)
  select(record_id, type_of_sample, date_sample_collected, bed_space_room_number, sample_number) |>
  left_join(
    redcap_adm_df |>
      select(record_id, location) |>
      unique(),
    by = join_by(record_id == record_id)
  ) |>
  mutate(
    ward =
      case_when(
        grepl("Ward 11, Broad Green", location) ~ "11",
        grepl("Ward 9, Broad Green", location) ~ "9",
        grepl("Ward 17B", location) ~ "17B",
        grepl("Ward 29 ", location) ~ "29",
        TRUE ~ NA
      ),
    location =
      case_when(
        grepl("Whiston", location) ~ "Whiston",
        grepl("Broad Green", location) ~ "Broad Green",
        grepl("Ward 17B", location) ~ "Aintree",
        grepl("Aintree", location) ~ "Aintree",
        TRUE ~ location
      )
  ) |>
  left_join(
    select(micro_results_df, tracs_id, e_coli, k_pn),
    by = join_by(sample_number == tracs_id)
  ) |>
  transmute(
    record_id = paste0(record_id, "_PS"),
    sample_number = sample_number,
    source = "Human",
    type_of_sample = type_of_sample,
    date_collected = date_sample_collected,
    location = location,
    ward = ward,
    room = bed_space_room_number,
    e_coli = e_coli,
    k_pn = k_pn
  )

# put em together - there are some sampleIDs that have two rows
# take the first

df_out_phenotypic <-
  bind_rows(
    df_out_env,
    df_out_pt
  ) |>
    unique() |>
    group_by(sample_number) |>
    slice(1)

# any fastqs that *don't* have a record in the phenotypic df?

fastq_manifest |>
  select(ID, sample_source, linking_id) |>
  filter(grepl("stool|environmental", sample_source)) |>
  mutate(linking_id = gsub("_E_", "_2_PS_", linking_id)) |>
  mutate(linking_id = gsub("_e|_k", "", linking_id)) |>
  anti_join(df_out_phenotypic,
join_by(linking_id == sample_number))

# yep - TODO - investigate these


sequence_manifest_with_metadata <-
  fastq_manifest |>
  filter(grepl("stool|environmental", sample_source) & !is.na(sample_source)) |>
  select(ID, sweep_or_wgs, linking_id) |>
  mutate(linking_id = gsub("_E_", "_2_PS_", linking_id)) |>
  mutate(linking_id = gsub("_e|_k", "", linking_id)) |>
  left_join(
    df_out_phenotypic,
    join_by(linking_id == sample_number)
  )

write_csv(df_out_phenotypic, here("data/processed/collated_micro_results_linked_to_metadata.csv"))

write_csv(sequence_manifest_with_metadata, here("data/processed/sequencing/tracs_stool_and_env_sample_sequence_ids_with_metadata.csv"))
