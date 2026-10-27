# v1.0 extension E3 (Luc's review of v0.9): uncertainty the point estimates leave out.
#   (a) Bounds for unscored links: the lower bound counts unscored US occupations as zero and the upper
#       bound as one, the highest possible score. A high imputation gives them the highest score in their
#       SOC minor group (major group if none is scored); it is not a bound, because for some units that
#       score is below the mean of their scored links.
#   (b) Crosswalk weights: each unit's scheme-1 weights over scored US occupations are redrawn from
#       Dirichlet(alpha * n * p), centred on the scheme-1 weights p with n links. alpha is calibrated
#       so that units' values vary across draws about as much as they vary across schemes 1 to 3; a
#       wider run uses alpha / 4.
#   (c) Earnings sampling error: EEH weekly earnings are redrawn from their published relative
#       standard errors (normal, independent across units); units without an RSE take the median.
#       Ranks and deciles are re-formed in every draw. EQ08 publishes no standard errors, so
#       employment is held fixed.
#   (d) A survival table: the share of draws in which each headline result holds.
# Added after the first results. Seeded, so reruns give identical output.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(purrr)
})
source("R/utils.R")
source("R/fn_exposure.R")
source("R/fn_analysis.R")
source("R/fn_owner_managers.R")
source("R/fn_units.R")

out <- function(f) out_path("m3", f)
B <- 500
set.seed(102)

soc_measures <- read_codes_csv(interim_path("soc_measures.csv"))
soc_w <- read_codes_csv(interim_path("soc_weights_oews.csv")) |> select(soc, w)
links1 <- read_codes_csv(interim_path("links_scheme1_isco.csv"))
long <- read_codes_csv(interim_path("unit_measures_long.csv"))
ut <- unit_table() |> left_join(scheme_values(long, "s1"), by = "unit")
sv13 <- map(c("s1", "s2", "s3"), \(s) scheme_values(long, s) |> select(unit, usage))

# Fast equivalents of weighted_rank() and fractional_deciles() for repeated draws (checked against
# them below). Ties share the mid-rank; deciles break earnings ties by unit code, as the pipeline does.
wrank <- function(x, w) {
  o <- order(x); xs <- x[o]
  g <- cumsum(c(TRUE, diff(xs) != 0))
  tot <- as.vector(rowsum(w[o], g))
  mid <- (cumsum(tot) - tot / 2) / sum(w)
  r <- numeric(length(x)); r[o] <- mid[g]; r
}
overlap <- function(earn, w, unit) {
  o <- order(earn, unit)
  share <- w[o] / sum(w); hi <- cumsum(share); lo <- hi - share
  b_lo <- (0:9) / 10; b_hi <- (1:10) / 10
  m <- pmax(0, outer(hi, b_hi, pmin) - outer(lo, b_lo, pmax))
  m[m < 1e-12] <- 0
  res <- matrix(0, length(earn), 10); res[o, ] <- m; res
}
dmean <- function(O, x) { ok <- !is.na(x); colSums(O[ok, , drop = FALSE] * x[ok]) / colSums(O[ok, , drop = FALSE]) }
cov_w <- function(a, b, w) { w <- w / sum(w); sum(w * (a - sum(w * a)) * (b - sum(w * b))) }

# Fixed inputs (all 358 units; earnings exist for every unit after imputation).
U <- ut |> arrange(unit)
emp <- U$emp
pots <- c("jsa_automation", "jsa_augmentation", "beta_gpt4", "aioe")
primary <- dmean(overlap(U$eeh_weekly_p, emp, U$unit), U$usage)

# All statistics for one draw of unit usage (e), extensive margin (m) and earnings (earn).
draw_stats <- function(e, m, earn) {
  O <- overlap(earn, emp, U$unit)
  du <- dmean(O, e); dm <- dmean(O, m)
  ok <- !is.na(e)
  r <- wrank(earn[ok], emp[ok])
  ci <- 2 * cov_w(e[ok], r, emp[ok]) / (sum(emp[ok] * e[ok]) / sum(emp[ok]))
  rci <- 4 * cov_w(wrank(e[ok], emp[ok]), r, emp[ok])
  pot_rci <- map_dbl(pots, function(p) {
    k <- !is.na(U[[p]]); rk <- wrank(earn[k], emp[k]); 4 * cov_w(wrank(U[[p]][k], emp[k]), rk, emp[k])
  }) |> set_names(pots)
  gq <- map(pots, function(p) {
    k <- ok & !is.na(U[[p]])
    gap <- rep(NA_real_, length(e))
    gap[k] <- 100 * (wrank(e[k], emp[k]) - wrank(U[[p]][k], emp[k]))
    gd <- dmean(O, gap)
    c(q1 = mean(gd[1:2]), q5 = mean(gd[9:10]))
  }) |> set_names(pots)
  # Women and men by decile: each unit's share of a decile, applied to each sex's employment.
  frac <- O / (emp / sum(emp))
  f <- frac * U$emp_female; mm <- frac * U$emp_male
  women <- colSums(f[ok, ] * e[ok]) / colSums(f[ok, ]); men <- colSums(mm[ok, ] * e[ok]) / colSums(mm[ok, ])
  wa_gap <- sum((U$emp_wa[ok] / sum(U$emp_wa[ok]) - emp[ok] / sum(emp[ok])) * e[ok])
  gap_j <- rep(NA_real_, length(e)); kj <- ok & !is.na(U$jsa_automation)
  gap_j[kj] <- 100 * (wrank(e[kj], emp[kj]) - wrank(U$jsa_automation[kj], emp[kj]))
  top15 <- U$unit[kj][order(-abs(gap_j[kj]))][1:15]
  list(
    stats = tibble(tmb = 100 * (du[10] - du[1]), ci = ci, rank_ci = rci, peak_decile = which.max(du),
                   holds = profile_holds(du, primary)$holds, ext_rises = dm[10] > dm[1],
                   intensity_lower_top = du[10] / dm[10] < du[1] / dm[1],
                   jsa_auto_top_pos = gq$jsa_automation[["q5"]] > 0, jsa_auto_bottom_neg = gq$jsa_automation[["q1"]] < 0,
                   capability_pattern = all(map_lgl(pots[-1], \(p) gq[[p]][["q1"]] > 0 && gq[[p]][["q5"]] < 0)),
                   between_families = rci > pot_rci[["jsa_automation"]] && rci < min(pot_rci[pots[-1]]),
                   women_higher_all = all(women > men),
                   women_higher_overall = sum(U$emp_female[ok] * e[ok]) / sum(U$emp_female[ok]) > sum(U$emp_male[ok] * e[ok]) / sum(U$emp_male[ok]),
                   wa_lower = wa_gap < 0),
    deciles = tibble(decile = 1:10, usage = du, extensive = dm),
    top15 = top15
  )
}

# Check the fast routines against the pipeline's own outputs for the main specification.
base <- draw_stats(U$usage, U$extensive, U$eeh_weekly_p)
m3_ci <- read_codes_csv(out_path("m3", "concentration_indices.csv"))
stopifnot(abs(base$stats$ci - m3_ci$ci[m3_ci$measure == "usage"]) < 1e-9,
          abs(base$stats$rank_ci - m3_ci$rank_ci[m3_ci$measure == "usage"]) < 1e-9,
          max(abs(base$deciles$usage - primary)) < 1e-12)

# (a) Bounds for unscored links ---------------------------------------------------------------
sm <- soc_measures |> select(soc, usage_exposure) |> filter(soc %in% unique(links1$soc)) |>
  mutate(minor = substr(soc, 1, 4), major = substr(soc, 1, 2))
hi_val <- sm |>
  group_by(minor) |> mutate(max_minor = suppressWarnings(max(usage_exposure, na.rm = TRUE))) |>
  group_by(major) |> mutate(max_major = suppressWarnings(max(usage_exposure, na.rm = TRUE))) |> ungroup() |>
  mutate(hi = coalesce(usage_exposure, if_else(is.finite(max_minor), max_minor, max_major)),
         ub = coalesce(usage_exposure, 1)) |> select(soc, hi, ub)
U <- U |>
  left_join(unit_scores(links1, hi_val, "hi", soc_w) |> select(unit, usage_hi = score), by = "unit") |>
  left_join(unit_scores(links1, hi_val, "ub", soc_w) |> select(unit, usage_ub = score), by = "unit")
stopifnot(all(U$usage_lb <= U$usage + 1e-12, na.rm = TRUE), all(U$usage_ub >= U$usage - 1e-12, na.rm = TRUE))
bound_runs <- list(lower = U$usage_lb, main = U$usage, high_imputation = U$usage_hi, upper = U$usage_ub)
bounds <- imap_dfr(bound_runs, function(e, k) {
  s <- draw_stats(e, U$extensive, U$eeh_weekly_p)
  s$deciles |> select(decile, usage) |> mutate(bound = k, tmb = s$stats$tmb, ci = s$stats$ci, rank_ci = s$stats$rank_ci,
                                               peak_decile = s$stats$peak_decile, holds = s$stats$holds)
})

# (b) Crosswalk draws ---------------------------------------------------------------------------
lw <- unit_weights(links1, soc_measures, "usage_exposure", soc_w) |>
  left_join(soc_measures |> select(soc, v = usage_exposure), by = "soc") |>
  filter(unit %in% U$unit) |> group_by(unit) |> mutate(n = n()) |> ungroup()
uix <- match(lw$unit, U$unit)
draw_units <- function(alpha) {
  g <- rgamma(nrow(lw), shape = alpha * lw$n * lw$w_norm)
  q <- g / as.vector(rowsum(g, uix))[match(uix, sort(unique(uix)))]
  e <- rep(NA_real_, nrow(U)); m <- rep(NA_real_, nrow(U))
  idx <- sort(unique(uix))
  e[idx] <- as.vector(rowsum(q * lw$v, uix)); m[idx] <- as.vector(rowsum(q * (lw$v > 0), uix))
  list(e = e, m = m)
}
# Calibrate alpha: employment-weighted mean across units of the spread of unit values.
target_sd <- reduce(sv13, left_join, by = "unit") |> rename(a = 2, b = 3, c = 4) |> filter(unit %in% U$unit) |>
  mutate(sd = apply(cbind(a, b, c), 1, sd, na.rm = TRUE)) |> left_join(U |> select(unit, emp), by = "unit") |>
  filter(!is.na(sd)) |> summarise(t = sum(emp * sd) / sum(emp)) |> pull(t)
alpha_grid <- c(0.25, 0.5, 1, 2, 4, 8, 16)
calib <- map_dfr(alpha_grid, function(a) {
  sims <- replicate(100, draw_units(a)$e)
  s <- apply(sims, 1, sd)
  k <- !is.na(s)
  tibble(alpha = a, mean_sd = sum(emp[k] * s[k]) / sum(emp[k]))
}) |> mutate(target_sd = target_sd)
alpha <- calib$alpha[which.min(abs(calib$mean_sd - target_sd))]

# (c) Earnings draws ------------------------------------------------------------------------------
rse <- coalesce(U$eeh_rse_max, median(U$eeh_rse_max, na.rm = TRUE))
draw_earn <- function() U$eeh_weekly_p * (1 + rse * rnorm(nrow(U)))

# (d) Run every draw type and summarise ------------------------------------------------------------
types <- list(
  crosswalk = function() { d <- draw_units(alpha); list(e = d$e, m = d$m, earn = U$eeh_weekly_p) },
  crosswalk_wide = function() { d <- draw_units(alpha / 4); list(e = d$e, m = d$m, earn = U$eeh_weekly_p) },
  earnings = function() list(e = U$usage, m = U$extensive, earn = draw_earn()),
  both = function() { d <- draw_units(alpha); list(e = d$e, m = d$m, earn = draw_earn()) }
)
runs <- imap(types, function(f, k) map(seq_len(B), function(i) { x <- f(); draw_stats(x$e, x$m, x$earn) }))
draws <- imap_dfr(runs, \(r, k) map_dfr(r, "stats") |> mutate(type = k, draw = row_number(), .before = 1))
survival <- draws |> group_by(type) |>
  summarise(draws = n(), ci_positive = mean(ci > 0), rank_ci_positive = mean(rank_ci > 0), tmb_positive = mean(tmb > 0),
            peak_at_decile_7 = mean(peak_decile == 7), profile_holds = mean(holds), extensive_rises = mean(ext_rises),
            intensity_lower_at_top = mean(intensity_lower_top), jsa_automation_top_positive = mean(jsa_auto_top_pos),
            jsa_automation_bottom_negative = mean(jsa_auto_bottom_neg), capability_pattern = mean(capability_pattern),
            between_families = mean(between_families), women_higher_every_decile = mean(women_higher_all), women_higher_overall = mean(women_higher_overall),
            wa_lower = mean(wa_lower), .groups = "drop")
ranges <- draws |> group_by(type) |>
  summarise(across(c(tmb, ci, rank_ci), list(p05 = \(x) quantile(x, 0.05), p50 = median, p95 = \(x) quantile(x, 0.95))), .groups = "drop")
bands <- imap_dfr(runs, function(r, k) {
  map_dfr(r, "deciles", .id = "draw") |> group_by(decile) |>
    summarise(usage_p05 = quantile(usage, 0.05), usage_p95 = quantile(usage, 0.95),
              extensive_p05 = quantile(extensive, 0.05), extensive_p95 = quantile(extensive, 0.95), .groups = "drop") |>
    mutate(type = k, .before = 1)
}) |> left_join(base$deciles |> rename(usage_main = usage, extensive_main = extensive), by = "decile")
dis15 <- read_codes_csv(out_path("m3", "largest_disagreements_jsa.csv"))$unit
top15_share <- imap_dfr(runs[c("crosswalk", "both")], function(r, k) {
  tibble(type = k, unit = dis15, share_in_top15 = map_dbl(dis15, \(u) mean(map_lgl(r, \(x) u %in% x$top15))))
})

write_csv(bounds, out("bounds_unscored.csv"))
write_csv(calib |> mutate(chosen = alpha == !!alpha), out("uncertainty_alpha_calibration.csv"))
write_csv(survival, out("uncertainty_survival.csv"))
write_csv(ranges, out("uncertainty_ranges.csv"))
write_csv(bands, out("uncertainty_bands.csv"))
write_csv(top15_share, out("uncertainty_top15.csv"))
message("Uncertainty draws: ", nrow(draws), "; alpha = ", alpha)
