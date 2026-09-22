library(tidyverse)
library(here)
library(expm)
library(bayesplot)
library(gtsummary)

df <-
  read_csv(here("data/processed/collated_micro_results_linked_to_metadata.csv"))

df |>
  select(record_id, location, source, date_collected, e_coli, k_pn) |>
  group_by(record_id) |>
  mutate(fu_time = max(as.numeric(difftime(date_collected, min(date_collected), units = "days")))) |>
  arrange(record_id, date_collected) |>
  slice(1) |>
  group_by(location, source) |>
  summarise(
    median_fu_time = median(fu_time, na.rm = TRUE),
    lq_fu_time = quantile(fu_time, 0.25, na.rm = TRUE),
    uq_fu_time = quantile(fu_time, 0.75, na.rm = TRUE),
    prop_ec = sum(e_coli == "Yes", na.rm = TRUE) / length(!is.na(e_coli)),
    lci_ec = binom.test(sum(e_coli == "Yes", na.rm = TRUE), length(!is.na(e_coli)))$conf.int[[1]],
    uci_ec = binom.test(sum(e_coli == "Yes", na.rm = TRUE), length(!is.na(e_coli)))$conf.int[[2]],
    prop_kp = sum(k_pn == "Yes", na.rm = TRUE) / length(!is.na(k_pn)),
    lci_kp = binom.test(sum(k_pn == "Yes", na.rm = TRUE), length(!is.na(k_pn)))$conf.int[[1]],
    uci_kp = binom.test(sum(k_pn == "Yes", na.rm = TRUE), length(!is.na(k_pn)))$conf.int[[2]]
  ) |>
  ungroup() |>
  mutate(
    fu_time = paste0(round(median_fu_time, 0), " (", round(lq_fu_time, 0), "-", round(uq_fu_time, 0), ")"),
    ec_prop = paste0(round(prop_ec, 2), " (", round(lci_ec, 2), "-", round(uci_ec, 2), ")"),
    kp_prop = paste0(round(prop_kp, 2), " (", round(lci_kp, 2), "-", round(uci_kp, 2), ")"),
    .keep = "unused"
  ) |>
  pivot_longer(-c(location, source)) |>
  mutate(location = str_to_title(location)) |>
  pivot_wider(id_cols = location, names_from = (c(source, name)), values_from = value)

df |>
  filter(source == "Human", location != "Aintree") |>
  group_by(record_id) |>
  mutate(t = as.numeric(difftime(date_collected, min(date_collected), units = "days")),
	 e_coli = if_else(e_coli == "Yes", 1, 0),
	 k_pn = if_else(k_pn == "Yes", 1, 0)) |>
  arrange(record_id) |>
  select(record_id, t, location, e_coli, k_pn) |>
  pivot_longer(-c(record_id, t, location))  |>
  ggplot(aes(t, value, color = location, fill = location)) +
  geom_smooth(span = 1.5) +
  # geom_point() + 
  facet_grid(name ~ location, scales = "free_x") +
  coord_cartesian(ylim = c(0,0.5), xlim = c(0,30))


df |>
  filter(source == "Human", location != "Aintree") |>
group_by(record_id) |>
  mutate(t = as.numeric(difftime(date_collected, min(date_collected), units = "days")),
	 e_coli = if_else(e_coli == "Yes", 1, 0),
	 k_pn = if_else(k_pn == "Yes", 1, 0)) |>
  arrange(record_id) |>
  select(record_id, t, location, e_coli, k_pn) |>
  pivot_longer(-c(record_id, t, location))  |>
  ggplot(aes(t, value, color = location, fill = location)) +
  geom_smooth(span = 0.9) +
  # geom_point() + 
  facet_grid(name ~ location) + 
  coord_cartesian(ylim = c(0,0.5), xlim = c(0,10)) +
  theme_bw()

# df |>
#   filter(source == "Environment", location != "Aintree") |>
#   group_by(record_id) |>
#   mutate(t = as.numeric(difftime(date_collected, min(date_collected, na.rm = TRUE), units = "days")),
# 	 e_coli = if_else(e_coli == "Yes", 1, 0),
# 	 k_pn = if_else(k_pn == "Yes", 1, 0)) |>
#   arrange(record_id) |>
#   select(record_id, t, location, e_coli, k_pn) |>
#   pivot_longer(-c(record_id, t, location))  |>
#   ggplot(aes(t, value, color = location, fill = location)) +
#   geom_smooth(span = 1.5) +
#   # geom_point() + 
#   facet_grid(name ~ location, scales = "free_x") 
#   # coord_cartesian(ylim = c(0,0.5), xlim = c(0,30))


# try to fit multistate models

library(cmdstanr)
library(bayesplot)

df_mod <-
df |>
  filter(source == "Human") |>
  group_by(record_id) |>
  mutate(t = as.numeric(difftime(date_collected, min(date_collected), units = "days")),
	 e_coli = if_else(e_coli == "Yes", 1, 0)) |>
  arrange(record_id, t) |>
  filter(!is.na(e_coli)) |>
  mutate(t_start = lag(t),
	 t_end = t,
	 state_end = e_coli,
	 state_start = lag(state_end)) |>
  select(record_id, location, t_start, t_end, state_start, state_end) |>
  filter(!is.na(t_start))

location_lookup <-
df_mod |> 
  ungroup() |>
  select(location) |>
  unique() |>
  mutate(location_id = 1:n())


mod_bin <- cmdstan_model(here("R/msm/tracs_msm_mod_nocovs.stan"))

mod_list <-
  list(
    debug = 0,
    N = length(unique(df_mod$record_id)),
    n = nrow(df_mod),
    N_sites = length(unique(df_mod$location)),
    n_obs = df_mod |>
      group_by(record_id) |>
      summarise(n_obs = n()) |>
      pull(n_obs),
    t_start = df_mod$t_start,
    t_end = df_mod$t_end,
    state_start = df_mod$state_start,
    state_end = df_mod$state_end,
    #covs = as.matrix(rep(c(0), nrow(df_mod))),
    site = df_mod |>
      left_join(location_lookup, by = "location") |>
      pull(location_id)
    )

model_fit <- mod_bin$sample(
  data = mod_list,
  chains = 4,
  iter_warmup = 1000,
  iter_sampling = 1000,
  refresh = 100,
  # adapt_delta = 0.99,
  # step_size = step_size,
  # max_treedepth = 15,
  parallel_chains = 4
  # output_dir = here("data")
)

model_fit

mcmc_dens(model_fit$draws())

mcmc_intervals(model_fit$draws(), prob_outer = 0.95, prob = 0.5, outer_size = 10, inner_size = 10, regex_pars = "q|a0|a")

mcmc_intervals_data(model_fit$draws(), regex_pars = "q|a0|a1", prob_outer = 0.95)

mcmc_trace(model_fit$draws())

mcmc_areas_ridges(model_fit$draws(), prob_outer = 0.95, prob = 0.5, outer_size = 10, inner_size = 10, regex_pars = "a0")
# sims


# state transition and antibiotic effects
q <- function(q01, q10, b01, b10) {
  q <- matrix(
    data = c(-q01 * exp(b01), q01 * exp(b01), q10 * exp(b10), -q10 * exp(b10)),
    byrow = TRUE,
    nrow = 2,
    ncol = 2
  )
  return(q)
}

#given an inital probability of being in state 1 initial_p1,
#q matrix q and time t, output the probabiity of being in state 1 at time t
pr_state1 <- function(initial_p1, q, t) {
  f <- matrix(
    data = c(1 - initial_p1, initial_p1),
    ncol = 2, nrow = 1, byrow = TRUE
  )
  return((f %*% expm(q * t))[1, 2])
}



t_steps <- 0:50

sims_list_full_posterior <- list()
sims_list_summary <- list()
print("Simulating from posterior ...")



  sims_df <- 
    expand_grid(
      t = 1:30,
      model_fit$draws(
        format = "draws_matrix"
      ) |>
        as_tibble(rownames = "draw") |>
        janitor::clean_names() |>
        select(matches("draw|q_|a01")) |>
        pivot_longer(-c(draw, q_1, q_2))
    ) |>
    rowwise() |>
    mutate(
	   pr_1 = pr_state1(
      initial_p1 = 0,
      q = q(q_1, q_2, value, 0),
      t = t
    ))





  sim_df_summary <-
    sims_df |>
    ungroup() |>
    group_by(name, t) |>
    summarise(
      pr_1_med = median(pr_1),
      lci = quantile(pr_1, 0.25),
      llci = quantile(pr_1, 0.025),
      uci = quantile(pr_1, 0.75),
      uuci = quantile(pr_1, 0.0975),
      .groups = "keep"
    ) 


    sim_df_summary |>
      ggplot(aes(t,pr_1_med, ymin = lci, ymax = uci, color = name, fill = name)) +
      geom_line() +
      geom_ribbon(alpha = 0.2, color = NA) +
      # geom_ribbon(x  = t,  ymin = llci, ymax = uuci, alpha = 0.2, color = NA, data = sdf2) + 
      facet_wrap(~ fct_reorder(name, pr_1_med, max), nrow = 1) +
      theme_bw() +
      labs(color = "site", fill = "site", x = "t (days)", y = "Pr(colonised)")

    ### participant characteristics


#
# df <-
#   read_csv(here("data/processed/micro/micro_processed20240828-1524.csv")) |>
#   mutate(
#     esbl = if_else(e_coli == "Yes" | k_pn == "Yes", "Yes", "No"),
#     sample_type = case_when(
#       grepl("E", tracs_id) ~ "Environmental",
#       grepl("PS", tracs_id) ~ "Patient",
#       grepl("HS", tracs_id) ~ "Hand swab",
#       TRUE ~ "Unknown"
#     )
#   )

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


df_pt_metadata <-
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
  ) 

df_pt_metadata |>
  select(age, mean_cfs, mean_cds, animal_exp, overseas_travel, hospital_admissions, abx, location) |>
  group_by(location) |>
  summarise(
    age_mean = mean(age,
      na.rm = TRUE
    ),
    cfs = mean(mean_cfs),
    cds = mean(mean_cds,
      na.rm = TRUE
    ),
	    hosp = sum(hospital_admissions == "Yes") / length(hospital_admissions),
abx = sum(abx == "Yes")/ length(abx)
  )

df_pt_metadata |>
  mutate(
  location = case_when(
		       grepl("Whiston", location) ~ "Whiston",
		       grepl("Broad Green", location) ~ "Broad Green",
		       TRUE ~ location)) |>
  filter(!grepl("Ward 17B|Ward 29|Ward 9", location)) |>
  tbl_summary(
    include = c(age, mean_cfs, mean_cds, animal_exp, overseas_travel, hospital_admissions, abx),
    by = location, # split table by group
    missing = "no" # don't list missing data separately
  ) |> 
  add_n() |> # add column with total number of non-missing observations
  add_p() |> # test for a difference between groups
  modify_header(label = "**Variable**") |> # update the column header
  bold_labels() 

# ? add abx exposure and CFS as covariates

# plot abx exposures
# we want days per person-day of exposure

df_abx_exp_summary <-
df_abx |>
  left_join(
df_pt_metadata |>
  # mutate(record_id = paste0(record_id, "_PS")) |>
  transmute(record_id = record_id,recruit_date = date_of_approach, location) |>
  unique() ,
by = "record_id") |>
  left_join(
df |>
  filter(source == "Human") |>
  select(record_id,date_collected) |>
  group_by(record_id) |>
  summarise(max_sample_date = max(date_collected)) |>
  mutate(record_id = as.numeric(gsub("_PS", "", record_id)))
) |>
  mutate(
	 t_start = as.numeric(difftime(abx_start_date, recruit_date, units = "days")),
	 t_end = as.numeric(difftime(abx_end_date, recruit_date, units = "days")),
	 t_max_sample = as.numeric(difftime(max_sample_date, recruit_date, units = "days"))
	 ) |>
  select(record_id, abx_name, abx_other, t_start, t_end, t_max_sample,location) |>
  filter(t_end >= 0) |>
  filter(t_start <= t_max_sample) |>
  mutate(t_end = if_else(t_end > t_max_sample, t_max_sample, t_end)) |>
  mutate(t_start = if_else(t_start < 0, 0, t_start)) |>
  mutate(days_of_exposure = t_end - t_start + 1) |>
  mutate(
  location = case_when(
		       grepl("Whiston", location) ~ "Whiston",
		       grepl("Broad Green", location) ~ "Broad Green",
		       TRUE ~ location)) |>
  filter(!grepl("Ward 17B|Ward 29|Ward 9", location)) |>
  group_by(location, abx_name) |>
  summarise(total_days_exposure = sum(days_of_exposure)) |>
  left_join(
df |>
  filter(source == "Human") |>
  ungroup() |>
  group_by(record_id, location) |>
  summarise(fu_time = max(as.numeric(difftime(date_collected, min(date_collected, na.rm = TRUE), units = "days")))) |>
  mutate(location = str_to_title(location)) |>
  group_by(location) |>
  summarise(total_fu_time = sum(fu_time, na.rm = TRUE)),
by = "location"
) |>
  mutate(abx_day_per_person_day = total_days_exposure/ total_fu_time) 

df_abx_exp_summary |> 
  group_by(location, total_fu_time) |>
  summarise(total_days_abx = sum(total_days_exposure, na.rm = TRUE)) |>
  rowwise() |>
  mutate(total_abx_per_person_day = total_days_abx / total_fu_time,
	 lci = binom.test(total_days_abx, total_fu_time)$conf.int[[1]],
	 uci = binom.test(total_days_abx, total_fu_time)$conf.int[[2]]) |>
  ggplot(aes(fct_reorder(location, total_abx_per_person_day), total_abx_per_person_day, ymin = lci, ymax = uci)) +
  geom_point() +
  geom_errorbar(width = 0) + 
  coord_flip()

df_abx_exp_summary |>
  rowwise() |>
mutate(
	 lci = binom.test(total_days_exposure, total_fu_time)$conf.int[[1]],
	 uci = binom.test(total_days_exposure, total_fu_time)$conf.int[[2]]) |>
  ggplot(aes(fct_reorder(abx_name, abx_day_per_person_day), abx_day_per_person_day, color = location, ymin = lci, ymax = uci)) +
  geom_point() +
  geom_errorbar(width = 0) + 
  facet_wrap(~ location) +
  coord_flip()

