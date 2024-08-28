library(tidyverse)
library(readxl)
library(here)

# assumptions of this cleaning script

# any record in qpcr sheet has both E coil and K pn PCRS performed
# if any are positive - interpret as positive
# if it is repeated - use the repeat value
# some repeat values dont match the original - output these as queries



datetime <- format(Sys.time(), "%Y%m%d-%H%M")

escape_spaces <- function(str) {
  return(gsub(" ", "\\\\\ ", str))
}

# need to have tracs shared drive mounted
# pull data from shared drive
download_data <- FALSE

cat("collate_micro_data.R run at", datetime, "\n")
cat(system(paste0("md5 ", here("R/collate_micro_data.R"))), "\n")
cat("Download data is", download_data, "\n")

if (download_data) {
  cat("Attempting to download micro spreadsheet from shared drive...\n")
  system(
    paste0(
      "cp -r /Volumes/shared/TRACS/TRACS\\ data/Sampling\\ data ",
      here("data/raw/")
    )
  )
}


sample_files <-
  list.files(here("data/raw/Sampling data/"), pattern = "TRACS [s|S]ample", recursive = TRUE)

sample_files <-
  sample_files[!grepl("~\\$|Trial|break", sample_files)]

cat("Found the following files:\n")
print(sample_files)

sheet_names <-
  map(
    sample_files, \(x)
    excel_sheets(
      here("data/raw/Sampling data/", x)
    )
  )



# iterate through each sheet and extract and merge
# reciept, plating, qpcr, and maldi results

i <- 1
listout <- list()
prev_samples_listout <- list()

for (sample_file in sample_files) {
  cat("[",i,"] Working on ", sample_file, "\n")
  location <- gsub("/.*$", "", sample_file)
  week <- str_extract(sample_file, "Week [0-9]*")
  cat("[",i,"] Location: ", location, "\n")
  cat("[",i,"] Week: ", week, "\n")

  sheets <- excel_sheets(here("data/raw/Sampling data", sample_file))

  receipt_sheets <- sheets[grepl("Receipt", sheets)]
  plating_sheets <- sheets[grepl("Plating", sheets)]
  qpcr_sheets <- sheets[grepl("qPCR results", sheets)]
  maldi_sheets <- sheets[grepl("MALDI results", sheets)]


  if (length(receipt_sheets) != 1 |
    length(plating_sheets) != 1 |
    (length(qpcr_sheets) + length(maldi_sheets) < 1)
  ) {
    stop(paste0("Wrong number of sheets in ", sample_file))
  }

  cat("[",i, "] Receipt sheets: ", receipt_sheets, "\n")

  receipt_df <-
    read_xlsx(here("data/raw/Sampling data", sample_file), sheet = receipt_sheets) |>
    janitor::clean_names()
  head(receipt_df) |> print()

  cat("\n[",i, "] Plating sheets: ", plating_sheets, "\n")
  plating_df <-
    read_xlsx(here("data/raw/Sampling data", sample_file), sheet = plating_sheets) |>
    janitor::clean_names()
  head(plating_df) |> print()

  out_df <-
    receipt_df |>
    select(tracs_id, lab_id, receipt_date, processing_date, sample_type) |>
    filter(grepl("TRACS", tracs_id)) |>
    mutate(lab_id = as.character(lab_id)) |>
    full_join(
      plating_df |>
        select(tracs_id, scai_result, mlga_result) |>
        filter(grepl("TRACS", tracs_id)),
      by = join_by(tracs_id)
    )

  cat("\n[",i, "] qPCR result sheets: ", qpcr_sheets, "\n")
  if (any(grepl("#98 qPCR results", qpcr_sheets)) &
    sample_file == "Broad Green/Visit 1/Week 14_11.09.23/11.09.23 TRACS sample spreadsheet.xlsx") {
    # This is a retest of a sample that is carried over to the next spreadhseet -
    # needs a bit of manual cleaning
    # the sheet it's carried over to is 18.09.23\ TRACS\ sample\ spreadsheet.xlsx
    cat("[",i, "] Dropping #98 qPCR results - it's a retest carried ovee to the next sheet.\n")
    qpcr_sheets <- qpcr_sheets[!grepl("#98 qPCR results", qpcr_sheets)]
  }

  if (length(qpcr_sheets > 1)) {
    qpcr_results_list <-
      map(qpcr_sheets, \(x)
      read_xlsx(here("data/raw/sampling data", sample_file), sheet = x) |>
        janitor::clean_names() |>
        mutate(across(everything(), as.character)))
    map(qpcr_results_list, \(x) print(head(x)))


    qpcr_results_df <-
      map(qpcr_results_list, \(x)
      select(x, lab_id, species) |>
        mutate(across(everything(), as.character))) |>
      bind_rows()

    # some qpcrs are re runs from previous weeks
    # strategy for these is to pull them all out intoa seperate file and merge
    # back in at the end

    prev_weeks_samples <-
      qpcr_results_df |>
      filter(grepl("[w|W]eek|wk", lab_id)) |>
      mutate(location = location, week_of_pcr = week)

    cat("\n[",i, "]", nrow(prev_weeks_samples), "that look like they are qPCR reruns - removing to add back in at the end\n")
    
    cat(
  paste0("[ ",i, " ] Number of non-control records that don't start with a number or i , and will be dropped: ", qpcr_results_df |>
        filter(!is.na(lab_id), !grepl("control", lab_id), !grepl("^[0-9]|^i", lab_id)) |>
        nrow(),
      "\n"
    ))

    # manually checked these funny lab_ids
    # checked out i = 2
    # Aintree/Visit 1_W29_8.05.23/Week 4_15.05.23/150523 TRACS sample spreadsheet.xlsx
    # there are a number of samples marked #5 chrom etc - I have ignored  
    # is this ok? Waht are they?

    # i = 7 What are the samples in 18.09.23 TRACS sample spreadsheet Broad Green/Visit 1/Week 15_18.09.23 that start with SG - I guess Sarah’s samples?

    # i = 17
    # Estuary house/Visit 2_02.10.23/Week 16_02.10.23/02.10.23 TRACS sample log.xlsx
    # a further 14 samples that lab id startes with SG - I guess more of sarah's
    #samples?

    # i = 27
# Longmoor house/Visit 2_19.06.23/Week 5_19.06.23/19.06.23 TRACS sample spreadsheet.xlsx
    # More SG samples - lab id started with SG

    # i = 39
# Whiston/Visit 1_6.11.23/Week 21_6.11.23/6.11.23 TRACS sample log.xlsx
    # ther are lots of samples here where lab id starts BS or P - what are they?

    # Emailed Esther/claudia with queries 2024-08-24

    qpcr_results_df <-
      qpcr_results_df |>
      filter(!is.na(lab_id), lab_id != "0", grepl("^[0-9]|^i", lab_id), !grepl("[w|W]eek|wk", lab_id)) |>
      mutate(lab_id = unlist(map(lab_id, \(x) strsplit(x, " ")[[1]][1]))) |>
      mutate(lab_id = gsub(",", "", lab_id)) |>
      mutate(species = paste0("qpcr_", tolower(gsub("\\. ", "_", species)))) |>
      unique() |>
      mutate(values = "Yes") |>
      pivot_wider(id_cols = lab_id, names_from = species, values_from = values, values_fill = "No") |>
      select(-qpcr_NA)

    if (!any(grepl("k_pn", names(qpcr_results_df)))) {
      qpcr_results_df <-
        mutate(qpcr_results_df, qpcr_k_pn = "No")
    }

    if (!any(grepl("e_coli", names(qpcr_results_df)))) {
      qpcr_results_df <-
        mutate(qpcr_results_df, qpcr_e_coli = "No")
    }

    if ("qpcr_undetermined" %in% names(qpcr_results_df)) {
      qpcr_results_df <-
        qpcr_results_df |>
        mutate(qpcr_k_pn = if_else(qpcr_undetermined == "Yes", "Undetermined", qpcr_k_pn)) |>
        mutate(qpcr_e_coli = if_else(qpcr_undetermined == "Yes", "Undetermined", qpcr_e_coli)) |>
        select(-qpcr_undetermined)
    }

    out_df <-
      out_df |>
      full_join(
        qpcr_results_df,
        by = join_by(lab_id)
      ) |>
      as.data.frame()
  }

  cat("\n[",i, "] MALDI result sheets: ", maldi_sheets, "\n")

  if (length(maldi_sheets > 1)) {
    # manual munging for funny sheets
    if (sample_file %in% c(
      "Estuary house/Visit 5_28.05.24/Week 45_28.05.24/28.05.24 TRACS sample log.xlsx",
      "Estuary house/Visit 5_28.05.24/Week 46_03.06.24/03.06.24 TRACS sample log.xlsx"
    )) {
      maldi_results_list <-
        map(maldi_sheets, \(x)
        read_xlsx(here("data/raw/Sampling data", sample_file), sheet = x, skip = 1) |>
          janitor::clean_names() |>
          mutate(across(everything(), as.character)) |>
          rename_with(\(x) if_else(grepl("species_best", x), "maldi_id", x)) |>
          rename(lab_id = lab_id_1) |>
          separate_longer_delim(maldi_id, delim = " + "))
      map(maldi_results_list, \(x) print(head(x)))
    } else {
      maldi_results_list <-
        map(maldi_sheets, \(x)
        read_xlsx(here("data/raw/Sampling data", sample_file), sheet = x) |>
          janitor::clean_names() |>
          mutate(across(everything(), as.character)) |>
          rename_with(\(x) if_else(grepl("species", x), "maldi_id", x)) |>
          separate_longer_delim(maldi_id, delim = " + "))
      map(maldi_results_list, \(x) print(head(x)))
    }

    cat("\n[",i, "]", paste0(
      "Number of non-control records that don't start with a number or i , and will be dropped: ",
      
      maldi_results_list |> 
        bind_rows() |>
        filter(!is.na(lab_id), !grepl("control", lab_id), !grepl("^[0-9]|^i", lab_id)) |>
        nrow(),
      "\n"
    ))

    maldi_results_df <-
      map(maldi_results_list, \(x)
      select(x, lab_id, maldi_id)) |>
      bind_rows() |>
      filter(!is.na(lab_id), !grepl("control", lab_id), grepl("^[0-9]|^i", lab_id)) |>
      mutate(lab_id = unlist(map(lab_id, \(x) strsplit(x, " ")[[1]][1]))) |>
      mutate(lab_id = gsub(",", "", lab_id)) 

    maldi_results_other <-
      maldi_results_df |>
      mutate(maldi_id = gsub("Escherichia ", "E\\. ", maldi_id)) |>
      filter(!grepl("K. pn|E. coli", maldi_id)) |>
      group_by(lab_id) |>
      summarise(maldi_other = paste(maldi_id, collapse = ";")) |>
      as.data.frame()

    maldi_results_df <-
      maldi_results_df |>
      mutate(maldi_id = gsub("Escherichia ", "E\\. ", maldi_id)) |>
      filter(grepl("K. pn|E. coli", maldi_id)) |>
      mutate(lab_id = unlist(map(lab_id, \(x) strsplit(x, " ")[[1]][1]))) |>
      mutate(maldi_id = paste0("maldi_", tolower(gsub("\\. ", "_", maldi_id)))) |>
      unique() |>
      mutate(values = "Yes") |>
      pivot_wider(id_cols = lab_id, names_from = maldi_id, values_from = values, values_fill = "No")

    if (!any(grepl("k_pn", names(maldi_results_df)))) {
      maldi_results_df <-
        mutate(maldi_results_df, maldi_k_pn = "No")
    }

    if (!any(grepl("e_coli", names(maldi_results_df)))) {
      maldi_results_df <-
        mutate(maldi_results_df, maldi_e_coli = "No")
    }

    if (nrow(maldi_results_other) == 0) {
      maldi_results_df <-
        mutate(maldi_results_df, maldi_other = "No")
    } else {
      maldi_results_df <-
        maldi_results_df |>
        full_join(
          maldi_results_other,
          by = join_by(lab_id)
        ) |>
        mutate(across(everything(), \(x) if_else(is.na(x), "No", x)))
    }

    out_df <-
      out_df |>
      full_join(
        maldi_results_df,
        by = join_by(lab_id)
      ) |>
      as.data.frame()
  }

  out_df <-
    out_df |>
    mutate(week = week) |>
    relocate(week, .before = everything()) |>
    mutate(location = location) |>
    relocate(location, .before = everything())

  # records with no TRACS_id - drop for now, need to resolve
  qpcr_data_queries <-
    bind_rows(
      tibble(
        file = "Estuary house/Visit 2_02.10.23/Week 17_09.10.23/09.10.23 TRACS sample log.xlsx",
        week = "Week 17",
        lab_id = "181",
        comment = "No lab id 181 in reciept sheet"
      ),
      tibble(
        file = "Aintree/Visit 2_W17B_14.08.23/Week 11_14.08.23/14.08.23 TRACS sample spreadsheet.xlsx",
        week = "Week 11",
        lab_id = "89",
        comment = "No lab id 89 in reciept sheet"
      ),
      tibble(
        file = "Estuary house/Visit 1_03.07.23/Week 7_10.07.23/10.07.23 TRACS sample spreadsheet.xlsx",
        week = "Week 7",
        lab_id = "81",
        comment = "No lab id 81 in reciept sheet"
      )
    )

  out_df <-
    out_df |>
    anti_join(
      qpcr_data_queries,
      by = join_by(week == week, lab_id == lab_id)
    )

  if (sum(is.na(out_df$tracs_id) > 0)) {
    stop("rows without tracs id!")
  }

  listout[[i]] <- out_df
  prev_samples_listout[[i]] <- prev_weeks_samples
  i <- i + 1
}

out_df <-
  bind_rows(listout)

prev_samples_out_df <-
  bind_rows(prev_samples_listout)

# add in prev week's samples

cat("Adding back in repeated samples to main data frame\n")

prev_samples_out_df <-
  prev_samples_out_df |>
  mutate(week_of_sample = str_extract(lab_id, "\\(.*\\)")) |>
  mutate(week_of_sample = gsub("[\\(\\)]", "", week_of_sample)) |>
  mutate(week_of_sample = case_when(
    week_of_sample == "last week" ~ paste0("Week ", str_extract(week_of_pcr, "[0-9]+")),
    TRUE ~ gsub("week|wk", "Week", week_of_sample)
  )) |>
  mutate(lab_id = str_extract(lab_id, "^[0-9|i]+(?=[ \\(])")) |>
  mutate(week_of_sample = str_replace(week_of_sample, "Week(?! )", "Week ")) |>
  mutate(species = paste0("add_qpcr_", tolower(gsub("\\. ", "_", species)))) |>
  unique() |>
  mutate(values = "Yes") |>
  unique() |>
  pivot_wider(id_cols = c(lab_id, location, week_of_pcr, week_of_sample), names_from = species, values_from = values, values_fill = "No") |>
  select(-add_qpcr_NA)

# save records where there seems to be a result and a repeat - data query to
# decide on result

repeat_samples_data_query <-
  out_df |>
  full_join(
    prev_samples_out_df |>
      select(week_of_sample, lab_id, week_of_sample, add_qpcr_e_coli, add_qpcr_k_pn),
    join_by(week == week_of_sample, lab_id == lab_id)
  ) |>
  filter(
    (!is.na(add_qpcr_e_coli) & !is.na(qpcr_e_coli) | !is.na(add_qpcr_k_pn) & !is.na(qpcr_k_pn)) &
    (add_qpcr_e_coli != qpcr_e_coli | add_qpcr_k_pn != qpcr_k_pn)
  )

cat("There are", nrow(repeat_samples_data_query), "samples that seem  to have different results fort a repeat pcr\n")
cat("These will be saved for data queries\n")

out_df <-
  out_df |>
  full_join(
    prev_samples_out_df |>
      select(week_of_sample, lab_id, week_of_sample, add_qpcr_e_coli, add_qpcr_k_pn) |>
      unique(),
    join_by(week == week_of_sample, lab_id == lab_id)
  ) |>
  mutate(
    qpcr_e_coli = if_else(!is.na(add_qpcr_e_coli), add_qpcr_e_coli, qpcr_e_coli),
    qpcr_k_pn = if_else(!is.na(add_qpcr_k_pn), add_qpcr_k_pn, qpcr_k_pn)
  )

out_df <-
  out_df |>
  mutate(e_coli = case_when(
    qpcr_e_coli == "Yes" | maldi_e_coli == "Yes" ~ "Yes",
    TRUE ~ "No"
  )) |>
  mutate(k_pn = case_when(
    qpcr_k_pn == "Yes" | maldi_k_pn == "Yes" ~ "Yes",
    TRUE ~ "No"
  ), ) |>
  unique()

# any duplicates?

tracs_id_dups <-
  out_df |>
  group_by(tracs_id) |>
  filter(n() > 1)

if (nrow(tracs_id_dups) > 0) {
  error("duplicated tracs id in final dataframe!")
}

# write


outfile <- here("data/processed/", paste0("micro_processed", datetime, ".csv"))
cat("Writing to", outfile, "\n")
write_csv(out_df, outfile)


outfile <- here("data/processed", paste0("micro_repeat_qpcr_data_query", datetime, ".csv"))
cat("Writing repeat data queries to", outfile, "\n")
write_csv(repeat_samples_data_query, outfile)

outfile <- here("data/processed", paste0("micro_qpcr_data_query", datetime, ".csv"))
cat("Writing qpcr data queries to", outfile, "\n")
write_csv(qpcr_data_queries, outfile)

cat("Done!\n")

# compare to esther's summary spreadsheet

# out_df |> 
#   filter(!is.na(scai_result), e_coli == "Yes") |>
#   mutate(receipt_date = dmy(receipt_date)) |> 
#   mutate(week_commencing = floor_date(receipt_date, unit = "week")) |>
#   group_by(week_commencing) |>
#   count() |>
#   as.data.frame()
#
#
# out_df |> mutate(receipt_date = dmy(receipt_date)) |> 
#   mutate(week_commencing = floor_date(receipt_date, unit = "week")) |>
#   filter(week_commencing == "2023-07-02")
