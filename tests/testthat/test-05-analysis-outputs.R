# Checks on the real M3 outputs.

have_m3 <- file.exists(out_path("m3", "decile_profiles.csv"))

test_that("each decile holds 10% of employment, within 0.5 pp, in every specification", {
  skip_if_not(have_m3, "M3 not run yet")
  dc <- read_codes_csv(interim_path("decile_share_check.csv"))
  expect_equal(nrow(dc), 48 * 10)
  expect_true(all(abs(dc$share - 0.1) <= 0.005))
})

test_that("decile profiles and gaps have one row per key", {
  skip_if_not(have_m3, "M3 not run yet")
  d <- read_codes_csv(out_path("m3", "decile_profiles.csv"))
  expect_false(anyDuplicated(d[c("scheme", "sample", "ranking", "decile")]) > 0)
  g <- read_codes_csv(out_path("m3", "gap_by_decile.csv"))
  expect_false(anyDuplicated(g[c("scheme", "sample", "ranking", "potential", "decile")]) > 0)
})

test_that("decile intensity equals mean exposure over mean extensive margin", {
  skip_if_not(have_m3, "M3 not run yet")
  d <- read_codes_csv(out_path("m3", "decile_profiles.csv"))
  expect_equal(d$intensity, d$usage / d$extensive, tolerance = 1e-12)
})

test_that("no published file carries a unit-level AIOE value", {
  skip_if_not(have_m3, "M3 not run yet")
  files <- list.files(out_path(), pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
  for (f in files) {
    h <- names(readr::read_csv(f, n_max = 0, show_col_types = FALSE))
    if ("unit" %in% h) expect_false(any(grepl("aioe", h, ignore.case = TRUE)), info = f)
  }
})
