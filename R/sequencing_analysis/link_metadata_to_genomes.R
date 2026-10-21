library(tidyverse)
library(here)
library(janitor)

redcap_sample_df <-
  read_csv(here("data/processed/redcap/samples_processed20250717-1055.csv"))

redcap_adm_df <-
  read_csv(here("data/processed/redcap/admission_processed20250717-1055.csv"))

micro_results_df <-
  read_csv(here("data/processed/micro/micro_processed20261021-1357.csv"))

env_loc_df <-
  read_csv(here("data/processed/micro/micro_env_sample_loc20261021-1531.csv"))

fastq_manifest <- 
  read_csv(here("data/processed/sequencing/tracs_samples_manifest.csv"))

# link micro with loc ----------------------------------

# There are a number of duplciations in subsequent week spreadsheets (presumably
# where people have gone back to collect missing samples) - remove
# also remove duplicate sample IDs woth the same site id - these mostly just
# have slightly differenty text in the location - just pick one 

env_loc_df <-
env_loc_df |>
  select(-week) |>
  distinct() |>
  group_by(swab_number, location, site_number) |>
  slice(1)

# implement sally's manual reconciliation

duplicates_corrected <-
  read_xlsx(here("data/raw/Missing_and_duplicate_samples.xlsx"),
            sheet = 5) |>
  janitor::clean_names() |>
  filter(corrections_name != "TRACS_2_ES_1288") |>
  mutate(original_swab_number = tracs_id,
         corrected_swab_number = corrections_name,
         site_number = as.numeric(str_extract(corrections_location, "^[0-9]+(?=_)")),
         location = gsub("_.+$","", str_extract(corrections_location, "(?<=_).+")),
         .keep = "none")

  env_loc_df <-
    env_loc_df |>
    left_join(duplicates_corrected,
      by = join_by(swab_number == original_swab_number, location, site_number)
    ) |>
    mutate(swab_number = if_else(!is.na(corrected_swab_number), corrected_swab_number, swab_number)) |>
    select(-c(corrected_swab_number))

  # how many duplicates

  env_loc_df |>
    group_by(swab_number) |>
    filter(n() > 1)

  micro_results_df |>
    filter(duplicated(tracs_id))

# missing samples in micro results df, that are present in the environment
# location log - needs a look at

env_loc_df |>
  anti_join(
    select(micro_results_df, tracs_id, e_coli, k_pn),
    by = join_by(swab_number == tracs_id)
)


# TODO - investigate these missing samples; though there is likely not much to
# be done

# link micro results to environmental location by tracs ID and by location
# (this latter screens out some errors)

micro_results_df |>
  filter(sample_type == "Environmental") |>
  select(tracs_id, location, e_coli, k_pn) |>
  anti_join(
  env_loc_df,
    by = join_by(tracs_id == swab_number, location)
) |> 
  arrange(tracs_id)

# drop duplicated IDs after joining - ie tracs IDs that have 2 different IDs in
# env_loc_df
# There is no real way to tell which is real

micro_results_df |>
  left_join(
  env_loc_df,
    by = join_by(tracs_id == swab_number, location)
) |> 
  arrange(tracs_id) |>
  # filter(grepl("1205", tracs_id))
  filter(duplicated(tracs_id)) |> pull(tracs_id) -> dups

length(dups)

# 33 duplicates
micro_results_df |>
  filter(sample_type == "Environmental") |>
  select(tracs_id, location, e_coli, k_pn) |>
  left_join(
  env_loc_df |> filter(!swab_number %in% dups),
    by = join_by(tracs_id == swab_number, location)
) |> 
  arrange(tracs_id) |>
  filter(is.na(site_number)) |> pull(tracs_id) |> sort()

# 98 missing in total


micro_results_df |>
  filter(sample_type == "Environmental") |>
  select(tracs_id, location, e_coli, k_pn) |>
  left_join(
  env_loc_df |> filter(!swab_number %in% dups),
    by = join_by(tracs_id == swab_number, location)
) |> 
  arrange(tracs_id) |>
  filter(is.na(site_number)) |> nrow()


df_out_env <-
micro_results_df |>
  filter(sample_type == "Environmental") |>
  select(tracs_id, location, e_coli, k_pn) |>
  left_join(
  env_loc_df |> filter(!swab_number %in% dups),
    by = join_by(tracs_id == swab_number, location)) |>
  select(
    location,
    site_number,
    ward,
    room,
    swab_site,
    tracs_id,
    date,
    e_coli,
    k_pn
  ) |>
  # filter(!is.na(site_number)) |>
  transmute(
    record_id = paste0(site_number, "_", location, if_else(!is.na(ward), paste0("_", ward), "")),
    sample_number = tracs_id,
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
# I've put an issue in the github - can double check

    df_out_pt |>
      distinct() |>
      group_by(sample_number) |>
      filter(n() > 1)


df_out_phenotypic <-
  bind_rows(
    df_out_env,
    df_out_pt |>
      distinct() |>
      group_by(sample_number) |>
      filter(n() == 1)
  )

# check for dups

df_out_phenotypic |>
  group_by(sample_number) |>
  filter(n() > 1)

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
