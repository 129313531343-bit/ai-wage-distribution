# Review tables for Luc's sign-off (M2): the 40 largest units by pooled employment, with
# their linked SOCs and weights under scheme 1, the value under every scheme, and the grade.
# Also a one-row summary of the primary chain against the 2022-path validation chain.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
})
source("R/utils.R")

emp <- read_codes_csv(interim_path("emp_units.csv"))
long <- read_codes_csv(interim_path("unit_measures_long.csv"))
w <- read_codes_csv(interim_path("unit_soc_weights_all_schemes.csv"))
socm <- read_codes_csv(interim_path("soc_measures.csv"))
jsa <- read_codes_csv(interim_path("jsa_units.csv"))
grades <- read_codes_csv(interim_path("unit_grades.csv"))
validation <- read_codes_csv(out_path("m2", "chain_validation_primary_vs_2022path.csv"))

top40 <- emp |> slice_max(emp, n = 40, with_ties = FALSE) |> select(unit, title, emp_000 = emp, emp_share)

by_scheme <- long |>
  filter(measure == "usage_exposure", unit %in% top40$unit) |>
  select(unit, scheme, score) |>
  pivot_wider(names_from = scheme, values_from = score, names_prefix = "usage_exposure_")

s1 <- long |> filter(measure == "usage_exposure", scheme == "s1") |> select(unit, extensive, intensity)

top_socs <- w |>
  filter(scheme == "s1", unit %in% top40$unit) |>
  left_join(socm |> select(soc, soc_title = title, usage_exposure), by = "soc") |>
  group_by(unit) |>
  arrange(desc(w_norm), .by_group = TRUE) |>
  summarise(
    n_socs = n(),
    top_socs = paste(head(sprintf("%s %s (w %.2f, e %.2f)", soc, soc_title, w_norm, usage_exposure), 5), collapse = " | "),
    .groups = "drop"
  )

review <- top40 |>
  left_join(grades |> select(unit, grade), by = "unit") |>
  left_join(by_scheme, by = "unit") |>
  left_join(s1, by = "unit") |>
  left_join(jsa |> select(unit, jsa_automation, jsa_augmentation), by = "unit") |>
  left_join(top_socs, by = "unit") |>
  mutate(across(where(is.double) & !c(emp_000, emp_share), ~ round(.x, 3)),
         emp_000 = round(emp_000, 1), emp_share = round(emp_share, 4),
         luc_signoff = "", luc_note = "")

dir.create(out_path("m2"), recursive = TRUE, showWarnings = FALSE)
write_csv(review, out_path("m2", "top40_units_review.csv"))

val_summary <- validation |>
  summarise(units = n(), identical_link_sets = sum(jaccard == 1, na.rm = TRUE),
            differ = sum(jaccard < 1, na.rm = TRUE), median_jaccard = median(jaccard, na.rm = TRUE))
write_csv(val_summary, out_path("m2", "chain_validation_summary.csv"))
message("Top-40 units cover ", round(100 * sum(top40$emp_share), 1), "% of employment")
print(count(review, grade))
