# D10: automated review of the 40 largest units (decision D11).
# Each unit is run through the same checks; each flag gets a resolution and a reason, applied by
# the rules below. Mapping links come from official concordances and are never hand-edited.
#
#   unmatched      no linked SOC has a usage-based score     -> keep as missing (never zero)
#   zero           score is exactly 0 (below usage gate)     -> keep; flagged in explorer and note
#   diffuse        5 or more scored linked SOCs              -> keep; non-diffuse sensitivity covers it
#   scheme range   max - min across schemes above 0.10      -> keep scheme 1 (fixed primary); range shown
#   influence      leaving the unit out moves the main top-minus-bottom gap by more than 1 pp,
#                  or the decile-profile Spearman with the full sample falls below 0.9
#                                                            -> keep; leave-one-out result reported
#   artefact       a flagged artefact SOC has weight >= 0.25 -> keep; artefact disclosed in limitations
#   unscored       over half of linked US (OEWS) employment has no score -> keep; extra sensitivity run
#   title check    no title word in common between the unit (or its occupations) and its
#                  highest-weight SOC                        -> inspect; resolution recorded below
# Writes data/out/m2/top40_units_review.csv (overwrites the earlier sign-off template).

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(purrr)
})
source("R/utils.R")
source("R/fn_analysis.R")
source("R/fn_titles.R")

emp <- read_codes_csv(interim_path("emp_units.csv"))
earn <- read_codes_csv(interim_path("earnings_units.csv"))
long <- read_codes_csv(interim_path("unit_measures_long.csv"))
w <- read_codes_csv(interim_path("unit_soc_weights_all_schemes.csv")) |> filter(scheme == "s1")
socm <- read_codes_csv(interim_path("soc_measures.csv"))
grades <- read_codes_csv(interim_path("unit_grades.csv"))
c6 <- read_codes_csv(interim_path("v12_codes6.csv"))

artefact_socs <- c("41-2031", "43-6012", "23-2011", "35-3011", "23-1011")

s1 <- long |> filter(scheme == "s1", measure == "usage_exposure") |> select(unit, usage = score)
rng <- long |> filter(measure == "usage_exposure") |> select(unit, scheme, score) |>
  pivot_wider(names_from = scheme, values_from = score, names_prefix = "usage_")
base <- emp |> select(unit, title, emp, emp_share) |> left_join(earn |> select(unit, eeh_weekly_p), by = "unit") |>
  left_join(s1, by = "unit")

profile <- function(d) {
  dm <- decile_means(fractional_deciles(d, "eeh_weekly_p", "emp"), d, "usage") |> arrange(decile)
  list(tmb = 100 * (last(dm$mean) - first(dm$mean)), means = dm$mean)
}
full <- profile(base)

top40 <- base |> slice_max(emp, n = 40, with_ties = FALSE)

loo <- map_dfr(top40$unit, function(u) {
  p <- profile(filter(base, unit != u))
  tibble(unit = u, loo_tmb_change_pp = p$tmb - full$tmb,
         loo_profile_spearman = cor(p$means, full$means, method = "spearman"))
})
checks <- top40 |>
  left_join(rng, by = "unit") |>
  left_join(grades |> select(unit, grade, n_valid, unscored_weight_share), by = "unit") |>
  left_join(loo, by = "unit") |>
  rowwise() |>
  mutate(scheme_range = { v <- c(usage_s1, usage_s2, usage_s3, usage_s4); v <- v[!is.na(v)]; if (length(v)) max(v) - min(v) else NA_real_ }) |>
  ungroup()

top_soc <- w |> group_by(unit) |> slice_max(w_norm, n = 1, with_ties = FALSE) |> ungroup() |>
  left_join(socm |> select(soc, soc_title = title), by = "soc") |> select(unit, top_soc = soc, top_soc_title = soc_title, top_soc_weight = w_norm)
artefact_w <- w |> filter(soc %in% artefact_socs) |> group_by(unit) |> summarise(artefact_weight = sum(w_norm), .groups = "drop")
anz_titles <- bind_rows(emp |> transmute(unit, t = title), c6 |> filter(!nfd) |> transmute(unit = substr(code, 1, 4), t = title)) |>
  group_by(unit) |> summarise(tokens = list(unique(unlist(title_tokens(t)))), .groups = "drop")

checks <- checks |>
  left_join(top_soc, by = "unit") |>
  left_join(artefact_w, by = "unit") |>
  left_join(anz_titles, by = "unit") |>
  mutate(
    artefact_weight = coalesce(artefact_weight, 0),
    title_overlap = map2_lgl(tokens, top_soc_title, ~ !is.na(.y) && length(intersect(.x, unlist(title_tokens(.y)))) > 0),
    flag_unmatched = is.na(usage),
    flag_zero = !is.na(usage) & usage == 0,
    flag_diffuse = grade == "diffuse",
    flag_scheme_range = !is.na(scheme_range) & scheme_range > 0.10,
    flag_influence = abs(loo_tmb_change_pp) > 1 | loo_profile_spearman < 0.9,
    flag_artefact = artefact_weight >= 0.25,
    flag_unscored = !is.na(unscored_weight_share) & unscored_weight_share > 0.5,
    flag_title = !flag_unmatched & !title_overlap
  ) |>
  select(-tokens)

resolutions <- c(
  flag_unmatched = "Kept as missing: no linked US occupation has a score; never set to zero; listed in the unmatched table.",
  flag_zero = "Kept: zero means below the source's usage gate; flagged 'below usage threshold' in the explorer.",
  flag_diffuse = "Kept: value averages five or more US occupations; the non-diffuse sensitivity run excludes it.",
  flag_scheme_range = "Kept the scheme 1 value (primary, fixed before results); the range across schemes is shown in the explorer and appendix.",
  flag_influence = "Kept: leave-one-out change to the main top-minus-bottom gap is reported in the appendix.",
  flag_artefact = "Kept: a flagged artefact US occupation carries at least a quarter of the weight; disclosed in the limitations.",
  flag_unscored = "Kept under method A (weights renormalised over scored US occupations), but most linked US employment has no score; a sensitivity run excludes such units (added after results) and the explorer shows the share.",
  flag_title = "Inspected: highest-weight US occupation shares no title word with the unit; link comes from the official ISCO concordances and is kept."
)
flag_cols <- names(resolutions)
review <- checks |>
  rowwise() |>
  mutate(
    flags = paste(sub("^flag_", "", flag_cols[c_across(all_of(flag_cols))]), collapse = "; "),
    resolution = if (any(c_across(all_of(flag_cols)))) paste(resolutions[flag_cols[c_across(all_of(flag_cols))]], collapse = " ") else "No flags: kept as is.",
  ) |>
  ungroup() |>
  mutate(reviewed_by = "automated checks",
         across(c(usage, starts_with("usage_"), scheme_range, top_soc_weight, artefact_weight, unscored_weight_share), ~ round(.x, 3)),
         loo_tmb_change_pp = round(loo_tmb_change_pp, 2), loo_profile_spearman = round(loo_profile_spearman, 3),
         emp = round(emp, 1), emp_share = round(emp_share, 4)) |>
  select(unit, title, emp_000 = emp, emp_share, usage_s1 = usage, usage_s2, usage_s3, usage_s4, scheme_range,
         grade, n_valid, unscored_weight_share, top_soc, top_soc_title, top_soc_weight, artefact_weight, loo_tmb_change_pp, loo_profile_spearman,
         all_of(flag_cols), flags, resolution, reviewed_by)

# Notes written after inspecting each flagged unit's linked US occupations.
unit_notes <- tribble(
  ~unit, ~unit_note,
  "6211", "Retail Salespersons (a flagged artefact, 0.32) and Fast Food and Counter Workers (0.00) carry four-fifths of the weight; partial ISCO links in the ABS correspondence add small weights on beauty, teller and postal occupations. Largest single influence on the main profile; leave-one-out result reported.",
  "4231", "The main US counterparts (Home Health Aides, Personal Care Aides) have no score, so the value rests on two supervisor occupations. Excluded in the unscored-majority sensitivity run.",
  "4211", "Title flag is wording only (child carer / childcare worker); the link is the natural US counterpart.",
  "7411", "Title flag is wording only; US stockers and hand material movers are the natural counterparts.",
  "5111", "Closest US occupation (Project Management Specialists) has no score; value rests on business and financial specialist occupations (38% of linked US employment unscored).",
  "8513", "Title flag is wording only; US food preparation workers are the natural counterpart.",
  "3513", "Both links come from ISCO 3434; OEWS weights favour the larger US supervisor occupation over Chefs and Head Cooks.",
  "4311", "Single link to US Bartenders, a flagged artefact with a score of zero.",
  "2713", "Title flag is wording only (solicitor / lawyer); US Lawyers is a flagged artefact.",
  "2531", "Title flag is wording only; US physician occupations, including family medicine, are the counterparts.",
  "5512", "Title flag is wording only (bookkeeper / bookkeeping clerk)."
)
review <- review |> left_join(unit_notes, by = "unit") |> mutate(unit_note = coalesce(unit_note, "")) |>
  relocate(unit_note, .after = resolution)
write_csv(review, out_path("m2", "top40_units_review.csv"))
summary_tbl <- review |> summarise(across(all_of(flag_cols), sum)) |> pivot_longer(everything(), names_to = "check", values_to = "units_flagged")
write_csv(summary_tbl, out_path("m2", "top40_check_summary.csv"))
print(summary_tbl)
print(as.data.frame(review |> filter(flag_title | flag_influence | flag_artefact) |>
  select(unit, title, top_soc_title, top_soc_weight, loo_tmb_change_pp, flags)), row.names = FALSE)
