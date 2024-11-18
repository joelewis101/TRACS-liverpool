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
