# Earnings by v1.2 unit group.
#   Primary (C1): EEH May 2025 cube 11, average weekly total cash earnings, all employees, 4-digit.
#                 No EEH cube gives hourly earnings at 4-digit (checked in M1).
#   Alternatives (C2): EEH cube 13 (hourly total cash earnings, full-time non-managerial
#                 adults, 3-digit) and ATO Taxation Statistics 2023-24 Table 15B.
# EEH and ATO use ANZSCO 2022 unit groups; they are bridged to v1.2 with fn_bridge.R.
# Merge weights are ATO individual counts for each 2022 unit group (the only source here
# with counts at that level); this is logged in decision_log.md.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(readxl)
  library(stringr)
})
source("R/utils.R")
source("R/fn_abs.R")
source("R/fn_bridge.R")

bridge <- read_codes_csv(interim_path("bridge_2022units_v12units.csv"))
v12_units <- read_codes_csv(interim_path("v12_units.csv"))
emp <- read_codes_csv(interim_path("emp_units.csv")) |> select(unit, emp)

# EEH cubes (read from inside the raw zip, which is never modified) --------------
eeh_dir <- file.path(tempdir(), "eeh")
unzip(raw_path("abs", "eeh_may2025_all_data_cubes.zip"), exdir = eeh_dir,
      files = c("63060DO011_202505.xlsx", "63060DO013_202505.xlsx"))
cube11 <- file.path(eeh_dir, "63060DO011_202505.xlsx")
cube13 <- file.path(eeh_dir, "63060DO013_202505.xlsx")

c11 <- read_eeh_table(cube11, "Table_1", c("weekly_m", "weekly_f", "weekly_p", "age_m", "age_f", "age_p")) |>
  left_join(read_eeh_table(cube11, "Table_2", c("se_m", "se_f", "se_p", "se_age_m", "se_age_f", "se_age_p")) |> select(-title),
            by = "code") |>
  mutate(rse_p = se_p / weekly_p, rse_m = se_m / weekly_m, rse_f = se_f / weekly_f)
stopifnot(nrow(c11) == 364, all(nchar(c11$code) == 4))

series13 <- c("ot_weekly", "total_weekly", "ot_hours", "total_hours", "ot_hourly", "total_hourly")
names13 <- c(paste0(series13, "_m"), paste0(series13, "_f"), paste0(series13, "_p"))
c13 <- read_eeh_table(cube13, "Table_1", names13) |>
  left_join(read_eeh_table(cube13, "Table_2", paste0("se_", names13)) |> select(-title), by = "code") |>
  filter(nchar(code) == 3) |>
  transmute(minor2022 = code, hourly_p = total_hourly_p, rse_hourly_p = se_total_hourly_p / total_hourly_p)

# ATO Table 15B --------------------------------------------------------------
ato <- read_excel(raw_path("ato", "ts24individual15occupationsex.xlsx"), sheet = "Table 15B", skip = 1, col_types = "text")
names(ato) <- c("submajor", "unit", "sex", "individuals", "avg_taxable", "med_taxable",
                "avg_sw", "med_sw", "avg_total", "med_total")
ato <- ato |>
  filter(!is.na(unit), sex == "Total") |>
  transmute(code = str_extract(unit, "^\\d{4}"), title = str_squish(str_remove(unit, "^\\d{4}")),
            individuals = as.numeric(individuals), avg_sw = as.numeric(avg_sw), med_sw = as.numeric(med_sw))

ato_lookup <- ato |>
  mutate(mapping = if_else(code %in% bridge$unit2022, "ANZSCO 2022 unit group, bridged to v1.2",
                           "no ANZSCO unit group (blank, type not specified, or ATO-specific code)")) |>
  mutate(share_of_individuals = individuals / sum(individuals))
weights_2022 <- ato |> filter(code %in% bridge$unit2022) |> transmute(unit2022 = code, w = individuals)

# Bridge to v1.2 ----------------------------------------------------------------
eeh_v12 <- bridge_to_v12(
  c11 |> transmute(unit2022 = code, weekly_p, weekly_m, weekly_f, rse_p),
  c("weekly_p", "weekly_m", "weekly_f"), bridge, weights_2022, rse_col = "rse_p"
) |>
  rename(unit = unit_v12, eeh_sources = sources, eeh_bridge = bridge_type, eeh_rse_max = rse_max)

hourly_v12 <- bridge |>
  mutate(minor2022 = substr(unit2022, 1, 3)) |>
  left_join(c13, by = "minor2022") |>
  left_join(weights_2022, by = "unit2022") |>
  filter(!is.na(hourly_p)) |>
  group_by(unit = unit_v12) |>
  summarise(eeh13_hourly_p = sum(coalesce(w, 1) * hourly_p) / sum(coalesce(w, 1)),
            eeh13_rse_max = max(rse_hourly_p, na.rm = TRUE), .groups = "drop")

ato_v12 <- bridge_to_v12(
  ato |> filter(code %in% bridge$unit2022) |> transmute(unit2022 = code, ato_avg_sw = avg_sw, ato_med_sw = med_sw),
  c("ato_avg_sw", "ato_med_sw"), bridge, weights_2022
) |>
  select(unit = unit_v12, ato_avg_sw, ato_med_sw)

earnings <- v12_units |>
  left_join(eeh_v12, by = "unit") |>
  left_join(hourly_v12, by = "unit") |>
  left_join(ato_v12, by = "unit")

earnings <- earnings |>
  rename(eeh_weekly_p_raw = weekly_p) |>
  mutate(eeh_weekly_p = eeh_weekly_p_raw) |>
  impute_from_parent("eeh_weekly_p", emp) |>
  rename(eeh_imputed = imputed) |>
  impute_from_parent("eeh13_hourly_p", emp) |>
  rename(eeh13_imputed = imputed) |>
  impute_from_parent("ato_avg_sw", emp) |>
  rename(ato_imputed = imputed)

dir.create(out_path("m2"), recursive = TRUE, showWarnings = FALSE)
write_csv(earnings, interim_path("earnings_units.csv"))
write_csv(ato_lookup, out_path("m2", "ato_code_lookup.csv"))
write_csv(earnings |> filter(eeh_imputed != "none" | ato_imputed != "none" | eeh13_imputed != "none") |>
            select(unit, title, eeh_imputed, eeh13_imputed, ato_imputed, eeh_sources, eeh_bridge),
          out_path("m2", "earnings_imputation_log.csv"))

message("EEH cube 11: ", sum(!is.na(c11$weekly_p)), " of 364 units published (persons)")
message("v1.2 units with direct EEH weekly value: ", sum(!is.na(earnings$eeh_weekly_p_raw)), " of ", nrow(earnings))
print(count(earnings, eeh_imputed)); print(count(earnings, eeh13_imputed)); print(count(earnings, ato_imputed))
message("EEH RSE > 25%: ", sum(earnings$eeh_rse_max > 0.25, na.rm = TRUE), " units")
message("ATO individuals in codes with no ANZSCO unit group: ",
        round(100 * sum(ato_lookup$share_of_individuals[ato_lookup$mapping != "ANZSCO 2022 unit group, bridged to v1.2"]), 1),
        "% (of which blank: ", round(100 * ato_lookup$share_of_individuals[ato_lookup$code == "0000"], 1), "%)")
