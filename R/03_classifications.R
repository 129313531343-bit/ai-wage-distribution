# Build the ANZSCO edition spine and bridges.
#   - v1.2 unit groups and 6-digit occupations (the analysis spine)
#   - a check that v1.3 has the same codes as v1.2 (the v1.3 "what's new" file lists no code changes)
#   - v1.2 6-digit occupations to ISCO-08 (primary chain)
#   - ANZSCO 2022 unit groups to v1.2 unit groups, via 2022 -> 2021 -> v1.3 (= v1.2)
#   - ISCO-08 to v1.2 through the 2022 tables (validation chain)
# Outputs go to data/interim/.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})
source("R/utils.R")
source("R/fn_abs.R")

abs <- function(f) raw_path("abs", f)
f_v12_struct <- abs("1220.0 ANZSCO Version 1.2 Structure v3.xls")
f_v13_struct <- abs("1220.0 anzsco version 1.3 structure v1.xlsx")
f_v12_isco <- abs("1220.0 ANZSCO Correspondence to ISCO-08 v2.xls")
f_2021 <- abs("anzsco 2021 correspondence.xlsx")
f_2022 <- abs("anzsco 2022 correspondence tables.xlsx")

# v1.2 spine ----------------------------------------------------------------
v12_units <- read_abs_units(f_v12_struct)
v12_codes6 <- read_abs_codes6(f_v12_struct) |> mutate(nfd = grepl("\\bnfd$", title))
stopifnot(!anyDuplicated(v12_units$unit), !anyDuplicated(v12_codes6$code))

# v1.3 against v1.2 -----------------------------------------------------------
v13_units <- read_abs_units(f_v13_struct)
v13_codes6 <- read_abs_codes6(f_v13_struct)
v13_check <- tibble(
  level = c("unit groups", "6-digit codes"),
  n_v12 = c(nrow(v12_units), nrow(v12_codes6)),
  n_v13 = c(nrow(v13_units), nrow(v13_codes6)),
  only_v12 = c(length(setdiff(v12_units$unit, v13_units$unit)), length(setdiff(v12_codes6$code, v13_codes6$code))),
  only_v13 = c(length(setdiff(v13_units$unit, v12_units$unit)), length(setdiff(v13_codes6$code, v12_codes6$code)))
)
v13_identical <- all(v13_check$only_v12 == 0 & v13_check$only_v13 == 0)

# v1.2 to ISCO-08 (primary chain) ---------------------------------------------
v12_isco <- read_abs_corr(f_v12_isco, "ANZSCO Version 1.2 to ISCO-08") |>
  filter(nchar(from_code) == 6, nchar(to_code) == 4) |>
  transmute(anzsco6 = from_code, anzsco6_title = from_title, isco4 = to_code, isco_title = to_title, partial)

# 2022 -> 2021 -> v1.3 at 6-digit, then to unit groups ------------------------
t22_21 <- read_abs_corr(f_2022, "Table 2") |> filter(nchar(from_code) == 6, nchar(to_code) == 6)
t21_13 <- read_abs_corr(f_2021, "Table 2") |> filter(nchar(from_code) == 6, nchar(to_code) == 6)
links6 <- t22_21 |>
  select(code2022 = from_code, code2021 = to_code, p1 = partial) |>
  inner_join(t21_13 |> select(code2021 = from_code, code13 = to_code, p2 = partial),
             by = "code2021", relationship = "many-to-many")

bridge_2022_v12 <- links6 |>
  mutate(unit2022 = substr(code2022, 1, 4), unit_v12 = substr(code13, 1, 4)) |>
  count(unit2022, unit_v12, name = "n_links6") |>
  group_by(unit2022) |> mutate(n_targets = n()) |>
  group_by(unit_v12) |> mutate(n_sources = n()) |> ungroup() |>
  mutate(type = case_when(
    n_targets == 1 & n_sources == 1 & unit2022 == unit_v12 ~ "same code",
    n_targets == 1 & n_sources == 1 ~ "recoded one-to-one",
    n_targets == 1 & n_sources > 1 ~ "merge (several 2022 units into one v1.2 unit)",
    n_targets > 1 & n_sources == 1 ~ "split (one 2022 unit into several v1.2 units)",
    TRUE ~ "many-to-many"
  ))

# ISCO-08 -> 2022 -> v1.2 (validation chain) -----------------------------------
t22_isco <- read_abs_corr(f_2022, "Table 4") |>
  filter(nchar(from_code) == 6, nchar(to_code) == 4) |>
  select(code2022 = from_code, isco4 = to_code, partial)
isco_v12_alt <- t22_isco |>
  inner_join(links6 |> select(code2022, code13), by = "code2022", relationship = "many-to-many") |>
  transmute(isco4, anzsco6 = code13, unit_v12 = substr(code13, 1, 4)) |>
  distinct()

# Write ---------------------------------------------------------------------
dir.create(interim_path(), showWarnings = FALSE)
write_csv(v12_units, interim_path("v12_units.csv"))
write_csv(v12_codes6, interim_path("v12_codes6.csv"))
write_csv(v13_check, interim_path("check_v13_vs_v12.csv"))
write_csv(v12_isco, interim_path("link_v12occ_isco.csv"))
write_csv(bridge_2022_v12, interim_path("bridge_2022units_v12units.csv"))
write_csv(isco_v12_alt, interim_path("link_isco_v12_via2022.csv"))

message("v1.2: ", nrow(v12_units), " unit groups, ", sum(!v12_codes6$nfd), " occupations (", sum(v12_codes6$nfd), " nfd codes)")
message("v1.3 identical to v1.2 in codes: ", v13_identical)
print(v13_check)
message("v1.2 -> ISCO links: ", nrow(v12_isco), " (", n_distinct(v12_isco$anzsco6), " occupations, ",
        n_distinct(v12_isco$isco4), " ISCO units)")
print(count(bridge_2022_v12, type))
print(as.data.frame(filter(bridge_2022_v12, type != "same code")), row.names = FALSE)
