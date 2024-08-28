library(tidyverse)
library(readxl)
library(here)



datetime <- format(Sys.time(), "%Y%m%d-%H%M")

cat("collate_env_loc_data.R run at", datetime, "\n")
cat(system(paste0("md5 ", here("R/collate_env_loc_data.R"))), "\n")

sample_files2 <-
  list.files(here("data/raw/Sampling data/"), pattern = "[e|E]nviron", recursive = TRUE)

sample_files2 <-
  sample_files2[!grepl("~\\$|Trial|break", sample_files2)]

cat("Found the following files:\n")
print(sample_files2)


i <- 1
listout <- list()

for (sample_file in sample_files2) {
  cat("[", i, "] Working on ", sample_file, "\n")
  location <- gsub("/.*$", "", sample_file)
  week <- str_extract(sample_file, "Week [0-9]*")
  cat("[", i, "] Location: ", location, "\n")
  cat("[", i, "] Week: ", week, "\n")

  sheets <- excel_sheets(here("data/raw/Sampling data", sample_file))

if (sample_file == "Longmoor house/Visit 1_ 17.04.23/Week 2_17.04.23/20.04.23 TRACS Environmental Sample Sheet.xlsx" |
sample_file == "Aintree/Visit 1_W29_8.05.23/Week 4_15.05.23/17.05.23 TRACS Environmental Sample Sheet.xlsx") {
   cat("skipping this sheet - needs data reconciliation - follow up with claudia and esther")
      listout[[i]] <- NULL

  } else {

  df <-
   map(sheets, \(x)
    read_xlsx(here("data/raw/sampling data", sample_file),
      sheet = x,
      col_types = "text"
    ) |>
    janitor::clean_names() |>
	rename_with(\(x) if_else(x == "x3769", "site_number", x))) |> 
      bind_rows() |>
      mutate(location = location,
	week = as.numeric(gsub("Week ", "", week))) |>
      relocate(c(week, location), .before = everything()) |>
      filter(!is.na(swab_number)) |>
    mutate(
      swab_number =
        if_else(!grepl("^[0-9]", swab_number),
          swab_number,
          paste0("TRACS_2_ES_", swab_number)
        )) 

  head(df) |> print()
  listout[[i]] <- df
  }
  
  i <- i + 1
}


enviro_out_df <- bind_rows(listout) |>
  select(!starts_with("x")) |>
  filter(grepl("^TRAC", swab_number)) |>
  select(-time) |>
  mutate(date = 
    if_else(grepl("\\.", date),
    dmy(date),
    janitor::excel_numeric_to_date(as.numeric(date))))


outfile <- here("data/processed", paste0("micro_env_sample_loc", datetime, ".csv"))
cat("Writing environmental location file to", outfile, "\n")
write_csv(enviro_out_df, outfile)
