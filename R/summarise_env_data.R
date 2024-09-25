library(tidyverse)
library(here)

df_loc <- read_csv(
  here("data/processed/micro/micro_env_sample_loc20240828-1752.csv")
) |>
  select(location, site_number, swab_site, swab_number) |>
  unique()

df_res <- read_csv(
  here("data/processed/micro/micro_processed20240828-1524.csv")
)

names(df_loc)

names(df_res)

df_loc |>
  left_join(
    select(df_res, tracs_id, e_coli, k_pn),
    by = join_by(swab_number == tracs_id)
  ) |>
  count(swab_site) |>
  as.data.frame()

df <-
  df_loc |>
  left_join(
    select(df_res, tracs_id, e_coli, k_pn),
    by = join_by(swab_number == tracs_id)
  ) |>
  mutate(
    swab_site_recode =
      case_when(
        grepl("[s|S]ink|[b|B]asin", swab_site) ~ "sink",
        grepl("[T|t]oilet", swab_site) ~ "toilet",
        grepl("[S|s]hower|[B|bath]", swab_site) ~ "bath_or_shower",
        TRUE ~ "other"
      ),
    location_id = paste0(str_extract(location, "^.{2}"), site_number),
    esbl = if_else(e_coli == "Yes" | k_pn == "Yes", "Yes", "No")
  )

df |>
  group_by(swab_site_recode) |>
  summarise(
    n_swabs = sum(!is.na(esbl)),
    n_esbl = sum(esbl == "Yes", na.rm = TRUE),
    prop = n_esbl / n_swabs
  )

df |>
  group_by(location_id, swab_site_recode) |>
  summarise(any_esbl = any(esbl == "Yes", na.rm = TRUE)) |>
  ungroup() |>
  count(swab_site_recode)

df |>
  group_by(location_id, swab_site_recode) |>
  summarise(any_esbl = any(esbl == "Yes", na.rm = TRUE)) |>
  ungroup() |>
  group_by(swab_site_recode) |>
  summarise(
    n_sites = sum(!is.na(any_esbl)),
    n_esbl = sum(any_esbl, na.rm = TRUE),
    prop = n_esbl / n_sites
  )

df |>
  ggplot(aes(swab_site_recode, fill = esbl)) +
  geom_bar(position = "fill")
