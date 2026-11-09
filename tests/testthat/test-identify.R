circle_centres <- function(el) {
  data.frame(cx = (el$x0 + el$x1) / 2, cy = (el$y0 + el$y1) / 2)
}

test_that("built data mapped through each panel's scales lands on the drawn points", {
  skip_if_no("ggplot2")
  fig <- suppressWarnings(gloss(p_facet(), width = 7, height = 4, context = FALSE))
  built <- gl_table(fig, "built_layer1")
  lv <- gl_leaf(fig)
  for (k in 1:2) {
    panel <- paste0("panel", k)
    rows <- built[built$PANEL == k, ]
    leaf <- lv$id[grepl("geom_point", lv$path) & lv$panel %in% panel]
    expect_length(leaf, 1L)
    el <- gl_elements(fig, list(leaf = leaf))
    px <- gl_to_pixel(fig, panel, rows$x, rows$y)
    cc <- circle_centres(el)
    expect_lt(max(abs(px$x - cc$cx)), 0.011)
    expect_lt(max(abs(px$y - cc$cy)), 0.011)
    back <- gl_to_data(fig, panel, cc$cx, cc$cy)
    expect_lt(max(abs(back$x - rows$x)), 0.01)
  }
  expect_equal(gl_panels(fig)$key, c("am=0", "am=1"))
})

test_that("facet_grid panels are matched to the layout by position", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() +
    ggplot2::facet_grid(am ~ cyl, scales = "free")
  fig <- gloss(p, width = 7, height = 5, context = FALSE)
  built <- gl_table(fig, "built_layer1")
  lv <- gl_leaf(fig)
  pan <- gl_panels(fig)
  expect_equal(nrow(pan), 6L)
  for (k in seq_len(nrow(pan))) {
    rows <- built[built$PANEL == k, ]
    leaf <- lv$id[grepl("geom_point", lv$path) & lv$panel %in% pan$id[k]]
    el <- gl_elements(fig, list(leaf = leaf))
    px <- gl_to_pixel(fig, pan$id[k], rows$x, rows$y)
    expect_lt(max(abs(px$x - circle_centres(el)$cx)), 0.011)
    expect_lt(max(abs(px$y - circle_centres(el)$cy)), 0.011)
  }
})

test_that("base plot windows use the native scales gridGraphics gives them", {
  skip_if_no("gridGraphics")
  fig <- gloss(function() plot(mtcars$wt, mtcars$mpg, pch = 19), width = 6, height = 4, context = FALSE)
  pan <- gl_panels(fig)
  expect_equal(nrow(pan), 1L)
  lv <- gl_leaf(fig)
  leaf <- lv$id[lv$class == "points" & lv$panel %in% pan$id]
  el <- gl_elements(fig, list(leaf = leaf[1]))
  px <- gl_to_pixel(fig, pan$id, mtcars$wt, mtcars$mpg)
  expect_lt(max(abs(px$x - circle_centres(el)$cx)), 0.011)
  expect_lt(max(abs(px$y - circle_centres(el)$cy)), 0.011)
})

test_that("hit testing, neighbours and overlap work in device space", {
  skip_if_no("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point(size = 3)
  fig <- gloss(p, width = 5, height = 4, context = FALSE)
  lv <- gl_leaf(fig)
  leaf <- lv$id[grepl("geom_point", lv$path)]
  el <- gl_elements(fig, list(leaf = leaf))
  target <- el[1, ]
  cx <- (target$x0 + target$x1) / 2
  cy <- (target$y0 + target$y1) / 2
  hit <- gl_hit(fig, cx, cy)
  expect_equal(hit$id[1], target$id)
  expect_true(all(c("circle", "rect") %in% hit$tag))
  hit_data <- gl_hit(fig, mtcars$wt[1], mtcars$mpg[1], space = "data", panel = "panel1")
  expect_equal(hit_data$id[1], target$id)
  near <- gl_near(fig, target$id, k = 3, same_leaf = TRUE)
  expect_equal(nrow(near), 3L)
  expect_true(all(diff(near$distance) >= 0))
  ov <- gl_overlap(fig, target$id)
  expect_true("below" %in% ov$relation)
  expect_error(gl_to_pixel(fig, "nope", 1, 1), "No panel")
})

test_that("gl_leaf and gl_elements describe one leaf", {
  g <- grid::gTree(children = grid::gList(
    grid::rectGrob(name = "bg"),
    grid::pointsGrob(c(0.2, 0.8), c(0.5, 0.5), name = "pts", pch = 19)
  ), name = "top")
  fig <- gloss(g, width = 2, height = 2, context = FALSE)
  pts <- gl_leaf(fig)$id[gl_leaf(fig)$name == "pts"]
  info <- gl_leaf(fig, pts)
  expect_equal(info$path, "top/pts")
  expect_equal(info$n_drawn, 2L)
  expect_length(info$elements, 2L)
  expect_equal(gl_elements(fig, list(leaf = pts))$ordinal, 1:2)
  expect_error(gl_elements(fig, list(nope = 1)), "Unknown element field")
})
