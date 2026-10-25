# The job_exposure.csv profile must match the counts recorded in the project brief.
# If Anthropic updates the file, these tests fail before anything downstream runs.

test_that("job_exposure.csv has the expected profile", {
  je <- readr::read_csv(raw_path("aei/job_exposure.csv"), show_col_types = FALSE)
  expect_equal(nrow(je), 756)
  expect_false(anyDuplicated(je$occ_code) > 0)
  expect_true(all(grepl("^\\d{2}-\\d{4}$", je$occ_code)))
  expect_equal(sum(je$observed_exposure == 0), 411)
  expect_equal(round(max(je$observed_exposure), 3), 0.745)
  expect_equal(round(mean(je$observed_exposure), 3), 0.077)
  expect_equal(median(je$observed_exposure), 0)
})

test_that("111 SOC 2018 detailed codes have no job_exposure row", {
  soc2018 <- soc2018_detailed_codes()
  je <- readr::read_csv(raw_path("aei/job_exposure.csv"), show_col_types = FALSE)
  expect_equal(length(soc2018), 867)
  expect_true(all(je$occ_code %in% soc2018))
  expect_equal(length(setdiff(soc2018, je$occ_code)), 111)
})
