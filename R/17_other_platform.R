# v1.0 extension E1 (Luc's review of v0.9): is the earnings gradient specific to Claude?
# Microsoft's AI applicability score [Tomlinson et al. 2025, CC BY 4.0], built from Copilot
# conversations, goes through the same crosswalk, weighting schemes, rankings and samples as the
# usage-based score. Measures on different scales are compared on employment-weighted ranks.
# A two-platform composite averages each unit's percentile ranks on the two measures; with two
# sources the median is the mean. Added after the first results.

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

copilot <- read_csv(raw_path("wwai", "ai_applicability_scores.csv"), col_types = cols(`SOC Code` = "c"), show_col_types = FALSE) |>
  transmute(soc = `SOC Code`, copilot = ai_applicability_score)
soc_w <- read_codes_csv(interim_path("soc_weights_oews.csv")) |> select(soc, w)
scheme_links <- list(
  s1 = list(links = read_codes_csv(interim_path("links_scheme1_isco.csv")), weights = soc_w),
  s2 = list(links = read_codes_csv(interim_path("links_scheme1_isco.csv")), weights = NULL),
  s3 = list(links = read_codes_csv(interim_path("links_scheme3_title.csv")), weights = soc_w),
  s4 = list(links = read_codes_csv(interim_path("links_scheme4_lmi.csv")), weights = soc_w)
)
cop_units <- imap(scheme_links, \(s, key) unit_scores(s$links, copilot, "copilot", s$weights) |> select(unit, copilot = score))

long <- read_codes_csv(interim_path("unit_measures_long.csv"))
ut <- unit_table()
schemes <- names(scheme_links)
sv <- set_names(map(schemes, \(s) scheme_values(long, s) |> left_join(cop_units[[s]], by = "unit")), schemes)

# Every specification: rank indices of Claude usage, Copilot applicability and the composite, on the
# units that have both measures, and the rank correlation between the two.
spec <- function(s, smp, rk) {
  d <- spec_samples[[smp]](ut) |> left_join(sv[[s]], by = "unit") |>
    filter(!is.na(usage), !is.na(copilot), !is.na(.data[[spec_rankings[[rk]]]]))
  r <- weighted_rank(d[[spec_rankings[[rk]]]], d$emp)
  comp <- (weighted_rank(d$usage, d$emp) + weighted_rank(d$copilot, d$emp)) / 2
  dec <- fractional_deciles(d, spec_rankings[[rk]], "emp")
  dm <- decile_means(dec, d, c("usage", "copilot")) |> select(decile, measure, mean) |> pivot_wider(names_from = measure, values_from = mean) |> arrange(decile)
  tibble(scheme = s, sample = smp, ranking = rk, units = nrow(d),
         rank_ci_usage = rank_concentration_index(d$usage, r, d$emp),
         rank_ci_copilot = rank_concentration_index(d$copilot, r, d$emp),
         rank_ci_composite = rank_concentration_index(comp, r, d$emp),
         ci_copilot = concentration_index(d$copilot, r, d$emp),
         copilot_top_minus_bottom = 100 * (last(dm$copilot) - first(dm$copilot)),
         spearman_usage_copilot = weighted_spearman(d$usage, d$copilot, d$emp))
}
grid <- expand_grid(s = schemes, smp = names(spec_samples), rk = names(spec_rankings))
sens <- pmap_dfr(grid, spec)

# Main specification: every measure on one rank scale. Mean employment-weighted percentile rank by
# earnings decile, the rank index, and the rank correlation with Claude usage. AIOE is aggregate only.
prim <- ut |> left_join(sv$s1, by = "unit")
measures <- c(usage = "usage", copilot = "copilot", jsa_automation = "jsa_automation", jsa_augmentation = "jsa_augmentation",
              beta_gpt4 = "beta_gpt4", aioe = "aioe")
main <- map_dfr(measures, function(m) {
  d <- prim |> filter(!is.na(.data[[m]]), !is.na(eeh_weekly_p))
  r <- weighted_rank(d$eeh_weekly_p, d$emp)
  du <- d |> filter(!is.na(usage))
  tibble(measure = m, units = nrow(d), rank_ci = rank_concentration_index(d[[m]], r, d$emp),
         spearman_with_usage = if (m == "usage") 1 else weighted_spearman(du$usage, du[[m]], du$emp),
         spearman_with_earnings = weighted_spearman(d[[m]], d$eeh_weekly_p, d$emp))
})
dec_p <- fractional_deciles(prim |> filter(!is.na(eeh_weekly_p)), "eeh_weekly_p", "emp")
rank_deciles <- map_dfr(measures, function(m) {
  d <- prim |> filter(!is.na(.data[[m]]), !is.na(eeh_weekly_p)) |> mutate(pr = 100 * weighted_rank(.data[[m]], emp))
  decile_means(dec_p, d, "pr") |> transmute(measure = m, decile, mean_rank = mean)
})
copilot_levels <- decile_means(dec_p, prim, "copilot") |> transmute(decile, copilot = mean)

write_csv(sens, out("other_platform_sensitivity.csv"))
write_csv(main, out("other_platform_main.csv"))
write_csv(rank_deciles, out("other_platform_rank_deciles.csv"))
write_csv(copilot_levels, out("other_platform_copilot_deciles.csv"))
message("Other-platform specifications: ", nrow(sens))
