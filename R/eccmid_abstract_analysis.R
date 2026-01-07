library(tidyverse)
library(here)
library(brms)
library(bayesplot)

df <-
  read_csv(here("data/processed/micro/micro_processed20240828-1524.csv")) |>
  mutate(
    esbl = if_else(e_coli == "Yes" | k_pn == "Yes", "Yes", "No"),
    sample_type = case_when(
      grepl("E", tracs_id) ~ "Environmental",
      grepl("PS", tracs_id) ~ "Patient",
      grepl("HS", tracs_id) ~ "Hand swab",
      TRUE ~ "Unknown"
    )
  )

df_exp <-
  read_csv(here("data/processed/redcap/exposures_processed20250717-1055.csv"))

df_abx <-
  read_csv(here("data/processed/redcap/abexp_processed20250717-1055.csv"))


df_pt <-
  read_csv(here("data/processed/redcap/demographics_processed20250717-1055.csv"))

df_adm <-
  read_csv(here("data/processed/redcap/admission_processed20250717-1055.csv"))

df_sam <-
  read_csv(here("data/processed/redcap/samples_processed20250717-1055.csv"))


df_cfs <-
  read_csv(here("data/processed/redcap/cfs_processed20250717-1055.csv")) |>
    group_by(record_id) |>
    summarise(mean_cfs = mean(cfs))

df_cds <-
  read_csv(here("data/processed/redcap/cds_processed20250717-1055.csv")) |>
    select(-c(redcap_event_name, date_cds, research_staff, cds_eat_and_drink)) |>
    pivot_longer(-record_id) |>
    group_by(record_id) |>
    summarise(mean_cds = mean(value))

df_pt_metadata <-
  df_pt |>
  left_join(
    df_adm |>
      select(record_id, location, admission_date, admitted_from),
    by = join_by(record_id == record_id)
  ) |>
  mutate(age = as.numeric(difftime(date_of_approach, date_of_birth)) / 365.25) |>
  left_join(df_cfs, by = join_by(record_id)) |>
  left_join(df_cds, by = join_by(record_id)) |>
  group_by(record_id) |>
    slice(1)

df |>
  ggplot(aes(location, fill = esbl)) +
  geom_bar(position = "fill") +
  facet_wrap(~sample_type) +
  coord_flip()

df |>
  group_by(sample_type, location) |>
  summarise(
    n = sum(esbl == "Yes"),
    N = length(esbl),
    prop = n / N
  ) |>
  write_csv(here("data/processed/summary_esbl_pos.csv"))



df_combined <-
  df_sam |>
  left_join(
    df,
    by = join_by(sample_number == tracs_id)
  ) |>
  left_join(df_pt_metadata, join_by(record_id == record_id)) |>
    mutate(esbl_num = if_else(esbl == "Yes", 1,0))

df_adm_sample <-
df_combined |>
  group_by(record_id) |>
  arrange(record_id, date_sample_collected) |>
  slice(1) |>
    left_join(
      filter(df_exp, redcap_event_name == "Visit 1"),
      by = join_by(record_id)
)

df_adm_sample <-
  df_adm_sample |>
  left_join(
    df_abx,
    join_by(record_id == record_id, closest(date_sample_collected > abx_end_date))
  ) |>
  mutate(abx = !is.na(abx_end_date))

m2 <-
  brm(esbl_num ~  admitted_from + (1 | record_id), data = df_combined, family = bernoulli(link = 'logit'), cores = 4)



m3 <-
  brm(esbl_num ~ hospital_admissions, data = df_adm_sample, family = bernoulli(link = 'logit'), cores = 4)

df_adm_sample |>
  ggplot(aes(x = esbl, y = mean_cds)) +
  geom_boxplot() 

df_adm_sample |>
  ggplot(aes(x = esbl, y = age)) +
  geom_boxplot() 

df_adm_sample |>
  ggplot(aes(capacity, fill = esbl)) +
  geom_bar()

df_adm_sample |>
  ggplot(aes(admitted_from, fill = esbl)) +
  geom_bar(position = "fill")


df_adm_sample |>
  ggplot(aes(abx, fill = esbl)) +
  geom_bar(position = "fill")



# m3 <-
#   brm(esbl_num ~ ppi + hospital_admissions + abx + (1 | location.x), data = df_adm_sample, family = bernoulli(link = 'logit'), cores = 4, control = list(adapt_delta = 0.99))
#
#
# m4 <-
#   brm(esbl_num ~ age + mean_cfs  + hospital_admissions + abx + location.x, data = df_adm_sample, family = bernoulli(link = 'logit'), cores = 4, control = list(adapt_delta = 0.99))
#

m5 <-
  brm(esbl_num ~ age + sex + mean_cfs  + hospital_admissions + abx + (1 | location.x), data = df_adm_sample, family = bernoulli(link = 'logit'), cores = 4, control = list(adapt_delta = 0.99))


df_combined |>
  group_by(record_id, location.x) |>
  summarise(any_esbl = any(esbl == "Yes", na.rm = TRUE)) |>
  group_by(location.x) |>
  summarise(
    n = sum(any_esbl),
    N = length(any_esbl),
    prop = sum(any_esbl)/length(any_esbl))


m5$fit |> mcmc_intervals_data(trans = exp, prob_outer = 0.95)

  # repeat but for E coli only


df |>
  ggplot(aes(location, fill = e_coli)) +
  geom_bar(position = "fill") +
  facet_wrap(~sample_type) +
  coord_flip()

df |>
  group_by(sample_type, location) |>
  summarise(
    n = sum(e_coli == "Yes"),
    N = length(e_coli),
    prop = n / N
  ) |>
  write_csv(here("data/processed/summary_ecoli_pos.csv"))


df_combined_Ec <-
  df_sam |>
  left_join(
    df,
    by = join_by(sample_number == tracs_id)
  ) |>
  left_join(df_pt_metadata, join_by(record_id == record_id)) |>
    mutate(ecoli_num = if_else(e_coli == "Yes", 1,0))

df_adm_sample_Ec <-
df_combined_Ec |>
  group_by(record_id) |>
  arrange(record_id, date_sample_collected) |>
  slice(1) |>
    left_join(
      filter(df_exp, redcap_event_name == "Visit 1"),
      by = join_by(record_id)
)

df_adm_sample_Ec <-
  df_adm_sample_Ec |>
  left_join(
    df_abx,
    join_by(record_id == record_id, closest(date_sample_collected > abx_end_date))
  ) |>
  mutate(abx = !is.na(abx_end_date))

m5_Ec <-
  brm(ecoli_num ~ age + sex + mean_cfs  + hospital_admissions + abx + (1 | location.x), data = df_adm_sample_Ec, family = bernoulli(link = 'logit'), cores = 4, control = list(adapt_delta = 0.99)) 


m5_Ec$fit |> mcmc_intervals_data(trans = exp, prob_outer = 0.95) |>
  write_csv(here("data/processed/model_output_baseline_ecoli_carriage.csv"))
