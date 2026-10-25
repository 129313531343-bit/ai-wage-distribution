# Registry of every raw input: where it comes from, where it lands, and its licence.
# 01_fetch.R downloads the "script" rows and writes data/raw/MANIFEST.csv from this table.
# Licence fields were checked by hand on 25 Oct 2026; `licence_checked` says where.

library(tibble)

AEI_COMMIT <- "4e5f69fab13a9c3f7d0dcc31a6f893a9818738f6"
ELOUNDOU_COMMIT <- "0471612fef3cc22b74fb884d27bff9dbd3770582"
AIOE_COMMIT <- "adca5fc2cd0e9a659ff05278b7fa7a53f4f324c1"

hf <- function(path) {
  sprintf("https://huggingface.co/datasets/Anthropic/EconomicIndex/resolve/%s/%s", AEI_COMMIT, path)
}
abs_old <- "https://www.abs.gov.au/ausstats/subscriber.nsf/log?openagent&"
abs_anzsco <- "https://www.abs.gov.au/statistics/classifications/anzsco-australian-and-new-zealand-standard-classification-occupations/"
onet <- "https://www.onetcenter.org/dl_files/database/db_31_0_csv/"

lic_aei <- "CC-BY (version not stated on dataset card); HF metadata tag: MIT"
lic_aei_url <- sprintf("https://huggingface.co/datasets/Anthropic/EconomicIndex/blob/%s/README.md", AEI_COMMIT)
lic_abs <- "CC BY 4.0"
lic_abs_url <- "https://www.abs.gov.au/website-privacy-copyright-and-disclaimer"
lic_onet <- "CC BY 4.0"
lic_onet_url <- "https://www.onetcenter.org/license_db.html"
lic_bls <- "US Government work, public domain"
lic_bls_url <- "https://www.bls.gov/opub/copyright-information.htm"

sources <- tribble(
  ~id, ~dest, ~url, ~method, ~version, ~licence, ~licence_url, ~licence_checked, ~notes,

  # Anthropic Economic Index (pinned commit)
  "aei_card", "aei/README.md", hf("README.md"), "script", AEI_COMMIT,
  lic_aei, lic_aei_url, "dataset card at pinned commit",
  "Card text: 'Data released under CC-BY, code released under MIT License'. YAML header: 'license: mit'.",
  "aei_job_exposure", "aei/job_exposure.csv", hf("labor_market_impacts/job_exposure.csv"), "script", AEI_COMMIT,
  lic_aei, lic_aei_url, "dataset card at pinned commit", "Massenkoff and McCrory (2026) observed exposure, SOC 2018 6-digit.",
  "aei_task_penetration", "aei/task_penetration.csv", hf("labor_market_impacts/task_penetration.csv"), "script", AEI_COMMIT,
  lic_aei, lic_aei_url, "dataset card at pinned commit", "",
  "aei_claude_ai_2026_06_26", "aei/aei_claude_ai_2026-06-26.csv", hf("release_2026_06_26/data/aei_claude_ai_2026-06-26.csv"), "script", AEI_COMMIT,
  lic_aei, lic_aei_url, "dataset card at pinned commit", "Long format. Queried with DuckDB.",
  "aei_doc_2026_06_26", "aei/data_documentation_2026_06_26.md", hf("release_2026_06_26/data_documentation.md"), "script", AEI_COMMIT,
  lic_aei, lic_aei_url, "dataset card at pinned commit", "",
  "mm_appendix", "docs_ref/massenkoff_mccrory_2026_appendix.pdf",
  "https://www-cdn.anthropic.com/files/4zrzovbb/website/e5f77fc0e77c0185110b5e4b909602791ae76eae.pdf", "script", "5 Mar 2026",
  "Not stated", "https://www.anthropic.com/research/labor-market-impacts", "paper page",
  "Reference copy for reading the method. Not redistributed.",

  # O*NET 31.0
  "onet_task_statements", "onet/task_statements.csv", paste0(onet, "task_statements.csv"), "script", "O*NET 31.0",
  lic_onet, lic_onet_url, "O*NET licence page", "Credit line recorded in docs/credits.md.",
  "onet_task_ratings", "onet/task_ratings.csv", paste0(onet, "task_ratings.csv"), "script", "O*NET 31.0",
  lic_onet, lic_onet_url, "O*NET licence page", "",
  "onet_occupation_data", "onet/occupation_data.csv", paste0(onet, "occupation_data.csv"), "script", "O*NET 31.0",
  lic_onet, lic_onet_url, "O*NET licence page", "",

  # ABS classifications and correspondences
  "abs_v12_isco08", "abs/1220.0 ANZSCO Correspondence to ISCO-08 v2.xls",
  paste0(abs_old, "1220.0%20ANZSCO%20Correspondence%20to%20ISCO-08%20v2.xls&1220.0&Data%20Cubes&A95F7BD105E1C5ABCA257BF90010E155&0&2013,%20Version%201.2&04.10.2013&Latest"),
  "script", "ANZSCO 2013 v1.2, released 4 Oct 2013", lic_abs, lic_abs_url, "ABS copyright page", "",
  "abs_v12_structure", "abs/1220.0 ANZSCO Version 1.2 Structure v3.xls",
  paste0(abs_old, "1220.0%20ANZSCO%20Version%201.2%20Structure%20v3.xls&1220.0&Data%20Cubes&6A8A6C9AC322D9ABCA257B9E0011956C&0&2013,%20Version%201.2&05.07.2013&Latest"),
  "script", "ANZSCO 2013 v1.2", lic_abs, lic_abs_url, "ABS copyright page", "",
  "abs_v13_isco08", "abs/1220.0 anzsco version 1.3 correspondence to isco-08 v1.xlsx",
  paste0(abs_old, "1220.0%20anzsco%20version%201.3%20correspondence%20to%20isco-08%20v1.xlsx&1220.0&Data%20Cubes&EDA6BEDD198E7D49CA2584A8000FF686&0&2013,%20Version%201.3&05.11.2019&Latest"),
  "script", "ANZSCO 2013 v1.3, released 5 Nov 2019", lic_abs, lic_abs_url, "ABS copyright page", "",
  "abs_v13_structure", "abs/1220.0 anzsco version 1.3 structure v1.xlsx",
  paste0(abs_old, "1220.0%20anzsco%20version%201.3%20structure%20v1.xlsx&1220.0&Data%20Cubes&57FF3E8EFF92B344CA2584A8000FF375&0&2013,%20Version%201.3&05.11.2019&Latest"),
  "script", "ANZSCO 2013 v1.3", lic_abs, lic_abs_url, "ABS copyright page", "",
  "abs_v13_whatsnew", "abs/1220.0 anzsco version 1.3 what's new v1.xlsx",
  paste0(abs_old, "1220.0%20anzsco%20version%201.3%20what%27s%20new%20v1.xlsx&1220.0&Data%20Cubes&5B13418EA8D57CAACA2584A8000FF655&0&2013,%20Version%201.3&05.11.2019&Latest"),
  "script", "ANZSCO 2013 v1.3", lic_abs, lic_abs_url, "ABS copyright page", "Used for the v1.3 to v1.2 bridge (no direct table is published).",
  "abs_2021_correspondence", "abs/anzsco 2021 correspondence.xlsx",
  paste0(abs_anzsco, "2021/anzsco%202021%20correspondence.xlsx"),
  "script", "ANZSCO 2021", lic_abs, lic_abs_url, "ABS copyright page", "2021 to v1.3 and ISCO-08.",
  "abs_2021_structure", "abs/anzsco 2021 structure v1.2 062023.xlsx",
  paste0(abs_anzsco, "2021/anzsco%202021%20structure%20v1.2%20062023.xlsx"),
  "script", "ANZSCO 2021", lic_abs, lic_abs_url, "ABS copyright page", "",
  "abs_2022_correspondence", "abs/anzsco 2022 correspondence tables.xlsx",
  paste0(abs_anzsco, "2022/anzsco%202022%20correspondence%20tables.xlsx"),
  "script", "ANZSCO 2022", lic_abs, lic_abs_url, "ABS copyright page", "2022 to 2021 and ISCO-08; 'p' partial flags, no proportions.",
  "abs_2022_structure", "abs/anzsco 2022 structure 062023.xlsx",
  paste0(abs_anzsco, "2022/anzsco%202022%20structure%20062023.xlsx"),
  "script", "ANZSCO 2022", lic_abs, lic_abs_url, "ABS copyright page", "",

  # ABS employment and earnings
  "abs_eq08", "abs/EQ08_mar2026.xlsx",
  "https://www.abs.gov.au/statistics/labour/employment-and-unemployment/labour-force-australia-detailed/mar-2026/EQ08.xlsx",
  "script", "Labour Force, Australia, Detailed, March 2026", lic_abs, lic_abs_url, "ABS copyright page",
  "Final release under this title. Last quarter Feb 2026. Coded to ANZSCO 2013 v1.2.",
  "abs_eeh_cubes", "abs/eeh_may2025_all_data_cubes.zip",
  "https://www.abs.gov.au/statistics/labour/earnings-and-working-conditions/employee-earnings-and-hours-australia/may-2025/All%20data%20cubes.zip",
  "script", "Employee Earnings and Hours, May 2025 (released 23 Jan 2026)", lic_abs, lic_abs_url, "ABS copyright page", "",

  "abs_wa_table04", "abs/63360_Table04_working_arrangements_aug2025.xlsx",
  "https://www.abs.gov.au/statistics/labour/earnings-and-working-conditions/working-arrangements/aug-2025/63360_Table04.xlsx",
  "script", "Working arrangements, August 2025, Table 4", lic_abs, lic_abs_url, "ABS copyright page",
  "Form of employment (employees, OMIEs, OMUEs) by occupation; used only to list owner-manager-heavy groups. Added in M3.",

  # ATO
  "ato_ts24_table15", "ato/ts24individual15occupationsex.xlsx",
  "https://data.gov.au/data/dataset/faea4485-f407-457d-97f8-3f0822ccd654/resource/3286e287-ee87-4be4-87b2-56c5c6602009/download/ts24individual15occupationsex.xlsx",
  "script", "Taxation Statistics 2023-24, Individuals Table 15", "CC BY 2.5 AU",
  "http://creativecommons.org/licenses/by/2.5/au/", "data.gov.au package metadata (taxation-statistics-2023-24)",
  "Table 15B used. Table 14 deliberately not used.",

  # Potential-exposure measures
  "jsa_occupations_8", "jsa/Occupations_8.csv",
  "https://www.jobsandskills.gov.au/sites/default/files/2025-09/Occupations_8.csv",
  "script", "Our Gen AI Transition (14 Aug 2025)", "CC BY 4.0",
  "https://www.jobsandskills.gov.au/copyright", "JSA copyright page", "Required attribution: (c) Commonwealth of Australia.",
  "eloundou_occ_level", "eloundou/occ_level.csv",
  sprintf("https://raw.githubusercontent.com/openai/GPTs-are-GPTs/%s/data/occ_level.csv", ELOUNDOU_COMMIT),
  "script", ELOUNDOU_COMMIT, "MIT",
  sprintf("https://github.com/openai/GPTs-are-GPTs/blob/%s/LICENSE", ELOUNDOU_COMMIT), "repository LICENSE file", "",
  "aioe_appendix", "aioe/AIOE_DataAppendix.xlsx",
  sprintf("https://raw.githubusercontent.com/AIOE-Data/AIOE/%s/AIOE_DataAppendix.xlsx", AIOE_COMMIT),
  "script", AIOE_COMMIT, "None stated", "https://github.com/AIOE-Data/AIOE", "repository has no licence file",
  "Not redistributed. Used only in aggregate charts and correlations; no per-occupation values are published.",
  "aioe_lm", "aioe/Language Modeling AIOE and AIIE.xlsx",
  sprintf("https://raw.githubusercontent.com/AIOE-Data/AIOE/%s/Language%%20Modeling%%20AIOE%%20and%%20AIIE.xlsx", AIOE_COMMIT),
  "script", AIOE_COMMIT, "None stated", "https://github.com/AIOE-Data/AIOE", "repository has no licence file",
  "Not redistributed. Aggregate use only.",

  # Fourth crosswalk scheme (decision D2)
  "lmi_anzsco_onetsoc", "lmi/anzsco-2013-to-onet-soc-2019.xlsx",
  "https://web.archive.org/web/20240315061455/https://labourmarketinsights.gov.au/media/pmukn3qt/anzsco-2013-to-onet-soc-2019.xlsx",
  "script", "Internet Archive capture 15 Mar 2024; ANZSCO 2013 v1.2 (per the file's Notes sheet)", "CC BY 4.0",
  "https://web.archive.org/web/20240103062525/https://labourmarketinsights.gov.au/copyright/",
  "archived LMI copyright page (captured 3 Jan 2024)",
  "Original site no longer resolves. Required attribution (file Notes sheet): Jobs and Skills Australia, ANZSCO 2013 Version 1.2 to O*NET-SOC 2019 Taxonomy correspondence.",

  # Manual downloads (BLS returns 403 to scripts)
  "bls_soc_2010_2018", "manual/soc_2010_to_2018_crosswalk.xlsx",
  "https://www.bls.gov/soc/2018/soc_2010_to_2018_crosswalk.xlsx", "manual", "SOC 2010 to 2018",
  lic_bls, lic_bls_url, "BLS copyright page", "Downloaded by hand.",
  "bls_isco_soc", "manual/ISCO_SOC_Crosswalk.xls",
  "https://www.bls.gov/soc/ISCO_SOC_Crosswalk.xls", "manual", "ISCO-08 to SOC 2010",
  lic_bls, lic_bls_url, "BLS copyright page", "Downloaded by hand.",
  "bls_oews_2025", "manual/oesm25nat.zip",
  "https://www.bls.gov/oes/special-requests/oesm25nat.zip", "manual", "OEWS May 2025 national",
  lic_bls, lic_bls_url, "BLS copyright page", "Downloaded by hand."
)
