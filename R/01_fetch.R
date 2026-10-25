# Download missing raw inputs and write data/raw/MANIFEST.csv.
# Raw files are never edited or replaced. If a file on disk no longer matches the
# sha256 in the existing manifest, this script stops instead of overwriting anything.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})
source("R/00_sources.R")

raw_dir <- "data/raw"
manifest_path <- file.path(raw_dir, "MANIFEST.csv")
options(timeout = 3600)
# jobsandskills.gov.au stalls on user-agents containing "libcurl", so keep this plain.
ua <- "ai-wage-distribution research pipeline"

old <- if (file.exists(manifest_path)) {
  read_csv(manifest_path, col_types = cols(.default = col_character()))
} else {
  tibble(file = character(), access_date = character(), sha256 = character())
}

sha256 <- function(path) digest::digest(file = path, algo = "sha256")

for (i in seq_len(nrow(sources))) {
  s <- sources[i, ]
  dest <- file.path(raw_dir, s$dest)
  if (file.exists(dest) || s$method != "script") next
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  message("Downloading ", s$id)
  tmp <- paste0(dest, ".part")
  # HTTP/1.1, because jobsandskills.gov.au returns HTTP/2 framing errors to libcurl.
  h <- curl::new_handle(useragent = ua, http_version = 2L, followlocation = TRUE)
  curl::curl_download(s$url, tmp, handle = h, quiet = TRUE)
  file.rename(tmp, dest)
}

rows <- lapply(seq_len(nrow(sources)), function(i) {
  s <- sources[i, ]
  dest <- file.path(raw_dir, s$dest)
  present <- file.exists(dest)
  hash <- if (present) sha256(dest) else NA_character_
  prev <- old[old$file == s$dest, ]
  if (present && nrow(prev) == 1 && !is.na(prev$sha256) && prev$sha256 != hash) {
    stop("sha256 changed for ", s$dest, ". Raw files must not change; investigate before continuing.")
  }
  access <- if (nrow(prev) == 1 && !is.na(prev$access_date)) prev$access_date
            else if (present) format(file.mtime(dest), "%Y-%m-%d") else NA_character_
  tibble(
    file = s$dest, id = s$id, source_url = s$url, method = s$method,
    access_date = access, sha256 = hash,
    bytes = if (present) as.character(file.size(dest)) else NA_character_,
    version_or_commit = s$version, licence = s$licence, licence_url = s$licence_url,
    licence_checked = s$licence_checked, notes = s$notes
  )
})
manifest <- bind_rows(rows)
write_csv(manifest, manifest_path, na = "")

missing <- manifest$file[is.na(manifest$sha256)]
if (length(missing) > 0) {
  message("Missing (download by hand into data/raw/): ", paste(missing, collapse = ", "))
}
message("Manifest: ", sum(!is.na(manifest$sha256)), " of ", nrow(manifest), " files present.")
