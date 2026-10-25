# Occupation-level measures before any crosswalk to ANZSCO.
#   US side, keyed by SOC 2018 6-digit code:
#     - usage-based exposure (AEI job_exposure.csv, observed_exposure)
#     - Eloundou et al. beta (O*NET-SOC 2019 codes averaged within SOC 2018 6-digit)
#     - global Claude.ai automation share (AEI 2026-06-26, GLOBAL, soc_occupation level 0)
#     - AIOE and LM-AIOE (kept in data/interim only; never published per occupation)
#   Australian side, keyed by v1.2 unit group:
#     - JSA automation and augmentation exposure ("All occupations" rows; v1.3 = v1.2 codes)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(readxl)
  library(stringr)
  library(DBI)
  library(duckdb)
})
source("R/utils.R")

# SOC 2018 detailed codes from O*NET 31.0 (867 distinct 6-digit codes) ----------
onet_occ <- read_csv(raw_path("onet", "occupation_data.csv"), show_col_types = FALSE)
soc2018 <- onet_occ |>
  transmute(onetsoc = `O*NET-SOC Code`, soc = substr(onetsoc, 1, 7), title = Title) |>
  filter(endsWith(onetsoc, ".00")) |>
  distinct(soc, title)
stopifnot(n_distinct(substr(onet_occ$`O*NET-SOC Code`, 1, 7)) == 867, nrow(soc2018) == 867)

# Usage-based exposure -------------------------------------------------------------
je <- read_csv(raw_path("aei", "job_exposure.csv"), show_col_types = FALSE) |>
  transmute(soc = occ_code, usage_exposure = observed_exposure)

# Eloundou beta (GPT-4 rating primary, human rating as a check) -----------------------
el <- read_csv(raw_path("eloundou", "occ_level.csv"), show_col_types = FALSE) |>
  transmute(soc = substr(`O*NET-SOC Code`, 1, 7), beta_gpt4 = dv_rating_beta, beta_human = human_rating_beta) |>
  group_by(soc) |>
  summarise(across(c(beta_gpt4, beta_human), mean), n_onetsoc = n(), .groups = "drop")

# Global Claude.ai automation share by detailed SOC ------------------------------------
con <- dbConnect(duckdb(shared_home = FALSE))
dbExecute(con, sprintf("CREATE VIEW aei AS SELECT * FROM read_csv_auto(%s, header = true)",
                       dbQuoteString(con, raw_path("aei", "aei_claude_ai_2026-06-26.csv"))))
auto <- dbGetQuery(con, "
  SELECT node_external_id AS soc, node_name,
         strftime(date_start, '%Y-%m') AS period, metric_id, value
  FROM aei
  WHERE geo_id = 'GLOBAL' AND category_name = 'soc_occupation' AND hierarchy_level = 0
    AND metric_id IN ('pct', 'collaboration_bucket_automation_pct', 'collaboration_bucket_augmentation_pct')")
dbDisconnect(con, shutdown = TRUE)
# Level-0 nodes are O*NET-SOC codes (e.g. 15-2051.02); shares are pooled to SOC 6-digit
# across both months, weighting each O*NET-SOC month cell by its usage share.
auto_soc <- auto |>
  tidyr::pivot_wider(names_from = metric_id, values_from = value) |>
  mutate(soc = substr(soc, 1, 7)) |>
  group_by(soc) |>
  summarise(
    global_automation_pct = weighted.mean(collaboration_bucket_automation_pct, pct, na.rm = TRUE),
    global_augmentation_pct = weighted.mean(collaboration_bucket_augmentation_pct, pct, na.rm = TRUE),
    global_usage_pct = sum(pct) / n_distinct(period), n_cells = n(), .groups = "drop"
  ) |>
  mutate(across(c(global_automation_pct, global_augmentation_pct), ~ if_else(is.nan(.x), NA_real_, .x)))

# AIOE (SOC vintage checked against SOC 2018 codes) ------------------------------------
aioe <- read_excel(raw_path("aioe", "AIOE_DataAppendix.xlsx"), sheet = "Appendix A") |>
  transmute(soc_aioe = `SOC Code`, aioe = AIOE)
lm_aioe <- read_excel(raw_path("aioe", "Language Modeling AIOE and AIIE.xlsx"), sheet = "LM AIOE") |>
  transmute(soc_aioe = `SOC Code`, lm_aioe = `Language Modeling AIOE`)
aioe <- full_join(aioe, lm_aioe, by = "soc_aioe")
aioe_vintage <- tibble(
  n_codes = nrow(aioe),
  share_in_soc2018 = mean(aioe$soc_aioe %in% soc2018$soc),
  has_2010_software_code_15_1132 = "15-1132" %in% aioe$soc_aioe,
  has_2018_software_code_15_1252 = "15-1252" %in% aioe$soc_aioe
)

# JSA ---------------------------------------------------------------------------
jsa_raw <- read_csv(raw_path("jsa", "Occupations_8.csv"), col_types = cols(.default = "c"))
jsa <- jsa_raw |>
  filter(`Occupation matrix group` == "All occupations") |>
  transmute(unit = `ANZSCO unit code`, jsa_title = `ANZSCO unit title`,
            jsa_augmentation = as.numeric(`Augmentation exposure score`),
            jsa_automation = as.numeric(`Automation exposure score`))
stopifnot(nrow(jsa_raw) == 714, nrow(jsa) == 357, !anyDuplicated(jsa$unit))

soc_measures <- soc2018 |>
  left_join(je, by = "soc") |>
  left_join(el, by = "soc") |>
  left_join(auto_soc |> select(soc, global_automation_pct, global_augmentation_pct, global_usage_pct), by = "soc")

write_csv(soc_measures, interim_path("soc_measures.csv"))
write_csv(aioe, interim_path("aioe_soc_NOT_FOR_PUBLICATION.csv"))
write_csv(jsa, interim_path("jsa_units.csv"))
dir.create(out_path("m2"), recursive = TRUE, showWarnings = FALSE)
write_csv(aioe_vintage, out_path("m2", "aioe_soc_vintage_check.csv"))

message("SOC 2018 codes: ", nrow(soc2018), "; with usage-based exposure: ", sum(!is.na(soc_measures$usage_exposure)),
        "; with Eloundou beta: ", sum(!is.na(soc_measures$beta_gpt4)),
        "; with global automation share: ", sum(!is.na(soc_measures$global_automation_pct)))
message("AEI soc_occupation codes not in SOC 2018 list: ", sum(!auto_soc$soc %in% soc2018$soc))
print(aioe_vintage)
