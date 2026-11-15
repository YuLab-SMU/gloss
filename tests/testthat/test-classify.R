test_that("ggplot role rules classify the drawing-system structure", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    ggplot2::geom_hline(yintercept = 20) +
    ggplot2::annotate("text", x = 4, y = 32, label = "typed") +
    ggplot2::labs(title = "A title")
  fig <- gloss(p, context = FALSE, bind = FALSE, dense = Inf)
  roles <- gl_classify(fig)
  expect_true(all(c("data", "reference", "annotation", "guide", "decoration") %in% roles$role))
  expect_true(any(roles$kind == "point"))
  expect_true(any(roles$kind == "reference line"))
  expect_true(any(roles$kind == "text" & roles$role == "annotation"))
  expect_true(all(roles$status %in% c("classified", "residue")))
  expect_true(all(c("element", "leaf", "cue", "rule", "reason") %in% names(roles)))
})

test_that("base axis and title leaves split into element roles", {
  fig <- gloss(function() {
    plot(1:3, 3:1, main = "M", xlab = "X", ylab = "Y")
  }, context = FALSE, bind = FALSE, dense = Inf)
  roles <- gl_classify(fig)
  expect_true(any(roles$kind == "axis line"))
  expect_true(any(roles$kind == "tick"))
  expect_true(any(roles$kind == "tick label"))
  expect_true(any(roles$kind == "title" & roles$role == "annotation"))
  expect_true(any(roles$kind == "axis title" & roles$role == "guide"))
  expect_true(all(gl_unclassified(fig)$status == "residue"))
})

test_that("role derived tables survive a bundle round trip", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  fig <- gloss(p, context = FALSE, bind = FALSE, dense = Inf)
  path <- tempfile(fileext = ".gloss")
  gl_write(fig, path)
  back <- gl_read(path)
  expect_equal(gl_classify(back), gl_classify(fig))
  expect_equal(gl_role_checks(back), gl_role_checks(fig))
})
