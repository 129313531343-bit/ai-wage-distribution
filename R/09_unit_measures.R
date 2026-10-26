# Unit-level measures under each weighting scheme (method A).
#   Scheme 1: primary ISCO chain, OEWS employment weights (primary)
#   Scheme 2: primary ISCO chain, equal weights
#   Scheme 3: title-match-first links, OEWS weights
#   Scheme 4: JSA/LMI correspondence links, OEWS weights (decision D2)
# Measures: usage-based exposure (with extensive margin and intensity), Eloundou beta (GPT-4
# and human ratings), global Claude.ai automation share. AIOE is computed for aggregate use
# only and written to a NOT_FOR_PUBLICATION file.
# Also writes coverage (choice C4), the unmatched list and the crosswalk grade of every unit.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(purrr)
})
source("R/utils.R")
source("R/fn_exposure.R")

soc_measures <- read_codes_csv(interim_path("soc_measures.csv"))
soc_w <- read_codes_csv(interim_path("soc_weights_oews.csv")) |> select(soc, w)
v12_units <- read_codes_csv(interim_path("v12_units.csv"))
emp <- read_codes_csv(interim_path("emp_units.csv"))

schemes <- list(
  s1 = list(label = "1 OEWS employment (primary)", links = read_codes_csv(interim_path("links_scheme1_isco.csv")), weights = soc_w),
  s2 = list(label = "2 equal weights", links = read_codes_csv(interim_path("links_scheme1_isco.csv")), weights = NULL),
  s3 = list(label = "3 title-match-first", links = read_codes_csv(interim_path("links_scheme3_title.csv")), weights = soc_w),
  s4 = list(label = "4 JSA/LMI correspondence", links = read_codes_csv(interim_path("links_scheme4_lmi.csv")), weights = soc_w)
)
measures <- c("usage_exposure", "beta_gpt4", "beta_human", "global_automation_pct")

long <- imap_dfr(schemes, function(s, key) {
  map_dfr(measures, function(m) {
    unit_scores(s$links, soc_measures, m, s$weights) |> mutate(scheme = key, scheme_label = s$label, measure = m)
  })
})

weights_all <- imap_dfr(schemes, function(s, key) {
  unit_weights(s$links, soc_measures, "usage_exposure", s$weights) |> mutate(scheme = key)
})

# Grade of each unit: number of linked SOCs with usage-based exposure under scheme 1.
# Also the share of the unit's linked US employment (OEWS) that has no usage-based score: when
# it is large, the unit's value rests on a minority of its US counterparts (added in the D10
# review, after the first results).
unscored <- schemes$s1$links |>
  distinct(unit, soc) |>
  inner_join(soc_w, by = "soc") |>
  left_join(soc_measures |> select(soc, usage_exposure), by = "soc") |>
  group_by(unit) |>
  summarise(unscored_weight_share = sum(w[is.na(usage_exposure)]) / sum(w), .groups = "drop")
grades <- long |>
  filter(scheme == "s1", measure == "usage_exposure") |>
  select(unit, n_valid, grade) |>
  left_join(unscored, by = "unit")

# AIOE, aggregate use only.
aioe <- read_codes_csv(interim_path("aioe_soc_NOT_FOR_PUBLICATION.csv")) |> rename(soc = soc_aioe)
links_aioe <- read_codes_csv(interim_path("links_aioe_soc2010_NOT_FOR_PUBLICATION.csv")) |> rename(soc = soc2010)
w2010 <- read_codes_csv(interim_path("soc2010_weights_oews.csv")) |> rename(soc = soc2010)
aioe_units <- bind_rows(
  unit_scores(links_aioe, aioe, "aioe", w2010) |> mutate(measure = "aioe"),
  unit_scores(links_aioe, aioe, "lm_aioe", w2010) |> mutate(measure = "lm_aioe")
)

# Coverage (C4) and the unmatched list.
covered <- grades |> filter(n_valid > 0) |> pull(unit)
coverage <- emp |>
  summarise(emp_total = sum(emp), emp_covered = sum(emp[unit %in% covered]),
            units_total = n(), units_covered = sum(unit %in% covered)) |>
  mutate(coverage_share = emp_covered / emp_total, target = 0.98, meets_target = coverage_share >= target)
unmatched <- emp |>
  filter(!unit %in% covered) |>
  transmute(unit, title, emp_000 = emp, emp_share = emp_share) |>
  arrange(desc(emp_000))

dir.create(out_path(), showWarnings = FALSE)
write_csv(long, interim_path("unit_measures_long.csv"))
write_csv(weights_all, interim_path("unit_soc_weights_all_schemes.csv"))
write_csv(grades, interim_path("unit_grades.csv"))
write_csv(aioe_units, interim_path("aioe_units_NOT_FOR_PUBLICATION.csv"))
write_csv(coverage, out_path("coverage.csv"))
write_csv(unmatched, out_path("unmatched_units.csv"))

print(coverage)
print(count(grades, grade))
print(long |> group_by(scheme, measure) |> summarise(units_with_value = sum(!is.na(score)), .groups = "drop") |>
        tidyr::pivot_wider(names_from = measure, values_from = units_with_value))
