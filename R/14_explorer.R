# Data for the occupation explorer: one row per ANZSCO v1.2 unit group, written as
# data/out/explorer_units.csv and as explorer/explorer_units.json with the same fields.
# Every field the page displays is a column here. AIOE is not included (aggregate use only).

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(jsonlite)
})
source("R/utils.R")
source("R/fn_analysis.R")

emp <- read_codes_csv(interim_path("emp_units.csv"))
earn <- read_codes_csv(interim_path("earnings_units.csv"))
jsa <- read_codes_csv(interim_path("jsa_units.csv"))
grades <- read_codes_csv(interim_path("unit_grades.csv"))
long <- read_codes_csv(interim_path("unit_measures_long.csv"))
w <- read_codes_csv(interim_path("unit_soc_weights_all_schemes.csv")) |> filter(scheme == "s1")
socm <- read_codes_csv(interim_path("soc_measures.csv"))
links1 <- read_codes_csv(interim_path("links_scheme1_isco.csv"))

major_names <- c(`1` = "Managers", `2` = "Professionals", `3` = "Technicians and Trades Workers",
                 `4` = "Community and Personal Service Workers", `5` = "Clerical and Administrative Workers",
                 `6` = "Sales Workers", `7` = "Machinery Operators and Drivers", `8` = "Labourers")

s1 <- long |> filter(scheme == "s1") |>
  select(unit, measure, score, extensive) |>
  pivot_wider(names_from = measure, values_from = c(score, extensive)) |>
  transmute(unit, usage = score_usage_exposure, extensive = extensive_usage_exposure,
            eloundou_beta = score_beta_gpt4, global_automation_pct = score_global_automation_pct)

scheme_range <- long |> filter(measure == "usage_exposure", !is.na(score)) |>
  group_by(unit) |> summarise(usage_min_schemes = min(score), usage_max_schemes = max(score), .groups = "drop")

# Employment-weighted quintile band of usage-based exposure (1 = lowest fifth).
band <- emp |> select(unit, emp) |> inner_join(s1 |> filter(!is.na(usage)) |> select(unit, usage), by = "unit") |>
  mutate(usage_band = pmin(5, floor(weighted_rank(usage, emp) * 5) + 1)) |>
  select(unit, usage_band)

socs <- w |>
  left_join(socm |> select(soc, soc_title = title, soc_usage = usage_exposure), by = "soc") |>
  arrange(unit, desc(w_norm)) |>
  group_by(unit) |>
  summarise(contributing_socs = paste(sprintf("%s %s (weight %.2f, exposure %.2f)", soc, soc_title, w_norm, soc_usage), collapse = "; "),
            .groups = "drop")
unscored <- links1 |> anti_join(w, by = c("unit", "soc")) |> count(unit, name = "linked_socs_without_score")

fmt2 <- function(x) case_when(is.na(x) ~ "", x > 0 & x < 0.005 ~ "<0.01", TRUE ~ sprintf("%.2f", x))

explorer <- emp |>
  transmute(unit, title, major_group = unname(major_names[substr(unit, 1, 1)]),
            employment_000 = round(emp, 1), employment_wa_000 = round(emp_wa, 1)) |>
  left_join(s1, by = "unit") |>
  left_join(band, by = "unit") |>
  left_join(scheme_range, by = "unit") |>
  left_join(jsa |> select(unit, jsa_automation, jsa_augmentation), by = "unit") |>
  left_join(earn |> select(unit, eeh_weekly_earnings = eeh_weekly_p, eeh_imputed), by = "unit") |>
  left_join(grades |> select(unit, crosswalk_grade = grade, n_scored_socs = n_valid, unscored_weight_share), by = "unit") |>
  left_join(socs, by = "unit") |>
  left_join(unscored, by = "unit") |>
  mutate(
    below_usage_threshold = !is.na(usage) & usage == 0,
    usage_display = fmt2(usage),
    usage_range_display = if_else(is.na(usage_min_schemes), "", paste(fmt2(usage_min_schemes), "to", fmt2(usage_max_schemes))),
    extensive_display = fmt2(extensive),
    eloundou_display = fmt2(eloundou_beta),
    global_automation_display = if_else(is.na(global_automation_pct), "", sprintf("%.0f%%", global_automation_pct)),
    eeh_weekly_earnings = round(eeh_weekly_earnings),
    earnings_note = if_else(eeh_imputed == "none", "", "imputed from minor group"),
    linked_socs_without_score = coalesce(linked_socs_without_score, 0L),
    contributing_socs = coalesce(contributing_socs, ""),
    unscored_share_display = if_else(is.na(unscored_weight_share), "", sprintf("%.0f%%", 100 * unscored_weight_share))
  ) |>
  select(unit, title, major_group, usage_display, usage_band, below_usage_threshold, usage_range_display,
         extensive_display, jsa_automation, jsa_augmentation, eloundou_display, global_automation_display,
         employment_000, employment_wa_000, eeh_weekly_earnings, earnings_note, crosswalk_grade, n_scored_socs,
         linked_socs_without_score, unscored_share_display, contributing_socs) |>
  arrange(unit)

stopifnot(nrow(explorer) == 358, !anyDuplicated(explorer$unit), !any(grepl("aioe", names(explorer), ignore.case = TRUE)))
write_csv(explorer, out_path("explorer_units.csv"), na = "")
dir.create(file.path(project_root(), "explorer"), showWarnings = FALSE)
write_json(explorer, file.path(project_root(), "explorer", "explorer_units.json"), na = "null", auto_unbox = TRUE, digits = NA)
message("Explorer rows: ", nrow(explorer))
