# Move unit-level values from ANZSCO 2021/2022 unit groups to v1.2 unit groups.
# Rule (from the brief): a v1.2 unit fed by several source units takes their weighted
# mean (weights = source employee counts); a source unit split across several v1.2
# units passes its value to each of them. One weighted mean over linked sources does both.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

bridge_to_v12 <- function(values, value_cols, bridge, weights, rse_col = NULL) {
  # values: tibble with unit2022 and value_cols (NA = suppressed)
  # bridge: unit2022, unit_v12, type
  # weights: unit2022, w (source employee counts; missing weights count as 1)
  long <- bridge |>
    select(unit2022, unit_v12, type) |>
    left_join(values, by = "unit2022") |>
    left_join(weights, by = "unit2022") |>
    mutate(w = coalesce(w, 1))

  out <- long |>
    pivot_longer(all_of(value_cols), names_to = "series", values_to = "value") |>
    filter(!is.na(value)) |>
    group_by(unit_v12, series) |>
    summarise(value = sum(w * value) / sum(w), .groups = "drop") |>
    pivot_wider(names_from = series, values_from = value)

  info <- long |>
    group_by(unit_v12) |>
    summarise(
      sources = paste(sort(unique(unit2022)), collapse = ";"),
      bridge_type = paste(sort(unique(type)), collapse = ";"),
      .groups = "drop"
    )
  if (!is.null(rse_col)) {
    rse <- long |>
      filter(!is.na(.data[[rse_col]])) |>
      group_by(unit_v12) |>
      summarise(rse_max = max(.data[[rse_col]]), .groups = "drop")
    info <- left_join(info, rse, by = "unit_v12")
  }
  info |> left_join(out, by = "unit_v12")
}

# Fill missing values from the employment-weighted mean of siblings in the same
# minor group (3-digit), then the same sub-major group (2-digit). Returns the
# filled column and the level used, so every imputation is logged.
impute_from_parent <- function(df, col, emp) {
  df <- df |> left_join(emp, by = "unit")
  parent_mean <- function(d, digits) {
    d |>
      filter(!is.na(.data[[col]])) |>
      group_by(parent = substr(unit, 1, digits)) |>
      summarise(fill = sum(emp * .data[[col]]) / sum(emp), .groups = "drop")
  }
  m3 <- parent_mean(df, 3)
  m2 <- parent_mean(df, 2)
  df |>
    mutate(p3 = substr(unit, 1, 3), p2 = substr(unit, 1, 2)) |>
    left_join(m3 |> rename(fill3 = fill), by = c("p3" = "parent")) |>
    left_join(m2 |> rename(fill2 = fill), by = c("p2" = "parent")) |>
    mutate(
      imputed = case_when(!is.na(.data[[col]]) ~ "none",
                          !is.na(fill3) ~ "minor group (3-digit) mean",
                          !is.na(fill2) ~ "sub-major group (2-digit) mean",
                          TRUE ~ "not imputed"),
      "{col}" := coalesce(.data[[col]], fill3, fill2)
    ) |>
    select(-p3, -p2, -fill3, -fill2, -emp)
}
