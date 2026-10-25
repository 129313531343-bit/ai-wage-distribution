# Checks of the analysis helpers on small synthetic data, so that each function is known
# to be right before it touches the real data.

test_that("weighted ranks give tied values the same mid-rank", {
  r <- weighted_rank(c(1, 2, 2, 3), c(1, 1, 1, 1))
  expect_equal(r, c(0.125, 0.5, 0.5, 0.875))
  expect_equal(weighted_rank(c(5, 1), c(3, 1)), c(0.625, 0.125))
})

test_that("fractional deciles give each decile exactly a tenth of employment", {
  set.seed(1)
  df <- tibble::tibble(unit = sprintf("%04d", 1:57), earn = runif(57), emp = rexp(57) * 100)
  d <- fractional_deciles(df, "earn")
  shares <- d |> dplyr::group_by(decile) |> dplyr::summarise(s = sum(emp_share_in_decile))
  expect_equal(nrow(shares), 10)
  expect_true(all(abs(shares$s - 0.1) <= 0.005))
  expect_equal(sum(d$emp_share_in_decile), 1)
  units <- d |> dplyr::group_by(unit) |> dplyr::summarise(f = sum(frac_of_unit))
  expect_true(all(abs(units$f - 1) < 1e-9))
})

test_that("a unit larger than a decile spans several deciles", {
  df <- tibble::tibble(unit = c("a", "b"), earn = c(1, 2), emp = c(25, 75))
  d <- fractional_deciles(df, "earn")
  expect_equal(sort(unique(d$decile[d$unit == "a"])), 1:3)
  expect_equal(sum(d$emp_share_in_decile[d$unit == "a"]), 0.25)
})

test_that("the concentration index has the right sign and is zero for flat exposure", {
  r <- weighted_rank(1:10, rep(1, 10))
  expect_gt(concentration_index(1:10, r, rep(1, 10)), 0)
  expect_lt(concentration_index(10:1, r, rep(1, 10)), 0)
  expect_equal(concentration_index(rep(2, 10), r, rep(1, 10)), 0)
})

test_that("the gap is zero when usage and potential rank units the same way", {
  df <- tibble::tibble(unit = letters[1:5], u = c(.1, .2, .3, .4, .5), p = c(1, 2, 3, 4, 5), emp = c(1, 2, 3, 2, 1))
  g <- unit_gap(df, "u", "p")
  expect_equal(g$gap_rank, rep(0, 5))
  expect_equal(g$gap_z, rep(0, 5))
})

test_that("profile_holds applies the slope-sign and Spearman rule", {
  expect_true(profile_holds(1:10 + rnorm(10, 0, .01), 1:10)$holds)
  expect_false(profile_holds(10:1, 1:10)$holds)
})

test_that("unit scores renormalise weights over SOCs with a value", {
  links <- tibble::tibble(unit = c("u1", "u1", "u1", "u2"), soc = c("a", "b", "c", "a"))
  vals <- tibble::tibble(soc = c("a", "b", "c"), v = c(0, 0.4, NA))
  w <- tibble::tibble(soc = c("a", "b", "c"), w = c(1, 3, 10))
  s <- unit_scores(links, vals, "v", w)
  expect_equal(s$score[s$unit == "u1"], 0.3)
  expect_equal(s$extensive[s$unit == "u1"], 0.75)
  expect_equal(s$intensity[s$unit == "u1"], 0.4)
  expect_equal(s$grade, c("few-to-one", "one-to-one"))
  uw <- unit_weights(links, vals, "v", w)
  expect_true(all(abs(tapply(uw$w_norm, uw$unit, sum) - 1) < 1e-12))
})
