test_that("the closed v0 checks return evidence-bearing statuses", {
  d <- data.frame(
    group = rep(c("a", "b"), each = 3),
    x = c(1, 2, 3, 1, 2, 3),
    y = c(2, 4, 6, 9, 8, 7),
    label = c("ok", "ok", "ok", "other", "other", "other"),
    stringsAsFactors = FALSE
  )
  count <- gl_check(d, "count", list(by = "group", equals = 3L))
  expect_equal(count$status, "verified")
  expect_equal(nrow(count$groups), 2L)

  value <- gl_check(d, "value", list(column = "label", value = "ok", row = 1L))
  expect_equal(value$status, "verified")
  expect_true(value$groups$passed[1])

  compare <- gl_check(d, "compare", list(left = "y", right = "x",
                                          stat = "mean", expect = "greater"))
  expect_equal(compare$status, "verified")
  range <- gl_check(d, "range", list(column = "x", min = 1, max = 3))
  expect_equal(range$status, "verified")

  exists <- gl_check(d, "exists", list(column = "label", value = "other"))
  expect_equal(exists$status, "verified")
})

test_that("closed v0 checks reject false values and refuse incomplete inputs", {
  d <- data.frame(x = 1:3, y = c(2, 4, 6), stringsAsFactors = FALSE)
  expect_equal(gl_check(d, "count", list(equals = 2L))$status, "failed")
  expect_equal(gl_check(d, "value", list(column = "x", value = 9))$status, "failed")
  expect_equal(gl_check(d, "compare", list(left = "x", right = "y",
                                             expect = "greater"))$status, "failed")
  expect_equal(gl_check(d, "range", list(column = "x", min = 2))$status, "partial")
  expect_equal(gl_check(d, "exists", list(column = "x", value = 99))$status, "failed")
  expect_equal(gl_check(d, "range", list(column = "missing", min = 1))$status, "refused")
})

test_that("semantic layer schemas reject unknown fields and retain speculative records", {
  skip_if_no("ggplot2")
  fig <- gloss(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
                 ggplot2::geom_point(), context = FALSE)
  el <- gl_bindings(fig)$element[1L]
  expect_error(gl_record(fig, "meaning", el, list(text = "x", html = "<b>bad</b>")),
               "unknown field")
  fig <- gl_record(fig, "meaning", el,
                   list(text = "possible explanation", provenance = "speculative"))
  rec <- attr(gl_records(fig, "meaning"), "records")[[1L]]
  expect_equal(rec$status, "speculative")
  expect_equal(gloss:::record_projection_status(rec), "speculative")
  expect_false(gloss:::record_is_factual(rec))
})

test_that("all built-in check plugins pass the declaration contract", {
  names <- c("trend", "count", "value", "compare", "range", "exists")
  for (nm in names) {
    result <- suppressWarnings(gl_test_plugin("check", nm))
    expect_false(any(result$passed %in% FALSE), label = nm)
  }
})
