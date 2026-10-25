# Readers for the three BLS files downloaded by hand into data/raw/manual/.
# The sheets have title rows above the header, so the header row is found by its labels.

suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
  library(stringr)
})

read_with_header <- function(path, sheet, must_have) {
  raw <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text", .name_repair = "minimal")
  hit <- which(apply(raw, 1, function(r) all(sapply(must_have, function(m) any(str_detect(r, fixed(m)), na.rm = TRUE)))))
  if (length(hit) == 0) stop("Header not found in ", basename(path), " (", sheet, ")")
  hdr <- str_squish(as.character(unlist(raw[hit[1], ])))
  d <- raw[-seq_len(hit[1]), ]
  names(d) <- make.unique(ifelse(is.na(hdr) | hdr == "", "blank", hdr))
  d
}

find_sheet <- function(path, must_have) {
  for (s in excel_sheets(path)) {
    ok <- tryCatch({ read_with_header(path, s, must_have); TRUE }, error = function(e) FALSE)
    if (ok) return(s)
  }
  stop("No sheet with ", paste(must_have, collapse = ", "), " in ", basename(path))
}

soc6 <- function(x) str_extract(x, "\\d{2}-\\d{4}")

# SOC 2010 to SOC 2018 (many-to-many).
read_soc_2010_2018 <- function(path) {
  s <- find_sheet(path, c("2010 SOC Code", "2018 SOC Code"))
  d <- read_with_header(path, s, c("2010 SOC Code", "2018 SOC Code"))
  d |>
    transmute(soc2010 = soc6(`2010 SOC Code`), soc2018 = soc6(`2018 SOC Code`)) |>
    filter(!is.na(soc2010), !is.na(soc2018)) |>
    distinct()
}

# ISCO-08 to SOC 2010, with BLS's partial-match flag.
read_isco_soc2010 <- function(path) {
  s <- find_sheet(path, c("ISCO-08 Code", "2010 SOC Code"))
  d <- read_with_header(path, s, c("ISCO-08 Code", "2010 SOC Code"))
  part_col <- names(d)[str_detect(tolower(names(d)), "^part")][1]
  d |>
    transmute(isco4 = str_extract(`ISCO-08 Code`, "^\\d{4}"), soc2010 = soc6(`2010 SOC Code`),
              partial = if (is.na(part_col)) NA else !is.na(.data[[part_col]]) & .data[[part_col]] != "") |>
    filter(!is.na(isco4), !is.na(soc2010)) |>
    distinct()
}

# OEWS May 2025 national employment by SOC code and level (O_GROUP).
read_oews_national <- function(zip_path) {
  files <- unzip(zip_path, list = TRUE)$Name
  xl <- files[str_detect(files, "national.*\\.xlsx?$")][1]
  if (is.na(xl)) stop("No national workbook in ", basename(zip_path))
  dir <- file.path(tempdir(), "oews")
  unzip(zip_path, files = xl, exdir = dir)
  d <- read_excel(file.path(dir, xl), col_types = "text")
  names(d) <- toupper(names(d))
  d |>
    transmute(occ_code = OCC_CODE, occ_title = OCC_TITLE, o_group = tolower(O_GROUP),
              tot_emp = suppressWarnings(as.numeric(TOT_EMP)))
}

# Employment weights for every SOC 2018 detailed code. Codes that OEWS publishes only as part
# of an aggregate (a broad-group code ending in 0, or another combined code) share that
# aggregate's employment equally. Each fill is logged.
soc_weights_from_oews <- function(oews, soc_detailed) {
  det <- oews |> filter(o_group == "detailed", !is.na(tot_emp)) |> select(soc = occ_code, w = tot_emp)
  direct <- tibble(soc = soc_detailed) |> inner_join(det, by = "soc") |> mutate(source = "OEWS detailed")
  missing <- setdiff(soc_detailed, direct$soc)
  agg <- oews |> filter(!is.na(tot_emp), o_group %in% c("broad", "detailed")) |>
    select(code = occ_code, emp = tot_emp, o_group)
  # A missing detailed code is covered by its broad group (first five digits + 0) when OEWS
  # publishes that group and none of the group's detailed codes carry the employment directly.
  filled <- tibble(soc = missing, broad = paste0(substr(missing, 1, 6), "0")) |>
    left_join(agg |> filter(o_group == "broad") |> select(broad = code, emp), by = "broad") |>
    left_join(direct |> group_by(broad = paste0(substr(soc, 1, 6), "0")) |> summarise(emp_direct = sum(w), .groups = "drop"),
              by = "broad") |>
    mutate(residual = pmax(emp - coalesce(emp_direct, 0), 0)) |>
    group_by(broad) |>
    mutate(w = residual / n(), source = paste0("OEWS broad group ", broad, " residual, split equally")) |>
    ungroup() |>
    filter(!is.na(w), w > 0) |>
    select(soc, w, source)
  # OEWS publishes no row at all for a few codes (11-1031 Legislators, 45-3031 Fishing and
  # Hunting Workers, and the military group 55). Non-military codes get the smallest published
  # detailed employment in their SOC major group, so they still count, with little weight.
  out <- bind_rows(direct, filled)
  still <- tibble(soc = setdiff(soc_detailed, out$soc)) |> filter(!startsWith(soc, "55-"))
  floor_w <- direct |> group_by(major = substr(soc, 1, 2)) |> summarise(w = min(w), .groups = "drop")
  fallback <- still |>
    mutate(major = substr(soc, 1, 2)) |>
    inner_join(floor_w, by = "major") |>
    transmute(soc, w, source = "no OEWS row; smallest published detailed employment in its SOC major group")
  bind_rows(out, fallback)
}
