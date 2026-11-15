test_that("structure and data trees expose the checked mapping", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point()
  fig <- suppressWarnings(gloss(p, context = FALSE, dense = Inf))

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

test_that("data tree keeps built rows when panel elements differ", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() + ggplot2::geom_smooth(method = "lm", se = TRUE) +
    ggplot2::facet_wrap(~am)
  fig <- suppressWarnings(gloss(p, context = FALSE, dense = Inf))
  expect_gte(nrow(gl_table(fig, "built_layer2")), 160)
  tree <- gl_tree(fig, "structure")
  expect_gte(sum(tree$nodes$type == "panel"), 2)
  expect_true(any(tree$nodes$type == "element" & tree$nodes$role == "data"))
})
