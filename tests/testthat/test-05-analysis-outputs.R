# Checks on the real M3 outputs.

have_m3 <- file.exists(out_path("m3", "decile_profiles.csv"))

test_that("each decile holds 10% of employment, within 0.5 pp, in every specification", {
  skip_if_not(have_m3, "M3 not run yet")
  dc <- read_codes_csv(interim_path("decile_share_check.csv"))
  sens <- read_codes_csv(out_path("m3", "sensitivity_table.csv"))
  expect_equal(nrow(dc), nrow(sens) * 10)
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

test_that("no published file carries a unit-level AIOE or teleworkability value", {
  skip_if_not(have_m3, "M3 not run yet")
  files <- list.files(out_path(), pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
  for (f in files) {
    h <- names(readr::read_csv(f, n_max = 0, show_col_types = FALSE))
    if ("unit" %in% h) expect_false(any(grepl("aioe|telework|workathome", h, ignore.case = TRUE)), info = f)
  }
})

test_that("the women-men split adds up to the overall gap", {
  skip_if_not(have_m3, "M3 not run yet")
  sd <- read_codes_csv(out_path("m3", "sex_decomposition.csv"))
  so <- read_codes_csv(out_path("m3", "sex_overall.csv"))
  expect_equal(sd$within + sd$between, sd$total)
  expect_equal(sd$total, so$women - so$men, tolerance = 1e-9)
})

test_that("WA group contributions sum to the WA gap, raw and normalised", {
  skip_if_not(have_m3, "M3 not run yet")
  wd <- read_codes_csv(out_path("m3", "wa_decomposition.csv"))
  wa <- read_codes_csv(out_path("m3", "wa_vs_national.csv"))
  for (m in wa$measure) for (lv in c("major", "submajor")) {
    x <- wd[wd$measure == m & wd$level == lv, ]
    expect_equal(sum(x$contribution), wa$wa_gap[wa$measure == m], tolerance = 1e-9)
    expect_equal(sum(x$contribution_norm), wa$wa_gap[wa$measure == m], tolerance = 1e-9)
  }
})

test_that("comparable concentration indices exist for every measure", {
  skip_if_not(have_m3, "M3 not run yet")
  ci <- read_codes_csv(out_path("m3", "concentration_indices.csv"))
  expect_false(anyNA(ci$rank_ci))
  expect_true(all(is.na(ci$ci[ci$measure == "aioe"])))
  expect_true(all(abs(ci$rank_ci) <= 1 / 3 + 1e-9))
})

test_that("uncertainty draws reproduce the main specification and cover every type", {
  skip_if_not(file.exists(out_path("m3", "uncertainty_survival.csv")), "E3 not run yet")
  s <- read_codes_csv(out_path("m3", "uncertainty_survival.csv"))
  expect_setequal(s$type, c("crosswalk", "crosswalk_wide", "earnings", "both"))
  expect_true(all(s$draws == 500))
  b <- read_codes_csv(out_path("m3", "bounds_unscored.csv"))
  dl <- b$usage[b$bound == "lower"]; dm <- b$usage[b$bound == "main"]; du <- b$usage[b$bound == "upper"]
  expect_true(all(dl <= dm + 1e-12) && all(du >= dm - 1e-12))
  ci <- read_codes_csv(out_path("m3", "concentration_indices.csv"))
  main <- read_codes_csv(out_path("m3", "bounds_unscored.csv")) |> dplyr::filter(bound == "main") |> dplyr::slice(1)
  expect_equal(main$ci, ci$ci[ci$measure == "usage"], tolerance = 1e-9)
})

test_that("the Gelbach split adds up to the change in the earnings slope", {
  skip_if_not(file.exists(out_path("m3", "conditional_gelbach.csv")), "E4 not run yet")
  g <- read_codes_csv(out_path("m3", "conditional_gelbach.csv"))
  expect_equal(g$base - g$full, g$via_potential + g$via_telework, tolerance = 1e-9)
})

test_that("the other-platform comparison covers every specification", {
  skip_if_not(file.exists(out_path("m3", "other_platform_sensitivity.csv")), "E1 not run yet")
  s <- read_codes_csv(out_path("m3", "other_platform_sensitivity.csv"))
  expect_equal(nrow(s), 60)
  expect_true(all(abs(c(s$rank_ci_usage, s$rank_ci_copilot, s$rank_ci_composite)) <= 1 / 3 + 1e-9))
})
