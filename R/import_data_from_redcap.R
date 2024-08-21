library(readr)
library(here)

datetime <- format(Sys.time(), "%Y%m%d-%H%M")

# Demographics

token_path <- here("data/secrets/redcap_token.txt.gpg")
token_fetch_string <-
  paste0("gpg -q -r joelewis101@doctors.org.uk -d ", token_path)
url <- "https://redcap.lstmed.ac.uk/api/"
outpath <- "data/raw/"

cat(datetime, "\n")
cat("Loading TRACS data from redcap database at", url, "\n")
cat("Saving files to ", outpath, "\n")

cat("Demographics\n")
formData <- list(
  "token" = system(token_fetch_string, intern = TRUE),
  content = "record",
  action = "export",
  format = "csv",
  type = "flat",
  csvDelimiter = "",
  "fields[0]" = "capacity",
  "forms[0]" = "demographics",
  rawOrLabel = "label",
  rawOrLabelHeaders = "raw",
  exportCheckboxLabel = "false",
  exportSurveyFields = "false",
  exportDataAccessGroups = "false",
  returnFormat = "csv"
)
response <- httr::POST(url, body = formData, encode = "form")
result <- httr::content(response)

write_csv(result, here(paste0(outpath, "demographics", datetime, ".csv")))
cat("---------------------\n")


# care dependency scale
cat("Care dependency scale\n")
formData <- list(
  "token" = system(token_fetch_string, intern = TRUE),
  content = "record",
  action = "export",
  format = "csv",
  type = "flat",
  csvDelimiter = "",
  "fields[0]" = "record_id",
  "forms[0]" = "care_dependency_score",
  rawOrLabel = "raw",
  rawOrLabelHeaders = "raw",
  exportCheckboxLabel = "false",
  exportSurveyFields = "false",
  exportDataAccessGroups = "false",
  returnFormat = "csv"
)
response <- httr::POST(url, body = formData, encode = "form")
result <- httr::content(response)


write_csv(result, here(paste0(outpath, "cds", datetime, ".csv")))

# clinical frailty score

cat("Clinical frailty score\n")
formData <- list(
  "token" = system(token_fetch_string, intern = TRUE),
  content = "record",
  action = "export",
  format = "csv",
  type = "flat",
  csvDelimiter = "",
  "fields[0]" = "record_id",
  "forms[0]" = "clinical_frailty_scale",
  rawOrLabel = "raw",
  rawOrLabelHeaders = "raw",
  exportCheckboxLabel = "false",
  exportSurveyFields = "false",
  exportDataAccessGroups = "false",
  returnFormat = "csv"
)
response <- httr::POST(url, body = formData, encode = "form")
result <- httr::content(response)
write_csv(result, here(paste0(outpath, "cfs", datetime, ".csv")))
cat("---------------------\n")

# antibiotic exposure

cat("Antibiotic exposure\n")
formData <- list(
  "token" = system(token_fetch_string, intern = TRUE),
  content = "record",
  action = "export",
  format = "csv",
  type = "flat",
  csvDelimiter = "",
  "fields[0]" = "record_id",
  "forms[0]" = "antibiotic_exposure",
  rawOrLabel = "label",
  rawOrLabelHeaders = "raw",
  exportCheckboxLabel = "false",
  exportSurveyFields = "false",
  exportDataAccessGroups = "false",
  returnFormat = "csv"
)
response <- httr::POST(url, body = formData, encode = "form")
result <- httr::content(response)
write_csv(result, here(paste0(outpath, "antibiotic_exp", datetime, ".csv")))
cat("---------------------\n")


# week a
cat("Week A\n")
formData <- list(
  "token" = system(token_fetch_string, intern = TRUE),
  content = "record",
  action = "export",
  format = "csv",
  type = "flat",
  csvDelimiter = "",
  "fields[0]" = "record_id",
  "forms[0]" = "week_a",
  rawOrLabel = "label",
  rawOrLabelHeaders = "raw",
  exportCheckboxLabel = "false",
  exportSurveyFields = "false",
  exportDataAccessGroups = "false",
  returnFormat = "csv"
)
response <- httr::POST(url, body = formData, encode = "form")
result <- httr::content(response)
write_csv(result, here(paste0(outpath, "weeka", datetime, ".csv")))
cat("---------------------\n")

# week b

cat("Week B\n")
formData <- list(
  "token" = system(token_fetch_string, intern = TRUE),
  content = "record",
  action = "export",
  format = "csv",
  type = "flat",
  csvDelimiter = "",
  "fields[0]" = "record_id",
  "forms[0]" = "week_b",
  rawOrLabel = "label",
  rawOrLabelHeaders = "raw",
  exportCheckboxLabel = "false",
  exportSurveyFields = "false",
  exportDataAccessGroups = "false",
  returnFormat = "csv"
)
response <- httr::POST(url, body = formData, encode = "form")
result <- httr::content(response)
write_csv(result, here(paste0(outpath, "weekb", datetime, ".csv")))
cat("---------------------\n")

# sample collections
cat("Sample collections\n")
formData <- list(
  "token" = system(token_fetch_string, intern = TRUE),
  content = "record",
  action = "export",
  format = "csv",
  type = "flat",
  csvDelimiter = "",
  "fields[0]" = "record_id",
  "forms[0]" = "sample_collection",
  rawOrLabel = "label",
  rawOrLabelHeaders = "label",
  exportCheckboxLabel = "false",
  exportSurveyFields = "false",
  exportDataAccessGroups = "false",
  returnFormat = "csv"
)
response <- httr::POST(url, body = formData, encode = "form")
result <- httr::content(response)
write_csv(result, here(paste0(outpath, "sample_collection", datetime, ".csv")))
cat("---------------------\n")

# end of visit

cat("End of visit\n")
formData <- list(
  "token" = system(token_fetch_string, intern = TRUE),
  content = "record",
  action = "export",
  format = "csv",
  type = "flat",
  csvDelimiter = "",
  "fields[0]" = "record_id",
  "forms[0]" = "end_of_visit",
  rawOrLabel = "label",
  rawOrLabelHeaders = "raw",
  exportCheckboxLabel = "false",
  exportSurveyFields = "false",
  exportDataAccessGroups = "false",
  returnFormat = "csv"
)
response <- httr::POST(url, body = formData, encode = "form")
result <- httr::content(response)
write_csv(result, here(paste0(outpath, "end_of_visit", datetime, ".csv")))
cat("---------------------\n")

# enhanced sampling

cat("Enchanced sampling\n")
formData <- list(
  "token" = system(token_fetch_string, intern = TRUE),
  content = "record",
  action = "export",
  format = "csv",
  type = "flat",
  csvDelimiter = "",
  "fields[0]" = "record_id",
  "forms[0]" = "enhanced_sampling",
  "events[0]" = "enhanced_sampling_arm_1",
  rawOrLabel = "label",
  rawOrLabelHeaders = "raw",
  exportCheckboxLabel = "false",
  exportSurveyFields = "false",
  exportDataAccessGroups = "false",
  returnFormat = "csv"
)
response <- httr::POST(url, body = formData, encode = "form")
result <- httr::content(response)
write_csv(result, here(paste0(outpath, "enhanced_sampling", datetime, ".csv")))
cat("---------------------\n")

# withdrawal

cat("Withdrawal\n")
formData <- list(
  "token" = system(token_fetch_string, intern = TRUE),
  content = "record",
  action = "export",
  format = "csv",
  type = "flat",
  csvDelimiter = "",
  "fields[0]" = "record_id",
  "forms[0]" = "withdrawal",
  rawOrLabel = "label",
  rawOrLabelHeaders = "raw",
  exportCheckboxLabel = "false",
  exportSurveyFields = "false",
  exportDataAccessGroups = "false",
  returnFormat = "csv"
)
response <- httr::POST(url, body = formData, encode = "form")
result <- httr::content(response)
write_csv(result, here(paste0(outpath, "withdrawal", datetime, ".csv")))
cat("---------------------\n")

