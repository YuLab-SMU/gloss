# Rows placed on the page from the figure alone: the table's position
# columns through the panel's scales, with no engine state (plan
# 2026-11-12-agent-path, Task 2). recheck_alone() checks the engine's own
# claims a second time with their rows placed that way.

alone_of <- function(x, ...) suppressWarnings(alone_capture(x, ...))

test_that("on a cartesian scatter the figure alone places rows where the engine does", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  fig <- gloss(p, width = 7, height = 5, context = FALSE)
  b <- gl_bindings(fig)
  placed <- place_rows(fig, "built_layer1", b$row, gl_elements(fig, list(id = b$element[1]))$panel)
  expect_named(placed, c("row", "x", "y"))
  el <- gl_elements(fig)[match(b$element, gl_elements(fig)$id), ]
  expect_lt(max(abs(placed$x - (el$x0 + el$x1) / 2)), 0.01)
  expect_lt(max(abs(placed$y - (el$y0 + el$y1) / 2)), 0.01)
  a <- alone_of(p, width = 7, height = 5)
  lv <- a$leaves
  expect_equal(nrow(lv), 1L)
  expect_equal(lv$engine_status, "verified")
  expect_equal(lv$alone_status, "verified")
  expect_equal(lv$same, 32L)
  expect_lt(lv$gap, 0.01)
  expect_true(is.na(lv$alone_reason))
  expect_identical(a$elements$engine, a$elements$alone)
})

test_that("a facetted figure with points, a ribbon, lines and text agrees leaf by leaf", {
  skip_if_no("ggplot2")
  a <- alone_of(p_facet(), width = 7, height = 4)
  lv <- a$leaves
  expect_true(nrow(lv) >= 6L)
  expect_identical(lv$alone_status, lv$engine_status)
  expect_true(all(lv$gap < 0.01))
  expect_equal(sum(lv$same), sum(lv$n_elements))
})

test_that("rows shifted by one within a leaf fail, from the figure alone as from the engine", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  lv <- alone_of(p, width = 7, height = 5)$leaves
  expect_equal(lv$moved, 32L)
  expect_equal(lv$moved_pass_engine, 0L)
  expect_equal(lv$moved_pass_alone, 0L)
})

test_that("a panel whose scales are not ranges on the page gives a reason, not a position", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() + ggplot2::coord_polar()
  fig <- gloss(p, width = 5, height = 5, context = FALSE)
  panel <- fig$substrate$panels$id[1]
  expect_match(place_rows(fig, "built_layer1", 1:3, panel), "scales")
  lv <- alone_of(p, width = 5, height = 5)$leaves
  # the engine's own transform places every row (some tie under the polar coord)
  expect_equal(lv$engine_failed, 0L)
  expect_equal(lv$engine_verified + lv$engine_ambiguous, 32L)
  expect_equal(lv$alone_status, "unbound")
  expect_match(lv$alone_reason, "scales")
  expect_equal(lv$same, 0L)
  # a table that is not there, a panel that is not there
  expect_match(place_rows(fig, "no_such_table", 1:3, panel), "table")
  expect_match(place_rows(fig, "built_layer1", 1:3, "panel9"), "panel")
  expect_match(place_rows(fig, "built_layer1", 99L, panel), "rows")
})

test_that("a flipped panel says so, and its rows are placed where the engine places them", {
  skip_if_no("ggplot2")
  # bench runs 2026-11-12-1711 and -1722: under coord_flip() the horizontal
  # range is the plot's y, and nothing in the figure said so; rows landed
  # thousands of pt off and a right pairing failed (bioc-016, tree-045)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() + ggplot2::coord_flip()
  fig <- gloss(p, width = 7, height = 5, context = FALSE)
  expect_identical(gl_panels(fig)$flipped, TRUE)
  a <- alone_of(p, width = 7, height = 5)
  expect_equal(a$leaves$engine_status, "verified")
  expect_equal(a$leaves$alone_status, "verified")
  expect_equal(a$leaves$same, 32L)
  expect_lt(a$leaves$gap, 0.01)
  # rows with bounds, and labels on them
  pb <- ggplot2::ggplot(ggplot2::mpg, ggplot2::aes(class)) + ggplot2::geom_bar() +
    ggplot2::geom_text(ggplot2::aes(label = ggplot2::after_stat(count)), stat = "count", hjust = -0.2) +
    ggplot2::coord_flip()
  ab <- alone_of(pb, width = 7, height = 5)$leaves
  expect_equal(nrow(ab), 2L)
  expect_identical(ab$alone_status, ab$engine_status)
  expect_equal(sum(ab$same), sum(ab$n_elements))
  expect_true(all(ab$gap < 0.01))
  # a wrong row still fails
  expect_equal(a$leaves$moved_pass_alone, 0L)
})

test_that("panels of every engine say whether they are flipped", {
  skip_if_no("ggplot2")
  expect_identical(gl_panels(suppressWarnings(gloss(p_facet(), width = 7, height = 4, context = FALSE)))$flipped,
                   c(FALSE, FALSE))
  expect_identical(gl_panels(gloss(base_scatter, width = 5, height = 4, context = FALSE))$flipped, FALSE)
  expect_identical(empty_panels()$flipped, logical())
  skip_if_no("patchwork")
  pw <- patchwork::wrap_plots(p_facet(), p_facet() + ggplot2::coord_flip(), ncol = 1)
  expect_identical(gl_panels(suppressWarnings(gloss(pw, width = 7, height = 8, context = FALSE)))$flipped,
                   c(FALSE, FALSE, TRUE, TRUE))
})

test_that("a panel that does not say which scale is horizontal is not placed", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  fig <- gloss(p, width = 7, height = 5, context = FALSE)
  fig$substrate$panels$flipped <- NULL   # a figure captured before panels said so
  expect_match(place_rows(fig, "built_layer1", 1:3, "panel1"), "horizontal")
})

test_that("a leaf the engine does not pair has no row to place", {
  g <- grid::gTree(children = grid::gList(grid::circleGrob(r = 0.1)))
  a <- alone_of(g, width = 3, height = 3)
  expect_equal(nrow(a$leaves), 0L)
  expect_equal(nrow(a$elements), 0L)
})
