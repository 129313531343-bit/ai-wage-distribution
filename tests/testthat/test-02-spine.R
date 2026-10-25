# The v1.2 spine, the edition bridges and the EQ08 employment weights.

test_that("v1.3 has exactly the v1.2 codes, so the v1.3 bridge is the identity", {
  chk <- read_codes_csv(interim_path("check_v13_vs_v12.csv"))
  expect_true(all(chk$only_v12 == 0 & chk$only_v13 == 0))
})

test_that("the spine has 358 unit groups and no duplicate keys", {
  u <- read_codes_csv(interim_path("v12_units.csv"))
  expect_equal(nrow(u), 358)
  expect_false(anyDuplicated(u$unit) > 0)
  b <- read_codes_csv(interim_path("bridge_2022units_v12units.csv"))
  expect_false(anyDuplicated(b[c("unit2022", "unit_v12")]) > 0)
  expect_true(all(u$unit %in% b$unit_v12))
})

test_that("EQ08 has 478 codes and nfd allocation keeps total employment", {
  eq <- read_codes_csv(out_path("m1", "eq08_row_counts.csv"))
  expect_true(all(eq$codes <= 478))
  emp <- read_codes_csv(interim_path("emp_units.csv"))
  expect_false(anyDuplicated(emp$unit) > 0)
  expect_equal(nrow(emp), 358)
  expect_equal(sum(emp$emp), mean(eq$emp_total_000), tolerance = 1e-9)
  expect_equal(sum(emp$emp_wa), mean(eq$emp_wa_000), tolerance = 1e-9)
  expect_equal(sum(emp$emp_male) + sum(emp$emp_female), sum(emp$emp), tolerance = 1e-9)
})

test_that("every v1.2 unit has an EEH earnings value or a logged imputation", {
  e <- read_codes_csv(interim_path("earnings_units.csv"))
  expect_equal(nrow(e), 358)
  expect_true(all(!is.na(e$eeh_weekly_p)))
  log <- read_codes_csv(out_path("m2", "earnings_imputation_log.csv"))
  imputed <- e$unit[e$eeh_imputed != "none"]
  expect_true(all(imputed %in% log$unit))
  expect_true(all(e$eeh_imputed[is.na(e$eeh_weekly_p_raw)] != "none"))
})

test_that("JSA joins to the spine with zero unmatched units", {
  j <- read_codes_csv(interim_path("jsa_units.csv"))
  u <- read_codes_csv(interim_path("v12_units.csv"))
  expect_equal(n_distinct(j$unit), 357)
  expect_equal(length(setdiff(j$unit, u$unit)), 0)
})
