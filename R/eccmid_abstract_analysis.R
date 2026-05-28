library(tidyverse)
library(here)
library(brms)
library(bayesplot)
library(scales)
library(blantyreSepsis)
library(readxl)

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



df_pt_metadata |>
  ungroup() |>
  select(sex, age, ethnicity, capacity, mean_cfs, admitted_from) |>
  pretty_tbl_df()

df_pt_metadata |>
  ungroup() |>
  left_join(
    df_exp |>
      group_by(record_id) |>
      arrange(record_id, date) |>
      slice(1) |>
      select(record_id, date, animal_exp, overseas_travel, hospital_admissions) |>
      left_join(
        df_abx |>
          select(record_id, abx_start_date) |>
          unique(),
        join_by(record_id == record_id, closest(date > abx_start_date))
      ) |> mutate(
        abx =
          case_when(
            is.na(abx_start_date) ~ "No",
            difftime(abx_start_date, date, units = "days") < 90 ~ "Yes",
            TRUE ~ "No"
          )
      ),
    by = "record_id"
  ) |>
  select(sex, age, ethnicity, capacity, mean_cfs, admitted_from, animal_exp, overseas_travel, hospital_admissions, abx) |>
  pretty_tbl_df()

    if_else(is.na(abx_start_date), "No", "Yes")
 select(record_id, date, animal_exp, overseas_travel, hospital_admissions, abx) |>


df |>
  ggplot(aes(location, fill = esbl)) +
  geom_bar(position = "fill") +
  facet_wrap(~sample_type) +
  coord_flip()


df |>
  filter(location != "Aintree", sample_type != "Hand swab") |>
  mutate(
    location =
      case_when(
        location == "Walton Manor" ~ "Care Home 1",
        location == "Estuary house" ~ "Care Home 2",
        location == "Whiston" ~ "Frailty Unit",
        location == "Broad Green" ~ "Elderly Care Ward",
        location == "Longmoor house" ~ "Rehab Unit"
      )
  ) |>
  group_by(location, sample_type) |>
  summarise(
    n = sum(esbl == "Yes"),
    N = length(esbl)
  ) |>
  rowwise() |>
  mutate(
    prop = n / N,
    lci = binom.test(n, N)$conf.int[1],
    uci = binom.test(n, N)$conf.int[2]
  ) |>
  ggplot(aes(
    x = fct_reorder(
      location,
      prop,
      max
    ),
    y = prop,
    ymin = lci,
    ymax = uci,
    shape = sample_type,
    color = sample_type
  )) +
  geom_point(size = 3) +
  geom_errorbar(width = 0) +
  # facet_wrap(~ sample_type, scales = "free", ncol = 1) +
  coord_flip() +
  theme_bw() +
  scale_color_manual(values = pal_viridis()(3)[1:2]) +
  scale_shape_manual(values = c(1, 15)) +
  labs(
    color = "Sample Type",
    shape = "Sample Type",
    # title = "Prevalence of ESBL by sample",
    x = "Study Site",
    y = "Prevalence"
  ) +
  theme(legend.position = "bottom", 
  plot.title= element_text(size = 14),
    axis.text = element_text(size =  14),
  )
 
ggsave("escmid_fig1.svg", width = 6, height  = 3)
ggsave("escmid_fig1.pdf", width = 6, height  = 3)

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

### E coli STs



read_tsv("/Users/joseph.lewis/projects/TRACS/manuscripts/escmid2026/ecoli_sc_combined_mlst.tsv", col_names = FALSE) |>
  mutate(X1 = str_extract(X1, "\\/.*$"))


read_xls("/Users/joseph.lewis/projects/TRACS/manuscripts/escmid2026/manifest_all_TRACS.xls") |>
  filter(grepl("TRACS", linking_id)) |>
  mutate(source = case_when(
    grepl("PS", linking_id) ~ "Human",
    grepl("ES", linking_id) ~ "Environmental",
    TRUE ~ NA
  )) |>
  select(ST, location, source) |>
  filter(location != "Companion animal") |>
  filter(
    !is.na(ST) & ST != "NA",
    !is.na(source),
    location != "Aintree",
    location != "TRACS"
  ) |>
  mutate(ST = as.numeric(ST)) |>
  group_by(ST) |>
  mutate(ST = if_else(n() < 8 | is.na(ST), NA, ST)) |>
  mutate(
    location =
      case_when(
        location == "Walton Manor" ~ "Care Home 1",
        location == "Estuary house" ~ "Care Home 2",
        location == "Whiston" ~ "Frailty Unit",
        location == "Broad Green" ~ "Elderly Care Ward",
        location == "Longmoor house" ~ "Rehab Unit"
      )
  ) |>
  mutate(location = factor(location,
    levels = c(
      "Rehab Unit",
      "Elderly Care Ward",
      "Frailty Unit",
      "Care Home 2",
      "Care Home 1"
    )
  )) |>
  ggplot(
    aes(location, fill = fct_infreq(as.factor(ST)))
  ) +
  geom_bar(position = "fill") +
  # geom_bar() +
  coord_flip() +
  facet_wrap(~source) +
  scale_fill_manual(
    values = viridis_pal()(9),
    labels = function(breaks) {
      breaks[is.na(breaks)] <- "Other"
      breaks
    }
  ) +
  labs(fill = "MLST",
    y = "Proportion",
    x = "") +
  theme_bw() +
  theme(legend.position = "bottom", 
    strip.text.x = element_text(size = 14),
  plot.title= element_text(size = 14),
    axis.text.y = element_text(size =  14),
  )

ggsave("escmid_fig2.svg", width = 6, height  = 4)
ggsave("escmid_fig2.pdf", width = 6, height  = 4)

read_xls("/Users/joseph.lewis/projects/TRACS/manuscripts/escmid2026/manifest_all_TRACS.xls") |>
  filter(grepl("TRACS", linking_id)) |>
  mutate(source = case_when(
     grepl("PS", linking_id) ~ "Human",
     grepl("ES", linking_id) ~ "Environmental",
     TRUE ~ NA
  )) |>
  select(ST, location, source) |>
  filter(location != "Companion animal") |>
  filter( !is.na(ST) & ST != "NA", 
    !is.na(source),
  location != "Aintree",
  location != "TRACS") |>
  group_by(location, ST) |>
  count() |>
  pivot_wider(id_cols = location, names_from = ST, values_from = n, values_fill = 0) |>
  ungroup() |>
  select(-location) |>
  as.matrix() |>
  fisher.test(simulate.p.value = TRUE)


read_csv("/Users/joseph.lewis/projects/TRACS/manuscripts/escmid2026/TRACS_summary_by_location_human.csv") |>
  pivot_longer(-location, names_to = "ST", values_to = "n") |>
  mutate(sample_type = "human") |>
  bind_rows(
    read_csv("/Users/joseph.lewis/projects/TRACS/manuscripts/escmid2026/TRACS_summary_by_location_env.csv") |>
      pivot_longer(-location, names_to = "ST", values_to = "n") |>
      mutate(sample_type = "environent")
  ) |>
  group_by(ST) |>
  filter(n > 0) |>
  mutate(ST = as.numeric(ST)) |>
  mutate(ST = if_else(n() < 5 | is.na(ST), NA, ST)) |>
  ggplot(
    aes(fct_reorder(location, n, sum), fill = as.factor(ST))) +
  geom_bar() +
  coord_flip()
