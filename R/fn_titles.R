# Title matching for scheme 3 (title-match-first). A unit's linked SOCs are kept only
# if one of them matches the unit title or one of its occupation titles; otherwise the
# unit falls back to scheme 1. Matching is deliberately strict, and every match is logged
# for review.

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
})

stop_words <- c("and", "or", "the", "of", "other", "all", "nec", "nfd", "workers", "worker",
                "occupations", "except", "including", "specialists", "specialist")

title_tokens <- function(x) {
  x |>
    str_to_lower() |>
    str_replace_all("[^a-z ]", " ") |>
    str_squish() |>
    str_split(" ") |>
    lapply(function(t) {
      t <- t[!t %in% stop_words & nchar(t) > 1]
      t <- str_replace(t, "ies$", "y")
      t <- str_replace(t, "(?<=[^s])s$", "")
      sort(unique(t))
    })
}

jaccard <- function(a, b) if (length(a) == 0 || length(b) == 0) 0 else length(intersect(a, b)) / length(union(a, b))

# links: unit, soc. anz_titles: unit, anz_title (unit and occupation titles). soc_titles: soc, soc_title.
# A link matches if the token sets are equal, or their Jaccard similarity is at least `min_jaccard`.
title_matches <- function(links, anz_titles, soc_titles, min_jaccard = 0.75) {
  cand <- links |>
    distinct(unit, soc) |>
    inner_join(anz_titles, by = "unit", relationship = "many-to-many") |>
    inner_join(soc_titles, by = "soc")
  ta <- title_tokens(cand$anz_title)
  ts <- title_tokens(cand$soc_title)
  cand$jaccard <- mapply(jaccard, ta, ts)
  cand |>
    filter(jaccard >= min_jaccard) |>
    group_by(unit, soc) |>
    slice_max(jaccard, n = 1, with_ties = FALSE) |>
    ungroup()
}
