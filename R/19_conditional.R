# v1.0 extension E4 (Luc's review of v0.9): does measured use rise with earnings once what AI can do
# and whether the work already runs through a computer are held fixed?
# Employment-weighted OLS across unit groups on employment-weighted percentile ranks:
#   R(usage) = a + b R(earnings) + g R(potential) + d R(teleworkable) + e,
# with each potential measure in turn, HC1 standard errors, a Gelbach (2016) decomposition of how much
# of the unconditional slope each control accounts for, and an ORIV estimate [Gillen, Snowberg and
# Yariv 2019] that uses JSA augmentation and AIOE as two error-prone measures of capability.
# Teleworkability is Dingel and Neiman's (2020) classification of O*NET occupations (GPL-3.0): unit-level
# values stay in a NOT_FOR_PUBLICATION file and only aggregate statistics are written to data/out.
# Descriptive partial associations across occupations, not causal effects. Added after the first results.

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

# Teleworkability by SOC 2010 (mean over O*NET-SOC detail), then to units through the SOC 2010 links
# and OEWS weights used for AIOE.
dn <- read_csv(raw_path("dingelneiman", "occupations_workathome.csv"), show_col_types = FALSE) |>
  transmute(soc = substr(onetsoccode, 1, 7), teleworkable) |>
  group_by(soc) |> summarise(tw = mean(teleworkable), .groups = "drop")
links2010 <- read_codes_csv(interim_path("links_aioe_soc2010_NOT_FOR_PUBLICATION.csv")) |> rename(soc = soc2010)
w2010 <- read_codes_csv(interim_path("soc2010_weights_oews.csv")) |> rename(soc = soc2010)
tw_units <- unit_scores(links2010, dn, "tw", w2010) |> select(unit, teleworkable = score)
write_csv(tw_units, interim_path("telework_units_NOT_FOR_PUBLICATION.csv"))

long <- read_codes_csv(interim_path("unit_measures_long.csv"))
d <- unit_table() |> left_join(scheme_values(long, "s1"), by = "unit") |> left_join(tw_units, by = "unit") |>
  filter(!is.na(usage), !is.na(eeh_weekly_p), !is.na(teleworkable), !is.na(jsa_automation), !is.na(aioe))
w <- d$emp
R <- function(x) 100 * weighted_rank(x, w)
X <- tibble(u = R(d$usage), m = R(d$extensive), y = R(d$eeh_weekly_p), tw = R(d$teleworkable),
            jsa_automation = R(d$jsa_automation), jsa_augmentation = R(d$jsa_augmentation),
            beta_gpt4 = R(d$beta_gpt4), aioe = R(d$aioe))

# Weighted least squares with HC1 standard errors.
wls <- function(yv, xs) {
  Z <- cbind(1, as.matrix(xs)); W <- w / sum(w) * length(w)
  A <- solve(t(Z) %*% (Z * W)); b <- A %*% t(Z) %*% (W * yv)
  e <- as.vector(yv - Z %*% b)
  V <- A %*% t(Z * (W * e)^2) %*% Z %*% A * length(yv) / (length(yv) - ncol(Z))
  tibble(term = c("(intercept)", colnames(xs)), estimate = as.vector(b), se = sqrt(diag(V)))
}
pots <- c("jsa_automation", "jsa_augmentation", "beta_gpt4", "aioe")
models <- list(earnings = c("y"), with_telework = c("y", "tw"))
for (p in pots) { models[[paste0("with_", p)]] <- c("y", p); models[[paste0("with_", p, "_telework")]] <- c("y", p, "tw") }
coefs <- map_dfr(c(usage = "u", extensive = "m"), function(o) {
  imap_dfr(models, \(v, k) wls(X[[o]], X[v]) |> mutate(model = k, .before = 1))
}, .id = "outcome") |> mutate(units = nrow(d))

# Gelbach decomposition of the earnings slope: base minus full = sum over controls of
# (control's coefficient in the full model) x (slope of the control on earnings rank).
gelbach_split <- function(o, p) {
  base <- wls(X[[o]], X["y"])$estimate[2]
  full <- wls(X[[o]], X[c("y", p, "tw")])
  contrib <- map_dbl(c(p, "tw"), \(k) full$estimate[full$term == k] * wls(X[[k]], X["y"])$estimate[2])
  tibble(outcome = o, potential = p, base = base, full = full$estimate[full$term == "y"],
         via_potential = contrib[1], via_telework = contrib[2])
}
gelbach <- map_dfr(c(usage = "u", extensive = "m"), \(o) map_dfr(pots, \(p) gelbach_split(o, p)))

# ORIV: capability measured twice (JSA augmentation, AIOE). Stack the two regressions, instrument each
# measure with the other, and estimate a common earnings coefficient.
oriv <- function(o) {
  n <- nrow(X); W <- rep(w / sum(w) * n, 2)
  Y <- c(X[[o]], X[[o]]); P <- c(X$jsa_augmentation, X$aioe); Iv <- c(X$aioe, X$jsa_augmentation); D <- rep(0:1, each = n)
  Xm <- cbind(P, y = rep(X$y, 2), tw = rep(X$tw, 2), 1, D, D * rep(X$y, 2), D * rep(X$tw, 2))
  Zm <- cbind(Iv, Xm[, -1])
  b <- solve(t(Zm) %*% (Xm * W), t(Zm) %*% (W * Y))
  tibble(outcome = o, earnings = b[2], capability = b[1], telework = b[3])
}
oriv_res <- map_dfr(c(usage = "u", extensive = "m"), oriv)

# Descriptive correlations (employment-weighted ranks).
assoc <- tibble(
  pair = c("telework_earnings", "telework_usage", "telework_extensive", "earnings_usage"),
  spearman = c(weighted_spearman(d$teleworkable, d$eeh_weekly_p, w), weighted_spearman(d$teleworkable, d$usage, w),
               weighted_spearman(d$teleworkable, d$extensive, w), weighted_spearman(d$eeh_weekly_p, d$usage, w)),
  units = nrow(d))

write_csv(coefs, out("conditional_gradient.csv"))
write_csv(gelbach, out("conditional_gelbach.csv"))
write_csv(oriv_res, out("conditional_oriv.csv"))
write_csv(assoc, out("conditional_associations.csv"))
message("Conditional gradient: ", nrow(d), " units")
