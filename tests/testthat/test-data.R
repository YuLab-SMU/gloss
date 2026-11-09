test_that("the five key rules apply in order", {
  k <- gl_infer_key(mtcars)
  expect_equal(c(k$rule, k$key), c("1", ".rownames"))
  expect_match(k$basis, "Mazda RX4")

  df <- data.frame(id = 1:4, name = c("a", "b", "c", "d"), v = c(1, 1, 2, 2))
  k <- gl_infer_key(df, hints = c(label = "id"))
  expect_equal(k$rule, 2L)
  expect_equal(k$key, "id")
  expect_match(k$basis, "label")

  k <- gl_infer_key(df)
  expect_equal(k$rule, 3L)
  expect_equal(k$key, "name")

  df2 <- data.frame(g = c("a", "a", "b", "b"), t = c(1L, 2L, 1L, 2L), v = c(5, 5, 5, 5))
  k <- gl_infer_key(df2)
  expect_equal(k$rule, 4L)
  expect_equal(k$key, c("g", "t"))

  df3 <- data.frame(g = c("a", "a", "b"), v = c(1, 1, 2))
  k <- gl_infer_key(df3)
  expect_equal(k$rule, 5L)
  expect_true(k$fragile)
})

test_that("a hint that is not unique is skipped", {
  df <- data.frame(grp = c("a", "a", "b"), name = c("x", "y", "z"))
  k <- gl_infer_key(df, hints = c(group = "grp"))
  expect_equal(c(k$rule, k$key), c("3", "name"))
})

test_that("hash keys are stable and distinguish duplicate rows", {
  df <- data.frame(g = c("a", "a", "b"), v = c(1, 1, 2))
  tbl <- new_table(list(name = "t", data = df))
  kv <- key_values(tbl)
  expect_length(unique(kv), 3L)
  expect_identical(kv, key_values(tbl))
  expect_match(kv[2], ":2$")
})

test_that("ggplot tables get row keys from row names and label mappings", {
  skip_if_no("ggplot2")
  fig <- suppressWarnings(gloss(p_facet(), width = 7, height = 4, context = FALSE))
  tabs <- gl_tables(fig)
  expect_equal(tabs$key[tabs$name == "raw"], ".rownames")
  expect_true(all(c("built_layer1", "built_layer2") %in% tabs$name))
  expect_setequal(fig$tables$raw$referenced, c("wt", "mpg", "cyl", "am"))
  expect_equal(gl_key_values(fig, "raw")[1], "Mazda RX4")
})

test_that("gl_key changes the key, checks it and keeps a history", {
  skip_if_no("ggplot2")
  df <- data.frame(name = c("a", "b", "c"), x = 1:3, y = c(2, 4, 6), grp = c("u", "u", "v"))
  fig <- gloss(ggplot2::ggplot(df, ggplot2::aes(x, y)) + ggplot2::geom_point(), width = 3, height = 3,
               context = FALSE)
  expect_equal(fig$tables$raw$key, "name")
  fig2 <- gl_key(fig, "raw", c("grp", "x"), by = "tester")
  expect_equal(fig2$tables$raw$key, c("grp", "x"))
  expect_equal(fig2$tables$raw$key_rule, 0L)
  expect_equal(nrow(fig2$tables$raw$key_history), 1L)
  expect_equal(fig2$tables$raw$key_history$from, "name")
  expect_equal(fig2$tables$raw$key_history$by, "tester")
  expect_equal(gl_key_values(fig2, "raw"), paste("u", 1:3, sep = "\u001f")[c(1, 2, 3)] |>
                 replace(3, paste("v", 3, sep = "\u001f")))
  expect_error(gl_key(fig, "raw", "grp"), "uniquely")
  expect_error(gl_key(fig, "raw", "nope"), "Not in table")
  expect_error(gl_key(fig, "nope", "x"), "No table")
  expect_identical(fig$tables$raw$key, "name")
})
