# The unit table used by every analysis script: employment, earnings, potential measures and
# crosswalk grades for each ANZSCO v1.2 unit, plus the usage-based measures under one scheme.

suppressPackageStartupMessages({
  library(dplyr)
})

unit_table <- function() {
  emp <- read_codes_csv(interim_path("emp_units.csv"))
  earn <- read_codes_csv(interim_path("earnings_units.csv"))
  jsa <- read_codes_csv(interim_path("jsa_units.csv"))
  grades <- read_codes_csv(interim_path("unit_grades.csv"))
  aioe_units <- read_codes_csv(interim_path("aioe_units_NOT_FOR_PUBLICATION.csv"))
  emp |>
    select(unit, title, emp, emp_male, emp_female, emp_wa) |>
    left_join(earn |> select(unit, eeh_weekly_p, eeh13_hourly_p, ato_avg_sw, eeh_rse_max), by = "unit") |>
    left_join(jsa |> select(unit, jsa_automation, jsa_augmentation), by = "unit") |>
    left_join(grades |> select(unit, grade, n_valid, unscored_weight_share), by = "unit") |>
    left_join(aioe_units |> filter(measure == "aioe") |> select(unit, aioe = score), by = "unit")
}

# Usage-based exposure and the SOC-level comparison measures for one weighting scheme.
scheme_values <- function(long, s) {
  l <- long |> filter(scheme == s)
  l |> filter(measure == "usage_exposure") |> select(unit, usage = score, extensive, intensity, usage_lb = score_lb) |>
    left_join(l |> filter(measure == "beta_gpt4") |> select(unit, beta_gpt4 = score, beta_ext = extensive), by = "unit") |>
    left_join(l |> filter(measure == "beta_human") |> select(unit, beta_human = score), by = "unit") |>
    left_join(l |> filter(measure == "global_automation_pct") |> select(unit, global_automation = score), by = "unit")
}

# The specification grid: three earnings rankings (C1, C2) and five samples (C7 and C10; the last
# sample was added after the first results in the D10 review). Needs owner_manager_draft
# (fn_owner_managers.R).
spec_rankings <- c(eeh = "eeh_weekly_p", eeh13 = "eeh13_hourly_p", ato = "ato_avg_sw")
spec_samples <- list(
  all = function(d) d,
  non_diffuse = function(d) filter(d, grade %in% c("one-to-one", "few-to-one")),
  excl_rse25 = function(d) filter(d, is.na(eeh_rse_max) | eeh_rse_max <= 0.25),
  excl_owner_managers = function(d) filter(d, !unit %in% owner_manager_draft),
  excl_unscored_majority = function(d) filter(d, is.na(unscored_weight_share) | unscored_weight_share <= 0.5)
)
