# Links for scheme 4 (decision D2): the JSA/LMI ANZSCO 2013 v1.2 to O*NET-SOC 2019 correspondence.
# The file mixes rows for unit groups (4-digit) and occupations (6-digit). A unit's links are the
# union of the O*NET-SOC codes on its own row and on its occupations' rows, rolled up to SOC 2018
# 6-digit codes. Rows graded NONE (no match) are dropped. The strongest grade per link is kept so
# that POOR-only links can be excluded in a sensitivity check.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(readxl)
})
source("R/utils.R")

lmi <- read_excel(raw_path("lmi", "anzsco-2013-to-onet-soc-2019.xlsx"), sheet = 2, skip = 3, col_types = "text")
names(lmi) <- c("order", "anzsco", "anzsco_title", "onetsoc", "onetsoc_title", "strength")
lmi <- lmi |> filter(!is.na(anzsco))

strength_rank <- c(GOOD = 1, ACCEPTABLE = 2, POOR = 3)
links_lmi <- lmi |>
  filter(strength != "NONE", onetsoc != "n/a") |>
  transmute(unit = substr(anzsco, 1, 4), soc = substr(onetsoc, 1, 7),
            row_level = if_else(nchar(anzsco) == 4, "unit row", "occupation row"), strength) |>
  group_by(unit, soc) |>
  summarise(strength = names(strength_rank)[min(strength_rank[strength])],
            row_levels = paste(sort(unique(row_level)), collapse = ";"), .groups = "drop")

v12_units <- read_codes_csv(interim_path("v12_units.csv"))
stopifnot(all(links_lmi$unit %in% v12_units$unit))
write_csv(links_lmi, interim_path("links_scheme4_lmi.csv"))

message("Scheme 4 links: ", nrow(links_lmi), " unit-SOC pairs; units with at least one link: ",
        n_distinct(links_lmi$unit), " of ", nrow(v12_units))
print(count(links_lmi, strength))
message("Units with no link: ", paste(setdiff(v12_units$unit, links_lmi$unit), collapse = ", "))
