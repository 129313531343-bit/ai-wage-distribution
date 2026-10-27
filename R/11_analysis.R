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
source("R/fn_units.R")

out <- function(f) out_path("m3", f)
dir.create(out_path("m3"), recursive = TRUE, showWarnings = FALSE)

long <- read_codes_csv(interim_path("unit_measures_long.csv"))

schemes <- c("s1", "s2", "s3", "s4")
scheme_labels <- long |> distinct(scheme, scheme_label)

# Unit table ------------------------------------------------------------------------
ut <- unit_table()
sv <- set_names(map(schemes, \(s) scheme_values(long, s)), schemes)

rankings <- spec_rankings
samples <- spec_samples
potentials <- c("jsa_automation", "jsa_augmentation", "beta_gpt4")

# One specification: scheme x sample x ranking ------------------------------------------
run_spec <- function(s, smp, rk) {
  d <- samples[[smp]](ut) |> left_join(sv[[s]], by = "unit")
  dec <- fractional_deciles(d, rankings[[rk]], "emp")
  dm <- decile_means(dec, d, c("usage", "extensive", "usage_lb", "beta_gpt4", "beta_ext", "jsa_automation",
                               "jsa_augmentation", "global_automation", "aioe")) |>
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
                ci_extensive = concentration_index(dd$extensive, r, dd$emp),
                rank_ci_usage = rank_concentration_index(dd$usage, r, dd$emp)),
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

# Concentration indices of every measure under the primary ranking. The level index (ci) depends
# on each measure's mean, so it does not compare measures; the rank index, the Erreygers index and
# the generalised index 2cov(e, r) were added after the first results (from the review) for that
# purpose. AIOE is a standardised score with negative values: its level and Erreygers indices are
# not defined, but its rank and generalised indices are (aggregate statistics only).
prim <- ut |> left_join(sv$s1, by = "unit")
bounded <- c("usage", "usage_lb", "extensive", "beta_ext", potentials)
ci_potential <- map_dfr(c("usage", "usage_lb", "extensive", "beta_ext", potentials, "aioe"), function(m) {
  dd <- prim |> filter(!is.na(eeh_weekly_p), !is.na(.data[[m]]))
  r <- weighted_rank(dd$eeh_weekly_p, dd$emp)
  w <- dd$emp / sum(dd$emp)
  tibble(measure = m,
         mean = sum(w * dd[[m]]),
         ci = if (m %in% bounded) concentration_index(dd[[m]], r, dd$emp) else NA_real_,
         rank_ci = rank_concentration_index(dd[[m]], r, dd$emp),
         erreygers = if (m %in% bounded) erreygers_index(dd[[m]], r, dd$emp) else NA_real_,
         generalised = 2 * sum(w * (dd[[m]] - sum(w * dd[[m]])) * (r - sum(w * r))),
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
    # OLS slope of the decile means, in exposure points (x100) per decile: the statistic C6 tests.
    slope_pp = 100 * profile_holds(usage, primary_profile$usage)$slope_variant,
    spearman_with_primary = profile_holds(usage, primary_profile$usage)$spearman,
    .groups = "drop"
  ) |>
  left_join(cis, by = c("scheme", "sample", "ranking"))

# Margin decomposition of each decile against decile 1, main specification, from unrounded means.
margins <- map_dfr(2:10, function(k) {
  margin_decomposition(primary_profile$usage[1], primary_profile$extensive[1],
                       primary_profile$usage[k], primary_profile$extensive[k]) |> mutate(decile = k, .before = 1)
})

gap_quintiles <- gaps |>
  mutate(quintile = ceiling(decile / 2)) |>
  filter(quintile %in% c(1, 5)) |>
  group_by(scheme, sample, ranking, potential, quintile) |>
  summarise(gap_rank = mean(gap_rank), gap_z = mean(gap_z), .groups = "drop") |>
  pivot_wider(names_from = quintile, values_from = c(gap_rank, gap_z), names_prefix = "q")
# Quintile gaps with zero-exposure units left out (added after the first results, from the review).
# All zero units share one tied rank, so a zero unit's gap is set by its potential rank alone.
# Deciles are those of the full sample; ranks are recomputed among units with positive exposure.
gap_quintiles_nonzero <- map_dfr(schemes, function(s) {
  d <- ut |> left_join(sv[[s]], by = "unit")
  dec <- fractional_deciles(d, "eeh_weekly_p", "emp")
  map_dfr(c(potentials, "aioe"), function(p) {
    g <- unit_gap(filter(d, usage > 0), "usage", p)
    dec |> inner_join(g, by = "unit") |>
      group_by(decile) |>
      summarise(gap_rank = sum(emp_share_in_decile * gap_rank) / sum(emp_share_in_decile), .groups = "drop") |>
      mutate(quintile = ceiling(decile / 2)) |>
      filter(quintile %in% c(1, 5)) |>
      group_by(quintile) |> summarise(gap_rank = mean(gap_rank), .groups = "drop") |>
      pivot_wider(names_from = quintile, values_from = gap_rank, names_prefix = "gap_rank_q") |>
      mutate(scheme = s, potential = p, .before = 1)
  })
})

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
disagree_all <- map_dfr(schemes, function(s) {
  unit_gap(ut |> left_join(sv[[s]], by = "unit"), "usage", "jsa_automation") |> mutate(scheme = s)
}) |>
  select(unit, scheme, gap_rank) |>
  pivot_wider(names_from = scheme, values_from = gap_rank, names_prefix = "gap_") |>
  filter(if_all(starts_with("gap_"), ~ !is.na(.x))) |>
  rowwise() |> filter(n_distinct(sign(c_across(starts_with("gap_")))) == 1) |> ungroup() |>
  left_join(ut |> select(unit, title, emp, jsa_automation, grade), by = "unit") |>
  left_join(sv$s1 |> select(unit, usage), by = "unit") |>
  # Employment-weighted contribution (gap x employment share), added after the first results:
  # the gap ranking alone puts small units first.
  mutate(contribution_s1 = gap_s1 * emp / sum(ut$emp))
disagree <- disagree_all |> arrange(desc(abs(gap_s1))) |> slice_head(n = 15)
disagree_weighted <- disagree_all |> arrange(desc(abs(contribution_s1))) |> slice_head(n = 15)

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
            share_women = sum(f) / (sum(f) + sum(m)), emp_women = sum(f), emp_men = sum(m), .groups = "drop")
# Split of the women-men gap into a within-decile part (different occupations in the same decile)
# and a between-decile part (different decile distributions), with average shares as weights so the
# two parts add to the total. Added after the first results, from the review.
sex_decomp <- sex_deciles |>
  mutate(fw = emp_women / sum(emp_women), fm = emp_men / sum(emp_men)) |>
  summarise(total = sum(fw * women) - sum(fm * men),
            within = sum((fw + fm) / 2 * (women - men)),
            between = sum((fw - fm) * (women + men) / 2)) |>
  mutate(within_share = within / total)

# D. WA against national ----------------------------------------------------------------------
wa_measures <- c("usage", "extensive", "jsa_automation", "beta_gpt4")
wa <- map_dfr(wa_measures, function(m) {
  d <- prim |> filter(!is.na(.data[[m]])) |>
    mutate(s_wa = emp_wa / sum(emp_wa), s_aus = emp / sum(emp), contrib = (s_wa - s_aus) * .data[[m]])
  tibble(measure = m, mean_wa = sum(d$s_wa * d[[m]]), mean_aus = sum(d$s_aus * d[[m]]), wa_gap = sum(d$contrib)) |>
    mutate(wa_gap_relative = wa_gap / mean_aus)
})
# Group contributions: raw (as first reported) and measured relative to the national mean
# (contribution_norm, added after the first results), which does not depend on the level of the measure.
wa_decomp <- map_dfr(c(major = 1, submajor = 2), function(k) {
  map_dfr(wa_measures, function(m) {
    d <- prim |> filter(!is.na(.data[[m]])) |>
      mutate(s_wa = emp_wa / sum(emp_wa), s_aus = emp / sum(emp), group = substr(unit, 1, k))
    normalised_contributions(d$s_wa, d$s_aus, d[[m]], d$group) |>
      rename(contribution = raw, contribution_norm = normalised) |>
      left_join(d |> group_by(group) |>
                  summarise(wa_emp_000 = sum(emp_wa), share_wa = sum(s_wa), share_aus = sum(s_aus), .groups = "drop"),
                by = "group") |>
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
# One thread, so sums are taken in the same order on every run (outputs are compared byte for byte).
invisible(dbExecute(con, "SET threads TO 1"))
dbExecute(con, sprintf("CREATE VIEW aei AS SELECT * FROM read_csv_auto(%s, header = true)",
                       dbQuoteString(con, raw_path("aei", "aei_claude_ai_2026-06-26.csv"))))
usage_major <- dbGetQuery(con, "
  SELECT geo_id, strftime(date_start, '%Y-%m') AS period, node_external_id AS soc_major, node_name, value AS pct
  FROM aei WHERE geo_id IN ('GLOBAL', 'AUS', 'AU-WA') AND category_name = 'soc_occupation'
    AND hierarchy_level = 1 AND metric_id = 'pct'
  ORDER BY geo_id, period, soc_major")
dbDisconnect(con, shutdown = TRUE)

all_major <- usage_major |> filter(geo_id == "GLOBAL") |> distinct(soc_major, node_name)
suppressed <- expand_grid(geo_id = c("GLOBAL", "AUS", "AU-WA"), period = unique(usage_major$period), all_major) |>
  anti_join(usage_major, by = c("geo_id", "period", "soc_major"))
missing_mass <- usage_major |> group_by(geo_id, period) |>
  summarise(published_pct = sum(pct), missing_pct = 100 - sum(pct), groups_published = n(), .groups = "drop")

# usage_index_rescaled divides by the published total in each geography and month instead of 100,
# because the published shares do not sum to 100 (N14); added after the first results.
usage_index <- usage_major |>
  group_by(geo_id, period) |> mutate(pct_rescaled = 100 * pct / sum(pct)) |> ungroup() |>
  group_by(geo_id, soc_major, node_name) |>
  summarise(usage_share = mean(pct) / 100, usage_share_rescaled = mean(pct_rescaled) / 100, months = n(), .groups = "drop") |>
  left_join(emp_soc_major |> pivot_longer(c(AUS, `AU-WA`), names_to = "geo_id", values_to = "emp_share") |>
              bind_rows(oews_major |> transmute(soc_major, geo_id = "GLOBAL", emp_share = GLOBAL)),
            by = c("geo_id", "soc_major")) |>
  mutate(usage_index = usage_share / emp_share, usage_index_rescaled = usage_share_rescaled / emp_share,
         employment_basis = if_else(geo_id == "GLOBAL", "US OEWS May 2025 (no global employment by SOC exists)",
                                    "EQ08 allocated to SOC with scheme 1 weights"))

# Influence check (added after the first results; logged as N9): the top-minus-bottom gap with
# each of the five largest units in deciles 1 and 10 left out in turn, under every scheme. Deciles
# are re-formed after each unit is left out. Extended after the review to the five largest units
# in decile 7 (the peak), with the concentration indices and the C6 rule for each run.
influence <- map_dfr(schemes, function(s) {
  d <- ut |> left_join(sv[[s]], by = "unit")
  dec <- fractional_deciles(d, "eeh_weekly_p", "emp")
  big <- dec |> filter(decile %in% c(1, 7, 10)) |> left_join(d |> select(unit, emp), by = "unit") |>
    group_by(decile) |> slice_max(emp * frac_of_unit, n = 5, with_ties = FALSE) |> ungroup()
  map_dfr(c("none", unique(big$unit)), function(u) {
    dd <- if (u == "none") d else filter(d, unit != u)
    dm <- decile_means(fractional_deciles(dd, "eeh_weekly_p", "emp"), dd, "usage") |> arrange(decile)
    du <- dd |> filter(!is.na(eeh_weekly_p), !is.na(usage))
    r <- weighted_rank(du$eeh_weekly_p, du$emp)
    tibble(scheme = s, left_out = u, from_decile = if (u == "none") NA_integer_ else min(big$decile[big$unit == u]),
           top_minus_bottom_pp = 100 * (last(dm$mean) - first(dm$mean)),
           d1 = first(dm$mean), d7 = dm$mean[7], d10 = last(dm$mean),
           ci_usage = concentration_index(du$usage, r, du$emp),
           rank_ci_usage = rank_concentration_index(du$usage, r, du$emp),
           holds = profile_holds(dm$mean, primary_profile$usage)$holds)
  })
}) |>
  left_join(ut |> select(left_out = unit, title, emp), by = "left_out")

# Smoothed profile over earnings percentiles (added after the first results, from the review): a
# local-linear fit of unit exposure on the unit's employment-weighted earnings rank, with
# employment weights. The band is the 5th to 95th percentile over 200 resamples of units; it shows
# how much the curve depends on which units are present, not sampling error.
smooth_fit <- function(d, y, grid) {
  fit <- loess(as.formula(paste(y, "~ r")), data = d, weights = emp, span = 0.4, degree = 1)
  predict(fit, newdata = data.frame(r = grid))
}
sp <- prim |> filter(!is.na(usage), !is.na(eeh_weekly_p)) |> mutate(r = weighted_rank(eeh_weekly_p, emp))
grid_r <- seq(0.02, 0.98, by = 0.01)
set.seed(101)
smoothed <- map_dfr(c("usage", "extensive"), function(y) {
  boot <- replicate(200, smooth_fit(sp[sample(nrow(sp), replace = TRUE), ], y, grid_r))
  tibble(measure = y, percentile = 100 * grid_r, fit = smooth_fit(sp, y, grid_r),
         lo = apply(boot, 1, quantile, 0.05, na.rm = TRUE), hi = apply(boot, 1, quantile, 0.95, na.rm = TRUE))
})

# Write -----------------------------------------------------------------------------------
write_csv(influence, out("influence_largest_units.csv"))
write_csv(margins, out("margin_decomposition.csv"))
write_csv(gap_quintiles_nonzero, out("gap_quintiles_nonzero.csv"))
write_csv(disagree_weighted, out("largest_disagreements_jsa_weighted.csv"))
write_csv(sex_decomp, out("sex_decomposition.csv"))
write_csv(smoothed, out("smoothed_profile.csv"))
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
