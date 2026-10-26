# M3 analyses A-D and the sensitivity table. Everything here is descriptive.
#   B: decile profiles of usage-based exposure, extensive margin and intensity; top-minus-bottom
#      gap in percentage points; concentration index.
#   C: usage-potential gap by decile (rank and z-score versions) against JSA automation (C5),
#      JSA augmentation and Eloundou beta; AIOE only in aggregate; correlations; largest
#      disagreements with JSA.
#   D: women and men; WA against national with a decomposition by group; SOC major-group
#      usage-to-employment index for AU, AU-WA and GLOBAL.
# Outputs go to data/out/m3/. AIOE results are aggregate (decile means, correlations) only.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(purrr)
  library(DBI)
  library(duckdb)
})
source("R/utils.R")
source("R/fn_analysis.R")
source("R/fn_owner_managers.R")

out <- function(f) out_path("m3", f)
dir.create(out_path("m3"), recursive = TRUE, showWarnings = FALSE)

emp <- read_codes_csv(interim_path("emp_units.csv"))
earn <- read_codes_csv(interim_path("earnings_units.csv"))
jsa <- read_codes_csv(interim_path("jsa_units.csv"))
grades <- read_codes_csv(interim_path("unit_grades.csv"))
long <- read_codes_csv(interim_path("unit_measures_long.csv"))
aioe_units <- read_codes_csv(interim_path("aioe_units_NOT_FOR_PUBLICATION.csv"))

schemes <- c("s1", "s2", "s3", "s4")
scheme_labels <- long |> distinct(scheme, scheme_label)

# Unit table ------------------------------------------------------------------------
ut <- emp |>
  select(unit, title, emp, emp_male, emp_female, emp_wa) |>
  left_join(earn |> select(unit, eeh_weekly_p, eeh13_hourly_p, ato_avg_sw, eeh_rse_max), by = "unit") |>
  left_join(jsa |> select(unit, jsa_automation, jsa_augmentation), by = "unit") |>
  left_join(grades |> select(unit, grade, n_valid, unscored_weight_share), by = "unit") |>
  left_join(aioe_units |> filter(measure == "aioe") |> select(unit, aioe = score), by = "unit")

scheme_values <- function(s) {
  l <- long |> filter(scheme == s)
  l |> filter(measure == "usage_exposure") |> select(unit, usage = score, extensive, intensity) |>
    left_join(l |> filter(measure == "beta_gpt4") |> select(unit, beta_gpt4 = score), by = "unit") |>
    left_join(l |> filter(measure == "beta_human") |> select(unit, beta_human = score), by = "unit") |>
    left_join(l |> filter(measure == "global_automation_pct") |> select(unit, global_automation = score), by = "unit")
}
sv <- set_names(map(schemes, scheme_values), schemes)

rankings <- c(eeh = "eeh_weekly_p", eeh13 = "eeh13_hourly_p", ato = "ato_avg_sw")
samples <- list(
  all = function(d) d,
  non_diffuse = function(d) filter(d, grade %in% c("one-to-one", "few-to-one")),
  excl_rse25 = function(d) filter(d, is.na(eeh_rse_max) | eeh_rse_max <= 0.25),
  excl_owner_managers = function(d) filter(d, !unit %in% owner_manager_draft),
  # Added after the first results (D10 review): drop units where most linked US employment has no score.
  excl_unscored_majority = function(d) filter(d, is.na(unscored_weight_share) | unscored_weight_share <= 0.5)
)
potentials <- c("jsa_automation", "jsa_augmentation", "beta_gpt4")

# One specification: scheme x sample x ranking ------------------------------------------
run_spec <- function(s, smp, rk) {
  d <- samples[[smp]](ut) |> left_join(sv[[s]], by = "unit")
  dec <- fractional_deciles(d, rankings[[rk]], "emp")
  dm <- decile_means(dec, d, c("usage", "extensive", "beta_gpt4", "jsa_automation", "jsa_augmentation", "global_automation", "aioe")) |>
    select(decile, measure, mean) |>
    pivot_wider(names_from = measure, values_from = mean) |>
    mutate(intensity = usage / extensive)
  dd <- d |> filter(!is.na(.data[[rankings[[rk]]]]), !is.na(usage))
  r <- weighted_rank(dd[[rankings[[rk]]]], dd$emp)
  gaps <- map_dfr(c(potentials, "aioe"), function(p) {
    g <- unit_gap(d, "usage", p)
    dec |> inner_join(g, by = "unit") |>
      group_by(decile) |>
      summarise(gap_rank = sum(emp_share_in_decile * gap_rank) / sum(emp_share_in_decile),
                gap_z = sum(emp_share_in_decile * gap_z) / sum(emp_share_in_decile), .groups = "drop") |>
      mutate(potential = p)
  })
  list(
    deciles = dm |> mutate(scheme = s, sample = smp, ranking = rk),
    gaps = gaps |> mutate(scheme = s, sample = smp, ranking = rk),
    ci = tibble(scheme = s, sample = smp, ranking = rk,
                ci_usage = concentration_index(dd$usage, r, dd$emp),
                ci_extensive = concentration_index(dd$extensive, r, dd$emp)),
    decile_check = dec |> group_by(decile) |> summarise(share = sum(emp_share_in_decile), .groups = "drop") |>
      mutate(scheme = s, sample = smp, ranking = rk)
  )
}

grid <- expand_grid(s = schemes, smp = names(samples), rk = names(rankings))
res <- pmap(grid, run_spec)
deciles <- map_dfr(res, "deciles")
gaps <- map_dfr(res, "gaps")
cis <- map_dfr(res, "ci")
decile_check <- map_dfr(res, "decile_check")

# Concentration indices of the potential measures under the primary ranking (for comparison).
# AIOE is left out: it is a standardised score with negative values, so CI = 2cov/mean is not defined
# in a meaningful way for it.
prim <- ut |> left_join(sv$s1, by = "unit")
ci_potential <- map_dfr(c("usage", "extensive", potentials), function(m) {
  dd <- prim |> filter(!is.na(eeh_weekly_p), !is.na(.data[[m]]))
  tibble(measure = m, ci = concentration_index(dd[[m]], weighted_rank(dd$eeh_weekly_p, dd$emp), dd$emp),
         emp_covered = sum(dd$emp) / sum(prim$emp))
})

# Concentration curves (primary ranking, scheme 1).
curves <- map_dfr(c("usage", "extensive", "jsa_automation", "jsa_augmentation", "beta_gpt4"), function(m) {
  dd <- prim |> filter(!is.na(eeh_weekly_p), !is.na(.data[[m]]))
  concentration_curve(dd[[m]], dd$eeh_weekly_p, dd$emp, dd$unit) |> mutate(measure = m)
})

# Sensitivity table -------------------------------------------------------------------------
primary_profile <- deciles |> filter(scheme == "s1", sample == "all", ranking == "eeh") |> arrange(decile)
sens <- deciles |>
  group_by(scheme, sample, ranking) |>
  arrange(decile, .by_group = TRUE) |>
  summarise(
    usage_d1 = first(usage), usage_d10 = last(usage),
    top_minus_bottom_pp = 100 * (last(usage) - first(usage)),
    extensive_top_minus_bottom_pp = 100 * (last(extensive) - first(extensive)),
    holds = profile_holds(usage, primary_profile$usage)$holds,
    slope_same_sign = profile_holds(usage, primary_profile$usage)$same_sign,
    spearman_with_primary = profile_holds(usage, primary_profile$usage)$spearman,
    .groups = "drop"
  ) |>
  left_join(cis, by = c("scheme", "sample", "ranking"))

gap_quintiles <- gaps |>
  mutate(quintile = ceiling(decile / 2)) |>
  filter(quintile %in% c(1, 5)) |>
  group_by(scheme, sample, ranking, potential, quintile) |>
  summarise(gap_rank = mean(gap_rank), gap_z = mean(gap_z), .groups = "drop") |>
  pivot_wider(names_from = quintile, values_from = c(gap_rank, gap_z), names_prefix = "q")
gap_sign_check <- gap_quintiles |>
  group_by(sample, ranking, potential) |>
  summarise(bottom_sign_same_all_schemes = n_distinct(sign(gap_rank_q1)) == 1,
            top_sign_same_all_schemes = n_distinct(sign(gap_rank_q5)) == 1,
            holds = bottom_sign_same_all_schemes & top_sign_same_all_schemes, .groups = "drop")

# Unit-level correlations (employment-weighted ranks) between usage and potential measures.
correlations <- map_dfr(schemes, function(s) {
  d <- ut |> left_join(sv[[s]], by = "unit")
  map_dfr(c(potentials, "aioe"), function(p) {
    dd <- d |> filter(!is.na(usage), !is.na(.data[[p]]))
    tibble(scheme = s, potential = p, units = nrow(dd),
           spearman_weighted = weighted_spearman(dd$usage, dd[[p]], dd$emp),
           spearman_unweighted = cor(dd$usage, dd[[p]], method = "spearman"))
  })
})

# Largest rank disagreements against JSA automation, kept only where the sign holds in all schemes.
disagree <- map_dfr(schemes, function(s) {
  unit_gap(ut |> left_join(sv[[s]], by = "unit"), "usage", "jsa_automation") |> mutate(scheme = s)
}) |>
  select(unit, scheme, gap_rank) |>
  pivot_wider(names_from = scheme, values_from = gap_rank, names_prefix = "gap_") |>
  filter(if_all(starts_with("gap_"), ~ !is.na(.x))) |>
  rowwise() |> filter(n_distinct(sign(c_across(starts_with("gap_")))) == 1) |> ungroup() |>
  left_join(ut |> select(unit, title, emp, jsa_automation, grade), by = "unit") |>
  left_join(sv$s1 |> select(unit, usage), by = "unit") |>
  arrange(desc(abs(gap_s1))) |>
  slice_head(n = 15)

# D. Women and men -------------------------------------------------------------------------
dec_p <- fractional_deciles(ut, "eeh_weekly_p", "emp")
sex_overall <- prim |> filter(!is.na(usage)) |>
  summarise(women = sum(emp_female * usage) / sum(emp_female), men = sum(emp_male * usage) / sum(emp_male),
            women_jsa = sum((emp_female * jsa_automation)[!is.na(jsa_automation)]) / sum(emp_female[!is.na(jsa_automation)]),
            men_jsa = sum((emp_male * jsa_automation)[!is.na(jsa_automation)]) / sum(emp_male[!is.na(jsa_automation)]))
sex_deciles <- dec_p |>
  inner_join(prim |> select(unit, emp, emp_female, emp_male, usage, jsa_automation), by = "unit") |>
  filter(!is.na(usage)) |>
  mutate(f = frac_of_unit * emp_female, m = frac_of_unit * emp_male) |>
  group_by(decile) |>
  summarise(women = sum(f * usage) / sum(f), men = sum(m * usage) / sum(m),
            share_women = sum(f) / (sum(f) + sum(m)), .groups = "drop")

# D. WA against national ----------------------------------------------------------------------
wa_measures <- c("usage", "extensive", "jsa_automation", "beta_gpt4")
wa <- map_dfr(wa_measures, function(m) {
  d <- prim |> filter(!is.na(.data[[m]])) |>
    mutate(s_wa = emp_wa / sum(emp_wa), s_aus = emp / sum(emp), contrib = (s_wa - s_aus) * .data[[m]])
  tibble(measure = m, mean_wa = sum(d$s_wa * d[[m]]), mean_aus = sum(d$s_aus * d[[m]]), wa_gap = sum(d$contrib))
})
wa_decomp <- map_dfr(c(major = 1, submajor = 2), function(k) {
  map_dfr(wa_measures, function(m) {
    prim |> filter(!is.na(.data[[m]])) |>
      mutate(s_wa = emp_wa / sum(emp_wa), s_aus = emp / sum(emp), contrib = (s_wa - s_aus) * .data[[m]]) |>
      group_by(group = substr(unit, 1, k)) |>
      summarise(contribution = sum(contrib), wa_emp_000 = sum(emp_wa), share_wa = sum(s_wa), share_aus = sum(s_aus), .groups = "drop") |>
      mutate(measure = m, level = names(c(major = 1, submajor = 2))[k])
  })
}) |>
  mutate(small_cell = level == "submajor" & wa_emp_000 < 5)

# D. SOC major-group usage-to-employment index -------------------------------------------------
wlinks <- read_codes_csv(interim_path("links_scheme1_isco.csv")) |>
  inner_join(read_codes_csv(interim_path("soc_weights_oews.csv")) |> select(soc, w), by = "soc") |>
  group_by(unit) |> mutate(w = w / sum(w)) |> ungroup()
emp_soc_major <- wlinks |>
  inner_join(prim |> select(unit, emp, emp_wa), by = "unit") |>
  group_by(soc_major = substr(soc, 1, 2)) |>
  summarise(AUS = sum(w * emp), `AU-WA` = sum(w * emp_wa), .groups = "drop") |>
  mutate(across(c(AUS, `AU-WA`), ~ .x / sum(.x)))
oews_major <- read_codes_csv(interim_path("soc_weights_oews.csv")) |>
  group_by(soc_major = substr(soc, 1, 2)) |> summarise(GLOBAL = sum(w), .groups = "drop") |>
  mutate(GLOBAL = GLOBAL / sum(GLOBAL))

con <- dbConnect(duckdb(shared_home = FALSE))
dbExecute(con, sprintf("CREATE VIEW aei AS SELECT * FROM read_csv_auto(%s, header = true)",
                       dbQuoteString(con, raw_path("aei", "aei_claude_ai_2026-06-26.csv"))))
usage_major <- dbGetQuery(con, "
  SELECT geo_id, strftime(date_start, '%Y-%m') AS period, node_external_id AS soc_major, node_name, value AS pct
  FROM aei WHERE geo_id IN ('GLOBAL', 'AUS', 'AU-WA') AND category_name = 'soc_occupation'
    AND hierarchy_level = 1 AND metric_id = 'pct'")
dbDisconnect(con, shutdown = TRUE)

all_major <- usage_major |> filter(geo_id == "GLOBAL") |> distinct(soc_major, node_name)
suppressed <- expand_grid(geo_id = c("GLOBAL", "AUS", "AU-WA"), period = unique(usage_major$period), all_major) |>
  anti_join(usage_major, by = c("geo_id", "period", "soc_major"))
missing_mass <- usage_major |> group_by(geo_id, period) |>
  summarise(published_pct = sum(pct), missing_pct = 100 - sum(pct), groups_published = n(), .groups = "drop")

usage_index <- usage_major |>
  group_by(geo_id, soc_major, node_name) |>
  summarise(usage_share = mean(pct) / 100, months = n(), .groups = "drop") |>
  left_join(emp_soc_major |> pivot_longer(c(AUS, `AU-WA`), names_to = "geo_id", values_to = "emp_share") |>
              bind_rows(oews_major |> transmute(soc_major, geo_id = "GLOBAL", emp_share = GLOBAL)),
            by = c("geo_id", "soc_major")) |>
  mutate(usage_index = usage_share / emp_share,
         employment_basis = if_else(geo_id == "GLOBAL", "US OEWS May 2025 (no global employment by SOC exists)",
                                    "EQ08 allocated to SOC with scheme 1 weights"))

# Influence check (added after the first results; logged as N9): the top-minus-bottom gap with
# each of the five largest units in deciles 1 and 10 left out in turn, under every scheme.
influence <- map_dfr(schemes, function(s) {
  d <- ut |> left_join(sv[[s]], by = "unit")
  dec <- fractional_deciles(d, "eeh_weekly_p", "emp")
  big <- dec |> filter(decile %in% c(1, 10)) |> left_join(d |> select(unit, emp), by = "unit") |>
    group_by(decile) |> slice_max(emp * frac_of_unit, n = 5, with_ties = FALSE) |> ungroup() |> pull(unit)
  base <- decile_means(dec, d, "usage") |> arrange(decile)
  map_dfr(c("none", unique(big)), function(u) {
    dd <- if (u == "none") d else filter(d, unit != u)
    dm <- decile_means(fractional_deciles(dd, "eeh_weekly_p", "emp"), dd, "usage") |> arrange(decile)
    tibble(scheme = s, left_out = u, top_minus_bottom_pp = 100 * (last(dm$mean) - first(dm$mean)),
           d1 = first(dm$mean), d10 = last(dm$mean))
  })
}) |>
  left_join(ut |> select(left_out = unit, title, emp), by = "left_out")

# Write -----------------------------------------------------------------------------------
write_csv(influence, out("influence_largest_units.csv"))
write_csv(deciles, out("decile_profiles.csv"))
write_csv(gaps, out("gap_by_decile.csv"))
write_csv(sens, out("sensitivity_table.csv"))
write_csv(gap_quintiles, out("gap_quintiles.csv"))
write_csv(gap_sign_check, out("gap_sign_check.csv"))
write_csv(ci_potential, out("concentration_indices.csv"))
write_csv(curves, out("concentration_curves.csv"))
write_csv(correlations, out("correlations.csv"))
write_csv(disagree, out("largest_disagreements_jsa.csv"))
write_csv(sex_overall, out("sex_overall.csv"))
write_csv(sex_deciles, out("sex_deciles.csv"))
write_csv(wa, out("wa_vs_national.csv"))
write_csv(wa_decomp, out("wa_decomposition.csv"))
write_csv(usage_index, out("soc_major_usage_index.csv"))
write_csv(missing_mass, out("aei_major_group_missing_mass.csv"))
write_csv(suppressed, out("aei_major_group_suppressed_cells.csv"))
write_csv(decile_check, interim_path("decile_share_check.csv"))

message("Specifications run: ", nrow(grid))
