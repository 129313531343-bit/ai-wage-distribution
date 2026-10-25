# Employment weights from Labour Force EQ08 (ANZSCO 2013 v1.2 unit groups).
#   1. Allocate each nfd code's employment to the unit groups under it, pro rata to
#      their employment in the same quarter x sex x state cell.
#   2. Average the four quarters May 2025, Aug 2025, Nov 2025 and Feb 2026 (choice C3).
# Outputs: data/interim/emp_cells.csv (unit x sex x state, pooled), emp_units.csv,
# and data/out/m1/eq08_nfd_allocation_log.csv.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
})
source("R/utils.R")
source("R/fn_abs.R")

pool_months <- as.Date(c("2025-05-01", "2025-08-01", "2025-11-01", "2026-02-01"))

eq08 <- read_eq08(raw_path("abs", "EQ08_mar2026.xlsx")) |> filter(month %in% pool_months)
v12_units <- read_codes_csv(interim_path("v12_units.csv"))

units <- eq08 |> filter(!nfd)
nfds <- eq08 |> filter(nfd) |> mutate(prefix = sub("0+$", "", code))
stopifnot(setequal(unique(units$code), v12_units$unit))

# Children of each nfd code: the unit groups whose code starts with its prefix.
children <- nfds |>
  distinct(code, prefix) |>
  cross_join(v12_units |> select(unit)) |>
  filter(startsWith(unit, prefix)) |>
  select(nfd_code = code, unit)

cell_keys <- c("month", "sex", "state")

shares_from <- function(base, keys) {
  children |>
    inner_join(base, by = "unit", relationship = "many-to-many") |>
    group_by(across(all_of(c("nfd_code", keys)))) |>
    mutate(total = sum(employed_000)) |>
    ungroup() |>
    filter(total > 0) |>
    mutate(share = employed_000 / total) |>
    select(all_of(c("nfd_code", keys, "unit", "share")))
}

# Shares within the cell; fall back to month x sex nationally if every child is zero in the cell.
cell_base <- units |> select(all_of(cell_keys), unit = code, employed_000)
national_base <- units |> group_by(month, sex, unit = code) |> summarise(employed_000 = sum(employed_000), .groups = "drop")
shares_cell <- shares_from(cell_base, cell_keys)
shares_nat <- shares_from(national_base, c("month", "sex"))

nfd_cells <- nfds |> filter(employed_000 > 0) |> select(all_of(cell_keys), nfd_code = code, nfd_emp = employed_000)
has_cell_share <- nfd_cells |> semi_join(shares_cell, by = c("nfd_code", cell_keys))
needs_fallback <- nfd_cells |> anti_join(shares_cell, by = c("nfd_code", cell_keys))

alloc <- bind_rows(
  has_cell_share |> inner_join(shares_cell, by = c("nfd_code", cell_keys)) |> mutate(rule = "cell"),
  needs_fallback |> inner_join(shares_nat, by = c("nfd_code", "month", "sex"), relationship = "many-to-many") |>
    mutate(rule = "national fallback")
) |>
  mutate(allocated_000 = nfd_emp * share)

stopifnot(abs(sum(alloc$allocated_000) - sum(nfd_cells$nfd_emp)) < 1e-6)

# full_join: a national-fallback share can land on a unit with no row in that cell.
emp_cells_q <- cell_base |>
  full_join(alloc |> group_by(across(all_of(cell_keys)), unit) |> summarise(allocated_000 = sum(allocated_000), .groups = "drop"),
            by = c(cell_keys, "unit")) |>
  mutate(allocated_000 = coalesce(allocated_000, 0), employed_000 = coalesce(employed_000, 0) + allocated_000)
stopifnot(abs(sum(emp_cells_q$employed_000) - sum(eq08$employed_000)) < 1e-6)

emp_cells <- emp_cells_q |>
  group_by(unit, sex, state) |>
  summarise(employed_000 = sum(employed_000) / length(pool_months), .groups = "drop")

emp_units <- emp_cells |>
  group_by(unit) |>
  summarise(
    emp = sum(employed_000),
    emp_male = sum(employed_000[sex == "Males"]),
    emp_female = sum(employed_000[sex == "Females"]),
    emp_wa = sum(employed_000[state == "Western Australia"]),
    .groups = "drop"
  ) |>
  mutate(emp_share = emp / sum(emp), emp_share_wa = emp_wa / sum(emp_wa)) |>
  left_join(v12_units, by = "unit") |>
  relocate(title, .after = unit)

alloc_log <- alloc |>
  group_by(nfd_code, rule) |>
  summarise(nfd_emp_000_avg = sum(allocated_000) / length(pool_months), n_children = n_distinct(unit), .groups = "drop") |>
  arrange(desc(nfd_emp_000_avg))

dir.create(out_path("m1"), recursive = TRUE, showWarnings = FALSE)
write_csv(emp_cells, interim_path("emp_cells.csv"))
write_csv(emp_units, interim_path("emp_units.csv"))
write_csv(alloc_log, out_path("m1", "eq08_nfd_allocation_log.csv"))

eq08_counts <- eq08 |>
  mutate(geo = if_else(state == "Western Australia", "AU-WA", "other states")) |>
  group_by(month) |>
  summarise(rows = n(), rows_wa = sum(geo == "AU-WA"), codes = n_distinct(code), nfd_codes = n_distinct(code[nfd]),
            nfd_share = sum(employed_000[nfd]) / sum(employed_000),
            emp_wa_000 = sum(employed_000[geo == "AU-WA"]),
            emp_total_000 = sum(employed_000), .groups = "drop")
write_csv(eq08_counts, out_path("m1", "eq08_row_counts.csv"))

print(eq08_counts)
message("Pooled employment ('000): ", round(sum(emp_units$emp), 1), "; WA: ", round(sum(emp_units$emp_wa), 1))
message("nfd employment allocated by national fallback ('000, pooled): ",
        round(sum(alloc_log$nfd_emp_000_avg[alloc_log$rule != "cell"]), 2))
