# Analysis helpers for methods B and C: employment-weighted fractional deciles,
# weighted ranks, the concentration index and curve, and the usage-potential gap.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

# Employment-weighted fractional rank in (0, 1): the share of employment below a unit
# plus half its own weight. Tied values share the mid-rank of their tied block.
weighted_rank <- function(x, w) {
  stopifnot(length(x) == length(w), all(w >= 0), !anyNA(x))
  W <- sum(w)
  blocks <- tibble(x = x, w = w) |>
    group_by(x) |>
    summarise(wb = sum(w), .groups = "drop") |>
    arrange(x) |>
    mutate(r = (cumsum(wb) - wb / 2) / W)
  blocks$r[match(x, blocks$x)]
}

# Split units into employment-weighted deciles by `rank_col`. A unit whose employment
# straddles a boundary is split fractionally, so each decile holds exactly 1/n of employment.
# Ties in the ranking variable are broken by unit code so the result is reproducible.
fractional_deciles <- function(df, rank_col, weight_col = "emp", n = 10) {
  d <- df |>
    filter(!is.na(.data[[rank_col]]), .data[[weight_col]] > 0) |>
    arrange(.data[[rank_col]], unit) |>
    mutate(share = .data[[weight_col]] / sum(.data[[weight_col]]),
           hi = cumsum(share), lo = hi - share)
  bounds <- tibble(decile = seq_len(n), d_lo = (decile - 1) / n, d_hi = decile / n)
  d |>
    cross_join(bounds) |>
    mutate(overlap = pmax(0, pmin(hi, d_hi) - pmax(lo, d_lo))) |>
    filter(overlap > 1e-12) |>
    mutate(frac_of_unit = overlap / share) |>
    select(unit, decile, frac_of_unit, emp_share_in_decile = overlap)
}

# Employment-weighted decile means of the given columns. Intensity at decile level is the
# ratio of mean exposure to mean extensive margin, so exposure = extensive x intensity holds.
decile_means <- function(deciles, unit_values, cols) {
  deciles |>
    inner_join(unit_values, by = "unit") |>
    pivot_longer(all_of(cols), names_to = "measure", values_to = "value") |>
    filter(!is.na(value)) |>
    group_by(decile, measure) |>
    summarise(mean = sum(emp_share_in_decile * value) / sum(emp_share_in_decile),
              emp_covered = sum(emp_share_in_decile), .groups = "drop")
}

# Concentration index CI = 2 cov_w(e, r) / mean_w(e), with r the employment-weighted
# fractional earnings rank. Positive values mean exposure is concentrated among higher earners.
concentration_index <- function(e, r, w) {
  ok <- !is.na(e) & !is.na(r) & !is.na(w)
  e <- e[ok]; r <- r[ok]; w <- w[ok] / sum(w[ok])
  me <- sum(w * e); mr <- sum(w * r)
  2 * sum(w * (e - me) * (r - mr)) / me
}

# Concentration curve: cumulative employment share (x) against cumulative exposure share (y),
# with units ordered by earnings.
concentration_curve <- function(e, earnings, w, unit) {
  tibble(unit, e, earnings, w) |>
    filter(!is.na(e), !is.na(earnings)) |>
    arrange(earnings, unit) |>
    mutate(cum_emp = cumsum(w) / sum(w), cum_exposure = cumsum(w * e) / sum(w * e)) |>
    select(unit, cum_emp, cum_exposure)
}

# Unit-level usage-potential gap: employment-weighted percentile rank of usage-based exposure
# minus that of a potential measure (0-100 scale, mid-rank ties), plus a weighted z-score version.
# Ranks are computed over the units that have both measures.
unit_gap <- function(df, usage_col, potential_col, weight_col = "emp") {
  d <- df |> filter(!is.na(.data[[usage_col]]), !is.na(.data[[potential_col]]), .data[[weight_col]] > 0)
  w <- d[[weight_col]]
  wz <- function(x) (x - sum(w * x) / sum(w)) / sqrt(sum(w * (x - sum(w * x) / sum(w))^2) / sum(w))
  d |>
    mutate(
      pr_usage = 100 * weighted_rank(.data[[usage_col]], w),
      pr_potential = 100 * weighted_rank(.data[[potential_col]], w),
      gap_rank = pr_usage - pr_potential,
      gap_z = wz(.data[[usage_col]]) - wz(.data[[potential_col]])
    ) |>
    select(unit, pr_usage, pr_potential, gap_rank, gap_z)
}

# Weighted Spearman-style rank correlation (Pearson on employment-weighted ranks).
weighted_spearman <- function(x, y, w) {
  ok <- !is.na(x) & !is.na(y) & !is.na(w)
  x <- x[ok]; y <- y[ok]; w <- w[ok]
  rx <- weighted_rank(x, w); ry <- weighted_rank(y, w)
  cov.wt(cbind(rx, ry), wt = w / sum(w), cor = TRUE)$cor[1, 2]
}

# Choice C6: a decile profile "holds" against the primary if the OLS slope of the decile means
# has the same sign and the Spearman correlation of the decile means is at least 0.7.
profile_holds <- function(variant, primary) {
  stopifnot(length(variant) == length(primary))
  deciles <- seq_along(primary)
  slope <- function(y) unname(coef(lm(y ~ deciles))[2])
  rho <- suppressWarnings(cor(variant, primary, method = "spearman"))
  list(slope_variant = slope(variant), slope_primary = slope(primary),
       same_sign = sign(slope(variant)) == sign(slope(primary)),
       spearman = rho, holds = sign(slope(variant)) == sign(slope(primary)) && !is.na(rho) && rho >= 0.7)
}
