# Unit-SOC links for schemes 1-3 and the validation chain.
#   Primary chain: SOC 2018 -> SOC 2010 -> ISCO-08 -> ANZSCO v1.2 occupation -> v1.2 unit group.
#   Validation chain: the same, except ISCO-08 -> ANZSCO 2022 -> 2021 -> v1.3 (= v1.2).
#   Scheme 3: title-match-first subset of the primary links.
#   AIOE (SOC 2010 codes) enters the primary chain at the SOC 2010 step.
#   SOC weights: OEWS May 2025 national employment (scheme 1, 3 and 4 weights).
# Requires the three BLS files in data/raw/manual/.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})
source("R/utils.R")
source("R/fn_bls.R")
source("R/fn_titles.R")

soc_measures <- read_codes_csv(interim_path("soc_measures.csv"))
v12_units <- read_codes_csv(interim_path("v12_units.csv"))
v12_codes6 <- read_codes_csv(interim_path("v12_codes6.csv"))
v12_isco <- read_codes_csv(interim_path("link_v12occ_isco.csv"))
isco_v12_alt <- read_codes_csv(interim_path("link_isco_v12_via2022.csv"))

x1018 <- read_soc_2010_2018(raw_path("manual", "soc_2010_to_2018_crosswalk.xlsx"))
isco_soc <- read_isco_soc2010(raw_path("manual", "ISCO_SOC_Crosswalk.xls"))
oews <- read_oews_national(raw_path("manual", "oesm25nat.zip"))
soc_w <- soc_weights_from_oews(oews, soc_measures$soc)

# Australian occupations only (the ISCO correspondence also lists New Zealand-only codes).
au_occ <- v12_codes6 |> filter(!nfd) |> pull(code)
v12_isco_au <- v12_isco |> filter(anzsco6 %in% au_occ)

chain <- v12_isco_au |>
  select(anzsco6, isco4) |>
  inner_join(isco_soc |> select(isco4, soc2010), by = "isco4", relationship = "many-to-many") |>
  inner_join(x1018, by = "soc2010", relationship = "many-to-many") |>
  transmute(unit = substr(anzsco6, 1, 4), anzsco6, isco4, soc2010, soc = soc2018)

links1 <- chain |>
  group_by(unit, soc) |>
  summarise(n_paths = n(), isco_codes = paste(sort(unique(isco4)), collapse = ";"), .groups = "drop")

chain_alt <- isco_v12_alt |>
  filter(anzsco6 %in% au_occ) |>
  inner_join(isco_soc |> select(isco4, soc2010), by = "isco4", relationship = "many-to-many") |>
  inner_join(x1018, by = "soc2010", relationship = "many-to-many") |>
  distinct(unit = unit_v12, soc = soc2018)

links_aioe <- v12_isco_au |>
  select(anzsco6, isco4) |>
  inner_join(isco_soc |> select(isco4, soc2010), by = "isco4", relationship = "many-to-many") |>
  distinct(unit = substr(anzsco6, 1, 4), soc2010)

# Scheme 3: title-match-first, applied occupation by occupation so that matching one
# occupation in a unit does not drop the unit's other occupations. For each v1.2 occupation,
# keep only the SOCs whose title matches the occupation's (or its unit's) title if there are
# any; otherwise keep all its SOCs. A unit's links are the union over its occupations.
occ_links <- chain |> distinct(anzsco6, unit, soc)
occ_titles <- v12_codes6 |>
  filter(!nfd) |>
  transmute(anzsco6 = code, unit = substr(code, 1, 4), occ_title = title) |>
  left_join(v12_units |> select(unit, unit_title = title), by = "unit") |>
  tidyr::pivot_longer(c(occ_title, unit_title), values_to = "anz_title") |>
  select(anzsco6, anz_title)
soc_titles <- soc_measures |> select(soc, soc_title = title)
matches3 <- title_matches(occ_links |> transmute(unit = anzsco6, soc), occ_titles |> rename(unit = anzsco6), soc_titles) |>
  rename(anzsco6 = unit)
links3 <- bind_rows(
  occ_links |> semi_join(matches3, by = c("anzsco6", "soc")) |> mutate(matched = TRUE),
  occ_links |> filter(!anzsco6 %in% matches3$anzsco6) |> mutate(matched = FALSE)
) |>
  group_by(unit, soc) |>
  summarise(matched = any(matched), .groups = "drop")

# Validation: compare the unit-SOC link sets of the primary and 2022-path chains.
validation <- full_join(
  links1 |> group_by(unit) |> summarise(socs_primary = list(soc), .groups = "drop"),
  chain_alt |> group_by(unit) |> summarise(socs_alt = list(soc), .groups = "drop"),
  by = "unit"
) |>
  rowwise() |>
  mutate(n_primary = length(socs_primary), n_alt = length(socs_alt),
         n_common = length(intersect(socs_primary, socs_alt)),
         jaccard = if (n_primary + n_alt == 0) NA_real_ else n_common / length(union(socs_primary, socs_alt)),
         only_primary = paste(setdiff(socs_primary, socs_alt), collapse = ";"),
         only_alt = paste(setdiff(socs_alt, socs_primary), collapse = ";")) |>
  ungroup() |>
  select(-socs_primary, -socs_alt)

# SOC 2010 weights for AIOE: OEWS SOC 2018 employment split across linked SOC 2010 codes.
w2010 <- x1018 |>
  inner_join(soc_w, by = c("soc2018" = "soc")) |>
  group_by(soc2018) |> mutate(w = w / n()) |> ungroup() |>
  group_by(soc2010) |> summarise(w = sum(w), .groups = "drop")

dir.create(out_path("m2"), recursive = TRUE, showWarnings = FALSE)
write_csv(soc_w, interim_path("soc_weights_oews.csv"))
write_csv(links1, interim_path("links_scheme1_isco.csv"))
write_csv(links3, interim_path("links_scheme3_title.csv"))
write_csv(matches3, out_path("m2", "scheme3_title_matches.csv"))
write_csv(chain_alt, interim_path("links_validation_2022path.csv"))
write_csv(links_aioe, interim_path("links_aioe_soc2010_NOT_FOR_PUBLICATION.csv"))
write_csv(w2010, interim_path("soc2010_weights_oews.csv"))
write_csv(validation, out_path("m2", "chain_validation_primary_vs_2022path.csv"))

message("SOC 2010-2018 links: ", nrow(x1018), "; ISCO-SOC 2010 links: ", nrow(isco_soc))
message("OEWS weights: ", nrow(soc_w), " of ", nrow(soc_measures), " SOC codes (",
        sum(soc_w$source != "OEWS detailed"), " filled from broad groups)")
message("Primary chain: ", nrow(links1), " unit-SOC links; units linked: ", n_distinct(links1$unit), " of ", nrow(v12_units))
message("ISCO units used: ", n_distinct(chain$isco4))
message("Scheme 3: ", n_distinct(matches3$anzsco6), " occupations in ", n_distinct(substr(matches3$anzsco6, 1, 4)),
        " units with a title match")
message("Validation: units with identical link sets: ", sum(validation$jaccard == 1, na.rm = TRUE),
        "; median Jaccard: ", round(median(validation$jaccard, na.rm = TRUE), 2))
