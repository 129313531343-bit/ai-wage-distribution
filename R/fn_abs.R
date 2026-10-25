# Readers for ABS classification, correspondence, Labour Force and EEH files.
# Each reader returns a tidy tibble with codes kept as character strings.

suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
  library(stringr)
  library(tidyr)
})

is_code <- function(x, digits = c(4, 6)) str_detect(x, paste0("^(", paste0("\\d{", digits, "}", collapse = "|"), ")$"))

# ABS correspondence tables have five columns: from code, from title, to code,
# partial-match flag ("p") and to title. The "from" columns are blank on
# continuation rows, so they are filled down before data rows are kept.
read_abs_corr <- function(path, sheet) {
  d <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text", .name_repair = "minimal")[, 1:5]
  names(d) <- c("from_code", "from_title", "to_code", "partial", "to_title")
  d |>
    mutate(across(everything(), str_squish)) |>
    mutate(from_title = if_else(is.na(from_code), NA_character_, from_title)) |>
    fill(from_code, from_title) |>
    filter(is_code(from_code), is_code(to_code)) |>
    mutate(partial = !is.na(partial) & partial == "p") |>
    distinct()
}

# Table 6 of an ANZSCO structure file: every valid 6-digit code, including nfd codes.
read_abs_codes6 <- function(path, sheet = "Table 6") {
  d <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text", .name_repair = "minimal")[, 1:2]
  names(d) <- c("code", "title")
  d |> mutate(across(everything(), str_squish)) |> filter(is_code(code, 6))
}

# Table 4 of an ANZSCO structure file: unit groups (4-digit) and their titles.
# The code sits in the fourth column and the title in the fifth.
read_abs_units <- function(path, sheet = "Table 4") {
  d <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text", .name_repair = "minimal")
  d <- d[, 1:5]
  names(d) <- c("major", "submajor", "minor", "unit", "title")
  d |>
    mutate(across(everything(), str_squish)) |>
    filter(is_code(unit, 4)) |>
    transmute(unit, title)
}

# Labour Force EQ08: employed persons ('000) by unit group, sex, state and mid-quarter month.
read_eq08 <- function(path) {
  d <- read_excel(path, sheet = "Data 1", skip = 3, col_types = "text", .name_repair = "minimal")[, 1:6]
  names(d) <- c("month", "sex", "state", "occ", "employed_000", "hours_000")
  d |>
    filter(!is.na(occ)) |>
    mutate(
      month = as.Date(as.numeric(month), origin = "1899-12-30"),
      code = str_sub(occ, 1, 4),
      title = str_squish(str_sub(occ, 6)),
      nfd = str_detect(title, "\\bnfd$"),
      employed_000 = as.numeric(employed_000),
      hours_000 = as.numeric(hours_000)
    ) |>
    select(month, sex, state, code, title, nfd, employed_000, hours_000)
}

# EEH cube tables with a code-and-title first column and one column per series.
# Suppressed cells (".", "np" or blank) become NA.
read_eeh_table <- function(path, sheet, col_names) {
  d <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text", .name_repair = "minimal")
  d <- d[, seq_len(length(col_names) + 1)]
  names(d) <- c("occ", col_names)
  d |>
    mutate(occ = str_squish(occ)) |>
    filter(str_detect(occ, "^\\d{1,4} ")) |>
    mutate(
      code = str_extract(occ, "^\\d{1,4}"),
      title = str_squish(str_remove(occ, "^\\d{1,4}")),
      across(all_of(col_names), ~ suppressWarnings(as.numeric(.x)))
    ) |>
    select(code, title, all_of(col_names))
}
