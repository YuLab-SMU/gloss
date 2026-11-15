test_that("structure and data trees expose the checked mapping", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  fig <- gloss(p, context = FALSE, dense = Inf)

  structure <- gl_tree(fig, "structure")
  expect_s3_class(structure, "gloss_tree")
  expect_true(all(c("figure", "panel", "leaf", "element") %in% structure$nodes$type))
  expect_true(nrow(structure$edges) >= nrow(structure$nodes) - 1L)

  data <- gl_tree(fig, "data")
  expect_true(all(c("table", "series", "row") %in% data$nodes$type))
  mapped <- gl_map(fig, by = "element")
  expect_true(all(c("element", "leaf", "role", "table", "row", "status", "structure") %in% names(mapped)))
  expect_true(any(mapped$status %in% c("verified", "ambiguous")))
})
