library(tidyverse)
library(here)


df <-
  read_tsv(here("data/processed/sequencing/json_summary.tsv"),
    col_names = c("sample", "reads_before_filter", "reads_after_filter")
  ) |>
  mutate(
    sample =
      str_extract(sample, "(?<= )[0-9].+(?=\\.fastq.gz -I)"),
      dropped_reads = reads_before_filter - reads_after_filter
  ) 

df |>
  select(-reads_before_filter) |>
  pivot_longer(-sample) |>
  ggplot(aes(fct_reorder(sample,value), value, color = name, fill = name)) +
  geom_col() 

# what is an appropriate read cutoff?
# probably depth < 20 over a 4.5Mb genome?
# ie x * 150 > 4.5e6 * 20 = 0.6e6

df |> 
  filter(reads_after_filter < 0.6e6)

