library(tidyverse)
library(here)

datetime <- format(Sys.time(), "%Y%m%d-%H%M")

# aim:
# Generate tidy dataframes of the data
# Demographics: pid, age, sex, ethnicity, last postcode, education, capacity
# CFS: pid, date, CFS
# CDS: pid, date, CDS
# ab_exposure: pid, agent, dose, route
# location: pid, date, study_site, bed
# samplingL pid / environmental location code; swab type; date; result

cat("clean_redcap_data.R run at", datetime, "\n")
cat(system(paste0("md5 ", here("R/clean_redcap_data.R"))), "\n")

demographics_file <-
  list.files(here("data/raw/"), pattern = "demographics")

if (length(demographics_file) != 1) {
  stop("Wrong number of demographics files in data/raw")
} else {
  cat("Using demographics file", demographics_file, "\n")
  demographics <-
    read_csv(
      paste0(here("data/raw", demographics_file))
    ) |>
    filter(redcap_event_name == "Baseline") |>
    mutate(record_id = as.numeric(record_id)) |>
    select(!matches("repeat")) |>
    select(-gp_details) 
  outfile <- paste0(
    here("data/processed/"), "demographics_processed", datetime, ".csv"
  )
  cat("Writing to", outfile, "\n")
  write_csv(demographics, outfile)
}

cfs_file <-
  list.files(here("data/raw/"), pattern = "cfs")

if (length(cfs_file) != 1) {
  stop("Wrong number of cfs files in data/raw")
} else {
  cat("Using cfs file", cfs_file, "\n")
  cfs <-
    read_csv(
      paste0(here("data/raw", cfs_file))
    ) |>
    select(!matches("redcap_repeat|complete")) |>
    filter(!is.na(date_cfs)) |>
    pivot_longer(
      -c(record_id, date_cfs, research_staff_4, redcap_event_name)
    ) |>
    filter(!is.na(value)) |>
    rename(
      cfs = value,
      research_staff = research_staff_4
    ) |>
    select(-name) |>
    mutate(record_id = as.numeric(record_id))
  outfile <- paste0(
    here("data/processed/"), "cfs_processed", datetime, ".csv"
  )
  cat("Writing to", outfile, "\n")
  write_csv(cfs, outfile)
}

cds_file <-
  list.files(here("data/raw/"), pattern = "cds")

if (length(cds_file) != 1) {
  stop("Wrong number of cds files in data/raw")
} else {
  cat("Using cds file", cds_file, "\n")
  cds <-
    read_csv(
      paste0(here("data/raw", cds_file))
    ) |>
    select(!matches("repeat")) |>
    filter(!is.na(date_cds)) |>
    rename(research_staff = research_staff_3) |>
    mutate(record_id = as.numeric(record_id))
  outfile <- paste0(
    here("data/processed/"), "cds_processed", datetime, ".csv"
  )
  cat("Writing to", outfile, "\n")
  write_csv(cds, outfile)
}


ab_file <-
  list.files(here("data/raw/"), pattern = "antibiotic_exp")

if (length(ab_file) != 1) {
  stop("Wrong number of antibiotic_exp files in data/raw")
} else {
  cat("Using ab file", ab_file, "\n")
  ab <-
    read_csv(
      paste0(here("data/raw", ab_file))
    ) |>
    filter(!is.na(redcap_repeat_instrument)) |>
    mutate(record_id = as.numeric(record_id))
  outfile <- paste0(
    here("data/processed/"), "abexp_processed", datetime, ".csv"
  )
  cat("Writing to", outfile, "\n")
  write_csv(ab, outfile)
}


# location data is in week A, week B and sample collection forms
# collate here
# aim to have one dataframe with date, all locations
# admission dataframe with admission times/dates and where from
# discharge dataframe

# will also need a file with the sampling dates


weeka_file <-
  list.files(here("data/raw/"), pattern = "weeka")

weekb_file <-
  list.files(here("data/raw/"), pattern = "weekb")

sample_file <-
  list.files(here("data/raw/"), pattern = "sample_collection")

if (length(weeka_file) != 1 | length(weekb_file) != 1 | length(sample_file) != 1) {
  stop("Wrong number of weeka, weekb or sample files in data/raw")
} else {
  cat("Using weeka file", weeka_file, "\n")
  weeka <-
    read_csv(
      paste0(here("data/raw", weeka_file))
    )

  cat("Using weekb file", weekb_file, "\n")
  weekb <-
    read_csv(
      paste0(here("data/raw", weekb_file))
    )
  cat("Using sample_collection file", sample_file, "\n")
  samples <-
    read_csv(
      paste0(here("data/raw", sample_file))
    ) |>
    janitor::clean_names()


  # locations
  participant_location <-
    bind_rows(
      weeka |>
        transmute(
          record_id = as.numeric(record_id),
          redcap_event_name = redcap_event_name,
          date = visit_date,
          location = location_visit1a,
          bed = bed_number_week_a
        ) |>
        filter(!is.na(date)),
      weekb |>
        transmute(
          record_id = as.numeric(record_id),
          redcap_event_name = redcap_event_name,
          date = v1b_date,
          bed = bed_number_week_b
        ) |>
        filter(!is.na(date)),
      samples |>
        transmute(
          record_id = as.numeric(record_id),
          redcap_event_name = event_name,
          date = date_sample_collected,
          bed = bed_space_room_number
        ) |>
        filter(!is.na(date))
    ) |>
    arrange(record_id, date) |>
    group_by(record_id) |>
    fill(location)
  outfile <- paste0(
    here("data/processed/"), "participant_loc_processed", datetime, ".csv"
  )
  cat("Writing to", outfile, "\n")
  write_csv(participant_location, outfile)

  admission <-
    weeka |>
    transmute(
      record_id = as.numeric(record_id),
      redcap_event_name = redcap_event_name,
      data_collection_date = visit_date,
      location = location_visit1a,
      admission_date = admission_date_v1,
      admitted_from = admitted_from,
      hospital_other_detail = hospital_other_detail,
      prev_location_adm_date = prev_location_adm_date
    ) |>
    filter(!is.na(admission_date)) |>
    arrange(record_id)
  outfile <- paste0(
    here("data/processed/"), "admission_processed", datetime, ".csv"
  )
  cat("Writing to", outfile, "\n")
  write_csv(admission, outfile)

}

# discharge

end_of_visit_file <-
  list.files(here("data/raw/"), pattern = "end_of_visit")

if (length(end_of_visit_file) != 1) {
  stop("Wrong number of end_of_visit files in data/raw")
} else {
  cat("Using end_of_visit file", end_of_visit_file, "\n")
  eov <-
    read_csv(
      paste0(here("data/raw", end_of_visit_file))
    ) |>
    janitor::clean_names() |>
    filter(!is.na(end_of_visit_date)) |>
    select(-matches("repeat"))
  outfile <- paste0(
    here("data/processed/"), "end_of_visit__processed", datetime, ".csv"
  )
  cat("Writing to", outfile, "\n")
  write_csv(eov, outfile)
}

# exposures
if (length(weeka_file) != 1) {
  stop("Wrong number of weeka files")
} else {
  cat("Using weeka file", weeka_file, "\n")
  weeka <-
    read_csv(
      paste0(here("data/raw", weeka_file))
    )
  exposures <-
    weeka |>
    select(
      matches(
        "record_id|redcap_event|visit_date|ppi|hospital_adm|devices|animal|overseas")
    ) |>
    rename(
      date = visit_date,
      urinary_catheter = medical_devices___1,
      nasogastric_feeding_tube = medical_devices___2,
      percutaneous_feeding_tube = medical_devices___3,
      longterm_vascular_devide = medical_devices___4,
      shortterm_vascular_device = medical_devices___5,
      other_medical_device = medical_devices___6,
      no_vascular_device = medical_devices___7,
      animal_exp = animal_exp_v1,
      animal_detail = animal_v1
    ) |>
    mutate(record_id = as.numeric(record_id)) |>
    filter(!is.na(date)) |>
    mutate(across(where(is.character), ~
      case_when(
        .x == "Unchecked" ~ "No",
        .x == "Checked" ~ "Yes",
        TRUE ~ .x
      ))) |>
    arrange(record_id, date)
  outfile <- paste0(
    here("data/processed/"), "exposures_processed", datetime, ".csv"
  )
  cat("Writing to", outfile, "\n")
  write_csv(exposures, outfile)
}

# samples
if (length(sample_file) != 1) {
  stop("Wrong number of sample files in data/raw")
} else {
  cat("Using sample_collection file", sample_file, "\n")
  samples <-
    read_csv(
      paste0(here("data/raw", sample_file))
    ) |>
    janitor::clean_names() |>
    filter(!is.na(date_sample_collected)) |>
    mutate(record_id = as.numeric(record_id)) |>
    arrange(record_id, date_sample_collected) |>
    mutate(
      sample_number = gsub("TRA*CS_2_PS[_|-]", "", toupper(sample_number)),
      sample_number = gsub("PS[_|-]|TRACS_2_", "", sample_number),
      sample_number = paste0("TRACS_2_PS_", sample_number)
    )
  outfile <- paste0(
    here("data/processed/"), "samples_processed", datetime, ".csv"
  )
  cat("Writing to", outfile, "\n")
  write_csv(samples, outfile)
}
