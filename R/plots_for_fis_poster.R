library(tidyverse)
library(here)

df_loc <- read_csv(
  here("data/processed/micro/micro_env_sample_loc20240828-1752.csv")
) |>
  select(location, site_number, swab_site, swab_number, date) |>
  unique()

df_res <- read_csv(
  here("data/processed/micro/micro_processed20240828-1524.csv")
) |> mutate(receipt_date = dmy(receipt_date))

names(df_loc)

names(df_res)

# inner join here because it looks like some of the TRACS_IDS are duplicated in
# df_loc. I guess this is because the swab ID was incorrectly entered in that
# sheet. Needs proprt sort - for now do inner join

df_loc |>
  inner_join(
    select(df_res, receipt_date, tracs_id, e_coli, k_pn),
    by = join_by(swab_number == tracs_id, date == receipt_date)
  ) |>
  nrow()

df <-
  df_loc |>
  inner_join(
    select(df_res, receipt_date, tracs_id, e_coli, k_pn),
    by = join_by(swab_number == tracs_id, date == receipt_date)
  ) |>
  mutate(
    swab_site_recode =
      case_when(
        grepl("[s|S][i|I]nk|[b|B]asin", swab_site) ~ "sink",
        grepl("[T|t]oilet", swab_site) ~ "toilet",
        grepl("[S|s]hower|[B|b]ath", swab_site) ~ "bath_or_shower",
        TRUE ~ "other"
      ),
    location_id = paste0(str_extract(location, "^.{2}"), site_number),
    esbl = if_else(e_coli == "Yes" | k_pn == "Yes", "Yes", "No")
  )

df_participants <-
  left_join(
    read_csv(here("data/processed/redcap/samples_processed20240902-1410.csv")),
    read_csv(here("data/processed/micro/micro_processed20240828-1524.csv")),
    by = join_by(sample_number == tracs_id)
  ) |>
  group_by(record_id) |>
  summarise(
    ecoli = any(e_coli == "Yes", na.rm = TRUE),
    kleb = any(k_pn == "Yes", na.rm = TRUE)
  ) |>
  mutate(esbl = if_else(ecoli | kleb, "Yes", "No"))

bind_rows(
  df |>
    group_by(location_id, swab_site_recode) |>
    summarise(any_esbl = any(esbl == "Yes", na.rm = TRUE)) |>
    ungroup() |>
    group_by(swab_site_recode) |>
    transmute(
      swab_type = swab_site_recode,
      esbl = any_esbl
    ),
  df_participants |>
    transmute(
      swab_type = "participant",
      esbl = esbl == "Yes"
    )
) |>
  mutate(esbl = if_else(esbl, "Present", "Absent")) |>
  ggplot(aes(fct_reorder(swab_type, esbl, \(x)sum(x == "Present") / length(x)), fill = esbl)) +
  geom_bar(position = "fill") +
  theme_bw() +
  scale_fill_viridis_d(option = "cividis") +
  coord_flip() +
  labs(x = "", y = "Proportion", fill = "ESBL/CPE", title = "Figure 2: Prevalance of 3GCR-E by sample type") +
  theme(text = element_text(size = 80), legend.position = "bottom")

ggsave("fis_plot.pdf", width = 40, height = 15, limitsize = FALSE)

bind_rows(
  df |>
    group_by(location_id, swab_site_recode) |>
    summarise(any_esbl = any(esbl == "Yes", na.rm = TRUE)) |>
    ungroup() |>
    group_by(swab_site_recode) |>
    transmute(
      swab_type = swab_site_recode,
      esbl = any_esbl
    ),
  df_participants |>
    transmute(
      swab_type = "participant",
      esbl = esbl == "Yes"
    )
) |>
  group_by(swab_site_recode) |>
  summarise(prop = sum(esbl) / length(esbl))

bind_rows(
  df |>
    group_by(location, location_id, swab_site_recode) |>
    summarise(any_esbl = any(esbl == "Yes", na.rm = TRUE)) |>
    ungroup() |>
    group_by(location, swab_site_recode) |>
    transmute(
      location = location,
      swab_type = swab_site_recode,
      esbl = any_esbl
    ),
  left_join(
    read_csv(here("data/processed/redcap/samples_processed20240902-1410.csv")),
    read_csv(here("data/processed/micro/micro_processed20240828-1524.csv")),
    by = join_by(sample_number == tracs_id)
  ) |>
    group_by(location, record_id) |>
    summarise(
      ecoli = any(e_coli == "Yes", na.rm = TRUE),
      kleb = any(k_pn == "Yes", na.rm = TRUE)
    ) |>
    mutate(esbl = if_else(ecoli | kleb, "Yes", "No")) |>
    group_by(location, record_id) |>
    summarise(esbl = any(esbl == "Yes", na.rm = TRUE)) |>
    transmute(
      location = location,
      swab_type = "participant",
      esbl = esbl
    )
) |>
  mutate(
    location = case_when(
      location %in% c(
        "Aintree", "Broad Green"
      ) ~ "Hospital DMOPS ward",
      location %in% c("Estuary house", "Walton Manor") ~ "Care home",
      location %in% c("Whiston") ~ "Frailty Unit",
      location %in% c("Longmoor house") ~ "Intermediate care",
      TRUE ~ location
    )
  ) |>
  group_by(location, swab_type) |>
  summarise(
    n = sum(esbl),
    tot = length(esbl)
  ) |>
  rowwise() |>
  mutate(
    prop = n / tot,
    lci = binom.test(n, tot)$conf.int[[1]],
    uci = binom.test(n, tot)$conf.int[[2]]
  ) |>
  # filter(swab_type == "participant", !is.na(location)) |>
  filter(!is.na(location)) |>
  mutate(swab_type = factor(swab_type,
    levels = c("participant", "sink", "toilet", "bath_or_shower", "other")
  )) |>
  ggplot(aes(location, prop, ymin = lci, ymax = uci)) +
  geom_point() +
  geom_errorbar(width = 0) +
  theme_bw() +
  theme(text = element_text(size = 14), axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_wrap(. ~ swab_type, nrow = 1) +
  coord_flip() +
  labs(y = "Proportion", x = "") -> a

ggsave("fis_plot2.pdf", a, width = 8, height = 2, limitsize = FALSE)

