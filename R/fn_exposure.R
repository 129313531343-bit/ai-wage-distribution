# Unit-level scores from SOC-level values through a set of unit-SOC links.
# Score of unit a = sum_s w_as v_s over linked SOCs with non-missing v_s, with the
# weights renormalised to sum to one over those SOCs (method A in the brief).

suppressPackageStartupMessages({
  library(dplyr)
})

grade_from_n <- function(n) {
  case_when(n == 0 ~ "unmatched", n == 1 ~ "one-to-one", n <= 4 ~ "few-to-one", TRUE ~ "diffuse")
}

# links: unit, soc; values: soc plus the value column; weights: soc, w (NULL = equal weights).
# Returns one row per unit with the score, the extensive margin (the same weights applied
# to 1[v > 0]), intensity (score / extensive margin), counts and the crosswalk grade.
# score_lb is a lower bound for non-negative measures: linked SOCs without a value count as zero
# instead of being renormalised away (added after the first results, from the review).
unit_scores <- function(links, values, value_col, weights = NULL) {
  d <- links |>
    distinct(unit, soc) |>
    left_join(values |> select(soc, v = all_of(value_col)), by = "soc")
  d <- if (is.null(weights)) mutate(d, w = 1) else left_join(d, weights, by = "soc")
  d |>
    group_by(unit) |>
    summarise(
      n_linked = n(),
      n_valid = sum(!is.na(v) & !is.na(w) & w > 0),
      w_total = sum(w[!is.na(v) & !is.na(w)]),
      score = if (n_valid > 0) sum((w * v)[!is.na(v) & !is.na(w)]) / w_total else NA_real_,
      extensive = if (n_valid > 0) sum((w * (v > 0))[!is.na(v) & !is.na(w)]) / w_total else NA_real_,
      score_lb = if (n_valid > 0) sum((w * v)[!is.na(v) & !is.na(w)]) / sum(w[!is.na(w)]) else NA_real_,
      linked_socs = paste(sort(soc[!is.na(v) & !is.na(w)]), collapse = ";"),
      .groups = "drop"
    ) |>
    mutate(
      intensity = if_else(extensive > 0, score / extensive, NA_real_),
      grade = grade_from_n(n_valid)
    ) |>
    select(-w_total)
}

# Weights within each unit, after renormalisation, for the weights-sum-to-one test.
unit_weights <- function(links, values, value_col, weights = NULL) {
  d <- links |>
    distinct(unit, soc) |>
    left_join(values |> select(soc, v = all_of(value_col)), by = "soc")
  d <- if (is.null(weights)) mutate(d, w = 1) else left_join(d, weights, by = "soc")
  d |>
    filter(!is.na(v), !is.na(w), w > 0) |>
    group_by(unit) |>
    mutate(w_norm = w / sum(w)) |>
    ungroup() |>
    select(unit, soc, w_norm)
}
