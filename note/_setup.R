# Shared setup for the note, appendix and methods memo. Every number in the prose comes from
# data/out/note_facts.csv (written by R/13_facts.R) through these helpers.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(knitr)
})
# Documents live one level below the project root (note/ and docs/), and Quarto runs each
# document from its own folder.
source("../R/utils.R")

facts_tbl <- read_csv(out_path("note_facts.csv"), show_col_types = FALSE)
F <- setNames(facts_tbl$value, facts_tbl$key)
fact <- function(k) {
  if (!k %in% names(F)) stop("Unknown fact: ", k)
  F[[k]]
}

# Fixed decimals, with a typographic minus sign for negative values.
fmt <- function(x, ...) sub("^-", "−", formatC(x, format = "f", ...))
# Whole numbers or fixed decimals, with thousands separators.
num <- function(k, d = 0) fmt(fact(k), digits = d, big.mark = ",")
# Shares as percentages.
pc <- function(k, d = 1) paste0(fmt(100 * fact(k), digits = d), "%")
# A value already on the percentage-point scale.
pp <- function(k, d = 1) paste0(fmt(fact(k), digits = d, flag = "+"), " pp")
# Signed value, and values on the x100 scale.
sg <- function(k, d = 1) fmt(fact(k), digits = d, flag = "+")
h <- function(k, d = 1) fmt(100 * fact(k), digits = d)
sh <- function(k, d = 1) fmt(100 * fact(k), digits = d, flag = "+")
# Absolute value, for sentences that already say "lower" or "below".
ab <- function(k, d = 1) fmt(abs(fact(k)), digits = d)
# A plain number not stored as a fact (counts in code, e.g. number of schemes).
n <- function(x, d = 0) fmt(x, digits = d, big.mark = ",")

m3 <- function(f) read_codes_csv(out_path("m3", f))
fig <- function(f) file.path(project_root(), "note", "figures", f)
