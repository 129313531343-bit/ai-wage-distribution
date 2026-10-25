# Small helpers shared by the pipeline scripts and the tests.

project_root <- function() {
  # Tests run from tests/testthat; scripts run from the project root.
  here <- normalizePath(getwd())
  while (!file.exists(file.path(here, "R", "00_sources.R"))) {
    parent <- dirname(here)
    if (parent == here) stop("Cannot find the project root")
    here <- parent
  }
  here
}

# Read a pipeline CSV, keeping every code column as character so codes such as
# "0110" keep their leading zeros and never turn into numbers.
read_codes_csv <- function(path) {
  header <- names(readr::read_csv(path, n_max = 0, show_col_types = FALSE))
  code_cols <- c("unit", "code", "unit2022", "unit_v12", "anzsco6", "isco4", "soc", "soc2010", "soc2018",
                 "onetsoc", "minor2022", "nfd_code", "sources", "eeh_sources", "parent", "soc_major", "group",
                 "linked_socs", "isco_codes", "only_primary", "only_alt", "soc_aioe", "prefix")
  is_code <- header %in% code_cols
  types <- setNames(ifelse(is_code, "c", "?"), header)
  readr::read_csv(path, col_types = do.call(readr::cols, as.list(types)))
}

raw_path <- function(...) file.path(project_root(), "data", "raw", ...)

# SOC 2018 detailed occupations: the distinct 6-digit codes in O*NET 31.0 (867 codes).
soc2018_detailed_codes <- function() {
  onet <- readr::read_csv(raw_path("onet", "occupation_data.csv"), show_col_types = FALSE)
  sort(unique(substr(onet[["O*NET-SOC Code"]], 1, 7)))
}
interim_path <- function(...) file.path(project_root(), "data", "interim", ...)
out_path <- function(...) file.path(project_root(), "data", "out", ...)
