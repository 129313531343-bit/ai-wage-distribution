# Crosswalk outputs: weights, coverage and keys. These run once the BLS files are in place
# and 08_crosswalks.R and 09_unit_measures.R have been run.

have_chain <- file.exists(interim_path("unit_measures_long.csv"))

test_that("weights sum to one within every unit under every scheme", {
  skip_if_not(have_chain, "crosswalk not built yet (BLS files needed)")
  w <- read_codes_csv(interim_path("unit_soc_weights_all_schemes.csv"))
  s <- w |> dplyr::group_by(scheme, unit) |> dplyr::summarise(total = sum(w_norm), .groups = "drop")
  expect_true(all(abs(s$total - 1) < 1e-9))
  expect_false(anyDuplicated(w[c("scheme", "unit", "soc")]) > 0)
})

test_that("coverage follows the definition in C4 and meets the 98% target", {
  skip_if_not(have_chain, "crosswalk not built yet (BLS files needed)")
  cov <- read_codes_csv(out_path("coverage.csv"))
  emp <- read_codes_csv(interim_path("emp_units.csv"))
  g <- read_codes_csv(interim_path("unit_grades.csv"))
  expect_equal(cov$emp_covered, sum(emp$emp[emp$unit %in% g$unit[g$n_valid > 0]]))
  expect_equal(cov$emp_total, sum(emp$emp))
  expect_gte(cov$coverage_share, 0.98)
})

test_that("unit measures have no duplicate keys", {
  skip_if_not(have_chain, "crosswalk not built yet (BLS files needed)")
  m <- read_codes_csv(interim_path("unit_measures_long.csv"))
  expect_false(anyDuplicated(m[c("scheme", "measure", "unit")]) > 0)
})
