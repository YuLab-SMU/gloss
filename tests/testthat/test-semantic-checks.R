test_that("trend check reports verified group evidence", {
  d <- data.frame(
    group = rep(c("a", "b"), each = 3),
    x = c(1, 2, 3, 1, 2, 3),
    y = c(5, 4, 2, 9, 8, 6)
  )
  out <- gl_check(d, "trend", list(response = "y", predictor = "x",
                                    by = "group", expect = "negative"))
  expect_s3_class(out, "gloss_check")
  expect_equal(out$status, "verified")
  expect_true(isTRUE(out$passed))
  expect_equal(nrow(out$groups), 2L)
  expect_true(all(out$groups$passed))
  expect_true(all(is.finite(out$groups$estimate)))
  expect_equal(out$plugin$name, "trend")
})

test_that("trend check distinguishes failed and partial claims", {
  d <- data.frame(
    group = rep(c("negative", "positive"), each = 3),
    x = c(1, 2, 3, 1, 2, 3),
    y = c(5, 4, 2, 2, 4, 7)
  )
  partial <- gl_check(d, "trend", list(response = "y", predictor = "x",
                                        by = "group", expect = "negative"))
  expect_equal(partial$status, "partial")
  expect_false(partial$passed)
  expect_equal(sum(partial$groups$passed, na.rm = TRUE), 1L)
  expect_match(partial$reason, "passed and some groups failed")

  failed <- gl_check(d[d$group == "positive", , drop = FALSE], "trend",
                     list(response = "y", predictor = "x", by = "group",
                          expect = "negative"))
  expect_equal(failed$status, "failed")
  expect_false(failed$passed)
  expect_false(failed$groups$passed[1])
})

test_that("trend check refuses missing or unrunnable evidence", {
  d <- data.frame(x = 1:3, y = c(2, 1, 0))
  missing <- gl_check(d, "trend", list(response = "z", predictor = "x",
                                       expect = "negative"))
  expect_equal(missing$status, "refused")
  expect_true(is.na(missing$passed))
  expect_match(missing$reason, "missing column")

  constant <- gl_check(data.frame(g = c("a", "a"), x = 1, y = c(2, 3)),
                       "trend", list(response = "y", predictor = "x",
                                       by = "g", expect = "positive"))
  expect_equal(constant$status, "refused")
  expect_true(is.na(constant$passed))
  expect_match(constant$reason, "no group")
  expect_match(constant$groups$reason, "no variation")
})

test_that("semantic check arguments and plugin names are validated", {
  d <- data.frame(x = 1:3, y = 3:1)
  expect_error(gl_check(d, "does_not_exist", list()), "No check plugin")
  expect_error(gl_check(d, "trend", list(response = "y", predictor = "x",
                                           expect = "sideways")), "not one of")
  expect_error(gl_check(d, "trend", list(response = "y", predictor = "x",
                                           expect = "negative", extra = TRUE)),
               "unknown field")
  expect_error(gl_check(d, "trend", list(response = "y", predictor = "x",
                                           by = 1, expect = "negative")),
               "single string")
})

test_that("the built-in trend check passes its plugin contract", {
  res <- gl_test_plugin("check", "trend")
  expect_false(any(res$passed %in% FALSE))
})
