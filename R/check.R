# `make check`: checks that must pass before anything is published.
#   1. Raw files still match the sha256 recorded in data/raw/MANIFEST.csv.
#   2. Prose files (the note, the summary and the methods memo; decision D5) contain no bare
#      digits outside inline R. Years, figure/table/section/chart/appendix numbers and text in
#      backticks are allowed.
#   3. The same prose files avoid causal wording unless the line is listed, with a reason, in
#      docs/causal_allowlist.txt.
#   4. No published file has a per-unit AIOE column.
# Exits with status 1 if any check fails.

suppressPackageStartupMessages({
  library(readr)
  library(stringr)
})
source("R/utils.R")

failures <- character()
fail <- function(...) failures <<- c(failures, paste0(...))

# 1. Manifest --------------------------------------------------------------------
manifest <- read_csv(raw_path("MANIFEST.csv"), col_types = cols(.default = "c"))
for (i in seq_len(nrow(manifest))) {
  f <- raw_path(manifest$file[i])
  if (is.na(manifest$sha256[i])) next
  if (!file.exists(f)) fail("Missing raw file: ", manifest$file[i])
  else if (digest::digest(file = f, algo = "sha256") != manifest$sha256[i]) fail("sha256 mismatch: ", manifest$file[i])
}

# 2 and 3. Prose ------------------------------------------------------------------
prose_files <- c(
  Sys.glob("note/*.qmd"),
  Sys.glob("docs/summary*.md"), Sys.glob("docs/summary*.qmd"),
  Sys.glob("docs/methods_memo*.md"), Sys.glob("docs/methods_memo*.qmd")
)
causal <- c("caused", "causes", "led to", "leads to", "impact of", "effect of AI", "displaced",
            "replaced", "driven by", "because of AI")
allow <- if (file.exists("docs/causal_allowlist.txt")) {
  a <- readLines("docs/causal_allowlist.txt", warn = FALSE)
  a <- a[nzchar(a) & !startsWith(a, "#")]
  if (any(!str_detect(a, " \\| \\S"))) fail("docs/causal_allowlist.txt: every entry needs ' | reason'")
  str_trim(str_remove(a, " \\| .*$"))
} else character()

strip_code <- function(lines) {
  in_chunk <- FALSE; in_yaml <- FALSE; in_math <- FALSE
  out <- character(length(lines))
  for (i in seq_along(lines)) {
    l <- lines[i]
    if (i == 1 && l == "---") { in_yaml <- TRUE; next }
    if (in_yaml) { if (l == "---") in_yaml <- FALSE; next }
    if (str_detect(l, "^```")) { in_chunk <- !in_chunk; next }
    if (str_detect(l, "^\\s*\\$\\$")) { in_math <- !in_math; next }   # display maths
    if (in_math) next
    if (in_chunk) next
    l <- str_remove_all(l, "`r [^`]*`")          # inline R
    l <- str_remove_all(l, "`[^`]*`")            # code spans
    l <- str_remove_all(l, "\\{#[^}]*\\}")       # cross-reference labels
    l <- str_remove_all(l, "@(fig|tbl|sec)-[A-Za-z0-9-]+")
    l <- str_remove_all(l, "\\[[^\\]]*@[^\\]]*\\]")          # bracketed citations, with page locators
    l <- str_remove_all(l, "-?@[A-Za-z][A-Za-z0-9_:-]*")   # citation keys
    l <- str_remove_all(l, "\\be61\\b")                      # organisation name (e61 Institute)
    l <- str_remove_all(l, "\\(A[0-9]\\)")                    # assumption labels (A1)-(A4)
    l <- str_remove_all(l, "\\{[^}]*\\}")                   # Quarto attributes: {.callout-note}, {width="80%"}
    l <- str_remove_all(l, "^:::.*$")                      # fenced div markers
    l <- str_remove_all(l, "\\$[^$]+\\$")                  # inline maths
    l <- str_remove(l, "^\\s*[0-9]+\\.\\s")                # numbered-list markers
    l <- str_remove_all(l, "<!--.*?-->")
    l <- str_remove_all(l, "\\]\\([^)]*\\)")     # link targets
    out[i] <- l
  }
  out
}

for (f in prose_files) {
  raw_lines <- readLines(f, warn = FALSE)
  text <- strip_code(raw_lines)
  for (i in seq_along(text)) {
    l <- text[i]
    if (!nzchar(l)) next
    l2 <- str_remove_all(l, "\\b(1[89]\\d\\d|20\\d\\d)\\b")
    l2 <- str_remove_all(l2, "(?i)\\b(figure|fig\\.|table|section|chart|appendix|walk-through|scheme|proposition|lemma|m)\\s*[0-9]+[a-z]?\\b")
    if (str_detect(l2, "[0-9]")) fail(f, ":", i, ": bare digits in prose: ", str_trunc(str_squish(raw_lines[i]), 90))
    hits <- causal[str_detect(str_to_lower(l), fixed(str_to_lower(causal)))]
    if (length(hits) > 0 && !str_trim(raw_lines[i]) %in% allow) {
      fail(f, ":", i, ": causal wording (", paste(hits, collapse = ", "), "): ", str_trunc(str_squish(raw_lines[i]), 90))
    }
  }
}

# 4. No per-unit AIOE values in published files -------------------------------------
published <- c(list.files("data/out", pattern = "\\.(csv|json)$", recursive = TRUE, full.names = TRUE),
               list.files("explorer", pattern = "\\.(csv|json)$", recursive = TRUE, full.names = TRUE))
# AIOE may appear in aggregate tables (decile means, correlations); it must never sit beside a
# unit (occupation) identifier. CSVs are checked by header; JSON by its unit-level keys.
unit_keys <- c("unit", "anzsco", "code", "soc", "occupation")
for (f in published) {
  if (str_detect(f, "\\.csv$")) {
    h <- str_to_lower(names(read_csv(f, n_max = 0, show_col_types = FALSE)))
    if (any(h %in% unit_keys) && any(str_detect(h, "aioe"))) fail(f, ": unit-level AIOE column (AIOE is aggregate-only)")
  } else {
    j <- jsonlite::fromJSON(f, simplifyVector = TRUE)
    if (is.data.frame(j) && any(str_to_lower(names(j)) %in% unit_keys) && any(str_detect(str_to_lower(names(j)), "aioe"))) {
      fail(f, ": unit-level AIOE field (AIOE is aggregate-only)")
    }
  }
}

if (length(failures) > 0) {
  cat("make check FAILED\n", paste0(" - ", failures, collapse = "\n"), "\n")
  quit(status = 1)
}
cat("make check passed: ", nrow(manifest), " manifest rows, ", length(prose_files), " prose files, ",
    length(published), " published files.\n", sep = "")
