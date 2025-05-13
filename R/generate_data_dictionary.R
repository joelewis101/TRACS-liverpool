library(tidyverse)
# library(datadictionary)
library(here)

library(labelled)



filename <-
  list.files(here("data/processed/micro/"), pattern = "processed")

cat("Using", filename[1], "to generate dictionary")

micro_data <-
  read_csv(here("data/processed/micro/", filename[1]),
    col_types = "cccccccccccccccccc") |>
    mutate(across(matches("date"), \(x)  as.Date(x,format = "%d.%m.%y")))

micro_data <-
set_variable_labels(micro_data,
  .labels = list(
  location = "Name of Hospital/facility",
    week = "Week of study",
    tracs_id = "Unique TRACS id to link to redcap metadata",
    lab_id = "Unique lab ID for sample",
    receipt_date = "Date of sample reciept",
    processing_date = "Date of sample processing",
    sample_type = "Type of sample",
    scai_result = "Result of growth on SCAI agar - [NG (no growth), Negative (growth but not Klebsiella), Positive (growth AND klebsiella)",
    mlga_result = "Result of growth on MLGA agar - [NG (no growth), Negative (growth but not E coli), Positive (growth AND E coli)",
    qpcr_k_pn = "Results of K pneumoniae PCR = [Yes (done and positive), NNo (done anmd negative], NA (not done)]",
    qpcr_e_coli = "Results of E coli PCR = [Yes (done and positive), NNo (done anmd negative], NA (not done)]",
    maldi_k_pn = "Rsults of maldi speciation = [Yes (done and Kpn present), No (done and kPn absent), NA (not done)]",
    maldi_e_coli = "Rsults of maldi speciation = [Yes (done and Ec present), No (done and Ec absent), NA (not done)]",
      maldi_other = "Results of maldi speciation if other species present; if multiple species, sperated by semicolon",
    add_qpcr_k_pn = "Results of 2nd K pneumoniae PCR (if done) = [Yes (done and positive), NNo (done anmd negative], NA (not done)]",
    add_qpcr_e_coli = "Results of 2nd E coli PCR (if done) = [Yes (done and positive), No (done anmd negative], NA (not done)]",
    e_coli = "Overall assessment is Ec present in sample [Yes,No]",
    k_pn = "Overall assessment is Kp present in sample [Yes,No]"))

micro_data <-
  generate_dictionary(micro_data)

write_csv(micro_data, here("data/processed/dictionaries", 
paste0(gsub("[0-9|-]+.csv","",filename[1]), "_dictionary.csv")
))

###

filename <-
  list.files(here("data/processed/micro/"), pattern = "env_sample_loc")

cat("Using", filename[1], "to generate dictionary")


micro_loc <-
  read_csv(here("data/processed/micro/", filename[1]))


micro_loc <-
set_variable_labels(micro_loc,
  .labels = list(
  location = "Name of Hospital/facility",
    week = "Week of study",
    swab_number = "Unique TRACS id to link to redcap metadata - same as tracs_id",
    date = "Date of sample collection",
    site_number = "Unique location ID for site location",
ward = "Ward/location at sub-facility level",
room = "Room of swab collection location",
swab_site = "Site of swab collection",
pbs_number = "PBS (collection solution) batch number",
floor = "Floor within facility of sampel collection"
))


micro_loc <-
  generate_dictionary(micro_loc)

write_csv(micro_loc, here("data/processed/dictionaries", 
paste0(gsub("[0-9|-]+.csv","",filename[1]), "_dictionary.csv")
))

# redcap data

filename <-
  list.files(here("data/processed/redcap/"), pattern = "abexp_processed")


cat("Using", filename[1], "to generate dictionary")


redcap_abx <-
  read_csv(here("data/processed/redcap/", filename[1]))

redcap_abx <-
  set_variable_labels(redcap_abx,
    .labels = list(
      record_id = "Unique participant ID"
    )
  )

redcap_abx <-
  generate_dictionary(redcap_abx)

write_csv(redcap_abx, here(
  "data/processed/dictionaries",
  paste0(gsub("[0-9|-]+.csv", "", filename[1]), "_dictionary.csv")
))

###

filename <-
  list.files(here("data/processed/redcap/"), pattern = "admission_processed")


cat("Using", filename[1], "to generate dictionary")

redcap_admission <-
  read_csv(here("data/processed/redcap/", filename[1]))

redcap_admission <-
  set_variable_labels(redcap_admission,
    .labels = list(
      record_id = "Unique participant ID",
      location = "Name of Hospital/facility",
      data_collection_date = "Date of sample collection",
      admission_date = "Date of admission to current facility",
      admitted_from = "Where admitted from to current facility",
      hospital_other_detail = "Free text details of which hospital admitted from"
    )
  )

redcap_admission <-
  generate_dictionary(redcap_admission)

write_csv(redcap_admission, here(
  "data/processed/dictionaries",
  paste0(gsub("[0-9|-]+.csv", "", filename[1]), "_dictionary.csv")
))

###

filename <-
  list.files(here("data/processed/redcap/"), pattern = "cds_processed")


cat("Using", filename[1], "to generate dictionary")

redcap_cds <-
  read_csv(here("data/processed/redcap/", filename[1]))

redcap_cds <-
  set_variable_labels(redcap_cds,
    .labels = list(
      record_id = "Unique participant ID"
    ))
 
redcap_cds <-
  generate_dictionary(redcap_cds)

write_csv(redcap_cds, here(
  "data/processed/dictionaries",
  paste0(gsub("[0-9|-]+.csv", "", filename[1]), "_dictionary.csv")
))

###

filename <-
  list.files(here("data/processed/redcap/"), pattern = "cfs_processed")


cat("Using", filename[1], "to generate dictionary")

redcap_cfs <-
  read_csv(here("data/processed/redcap/", filename[1]))

redcap_cfs <-
  set_variable_labels(redcap_cfs,
    .labels = list(
      record_id = "Unique participant ID",
      cfs = "clinical frailty score"
    ))

redcap_cfs <-  
  generate_dictionary(redcap_cfs)

write_csv(redcap_cfs, here(
  "data/processed/dictionaries",
  paste0(gsub("[0-9|-]+.csv", "", filename[1]), "_dictionary.csv")
))

###

filename <-
  list.files(here("data/processed/redcap/"), pattern = "demographics_processed")

cat("Using", filename[1], "to generate dictionary")

redcap_demographics <-
  read_csv(here("data/processed/redcap/", filename[1]))

redcap_demographics <-
  set_variable_labels(redcap_demographics,
    .labels = list(
      record_id = "Unique participant ID"
    ))

redcap_demographics <-
  generate_dictionary(redcap_demographics)

write_csv(redcap_demographics, here(
  "data/processed/dictionaries",
  paste0(gsub("[0-9|-]+.csv", "", filename[1]), "_dictionary.csv")
))
###



###

filename <-
  list.files(here("data/processed/redcap/"), pattern = "end_of_visit")


cat("Using", filename[1], "to generate dictionary")

redcap_end_of_visit <-
  read_csv(here("data/processed/redcap/", filename[1]))

redcap_end_of_visit <-
  set_variable_labels(redcap_end_of_visit,
    .labels = list(
      record_id = "Unique participant ID"
    ))
 
redcap_end_of_visit <-
  generate_dictionary(redcap_end_of_visit)

write_csv(redcap_end_of_visit, here(
  "data/processed/dictionaries",
  paste0(gsub("[0-9|-]+.csv", "", filename[1]), "_dictionary.csv")
))

###



###

filename <-
  list.files(here("data/processed/redcap/"), pattern = "exposures")


cat("Using", filename[1], "to generate dictionary")

redcap_exposures <-
  read_csv(here("data/processed/redcap/", filename[1]))

redcap_exposures <-
  set_variable_labels(redcap_exposures,
    .labels = list(
      record_id = "Unique participant ID"
    ))
 
redcap_exposures <-
  generate_dictionary(redcap_exposures)

write_csv(redcap_exposures, here(
  "data/processed/dictionaries",
  paste0(gsub("[0-9|-]+.csv", "", filename[1]), "_dictionary.csv")
))

###



###

filename <-
  list.files(here("data/processed/redcap/"), pattern = "participant_loc")


cat("Using", filename[1], "to generate dictionary")

redcap_participant_loc <-
  read_csv(here("data/processed/redcap/", filename[1]))

redcap_participant_loc <-
  set_variable_labels(redcap_participant_loc,
    .labels = list(
      record_id = "Unique participant ID"
    ))

redcap_participant_loc <-
  generate_dictionary(redcap_participant_loc)

write_csv(redcap_participant_loc, here(
  "data/processed/dictionaries",
  paste0(gsub("[0-9|-]+.csv", "", filename[1]), "_dictionary.csv")
))
###



###

filename <-
  list.files(here("data/processed/redcap/"), pattern = "samples_processed")


cat("Using", filename[1], "to generate dictionary")

redcap_samples <-
  read_csv(here("data/processed/redcap/", filename[1]))

redcap_samples <-
  set_variable_labels(redcap_samples,
    .labels = list(
      record_id = "Unique participant ID"
    ))
 
redcap_samples <-
  generate_dictionary(redcap_samples)


write_csv(redcap_samples, here(
  "data/processed/dictionaries",
  paste0(gsub("[0-9|-]+.csv", "", filename[1]), "_dictionary.csv")
))

###
