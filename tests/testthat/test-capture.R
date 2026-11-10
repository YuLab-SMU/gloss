test_that("the six input classes draw exactly what plain svglite draws", {
  skip_if_no("ggplot2", "patchwork", "gridGraphics", "ComplexHeatmap", "ggrepel")
  inputs <- six_inputs()
  for (nm in names(inputs)) {
    inp <- inputs[[nm]]
    fig <- suppressWarnings(gloss(inp$x, width = 7, height = 5, dense = Inf, context = FALSE))
    plain <- suppressWarnings(plain_svg(inp$draw, 7, 5))
    expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain), label = nm)
    el <- fig$substrate$elements
    unowned <- el[is.na(el$leaf), ]
    expect_equal(nrow(unowned), 1L, label = paste(nm, "unowned elements"))
    expect_equal(unowned$tag, "rect", label = paste(nm, "background tag"))
    expect_equal(c(unowned$x0, unowned$y0, unowned$x1, unowned$y1), c(0, 0, 504, 360),
                 label = paste(nm, "background box"))
    expect_equal(sum(fig$substrate$leaves$n_drawn), sum(!is.na(el$leaf)), label = nm)
  }
})

test_that("the faceted ggplot reproduces the counts measured in the spike", {
  skip_if_no("ggplot2")
  fig <- suppressWarnings(gloss(p_facet(), width = 7, height = 4, dense = Inf, context = FALSE))
  expect_equal(nrow(fig$substrate$elements), 134L)
  expect_equal(nrow(fig$substrate$leaves), 62L)
  expect_equal(sum(fig$substrate$leaves$status == "count_mismatch"), 6L)
  pts <- fig$substrate$leaves[grepl("geom_point", fig$substrate$leaves$path), ]
  expect_equal(pts$n_drawn, c(19L, 13L))
  expect_true(all(pts$status == "ok"))
})

test_that("probes record viewport paths and boxes", {
  skip_if_no("ComplexHeatmap")
  fig <- gloss(heatmap_example(), width = 7, height = 5, dense = Inf, context = FALSE)
  vps <- fig$substrate$leaves$vp
  expect_true(any(grepl("z_heatmap_body_1_1", vps)))
  expect_true(any(grepl("annotation_cyl_1", vps)))
  lv <- fig$substrate$leaves
  expect_true(all(lv$x0 <= lv$x1 & lv$y0 <= lv$y1))
})

test_that("a count mismatch is reported and the leaf is not bindable", {
  g <- grid::gTree(children = grid::gList(
    grid::pointsGrob(c(0.2, NA, 0.8), c(0.3, 0.5, 0.7), pch = 19, name = "pts"),
    grid::textGrob("two\nlines", name = "lbl")
  ), vp = grid::viewport(), name = "top")
  fig <- gloss(g, width = 3, height = 3, context = FALSE)
  lv <- fig$substrate$leaves
  pts <- lv[lv$name == "pts", ]
  expect_equal(pts$n_expected, 3L)
  expect_equal(pts$n_drawn, 2L)
  expect_equal(pts$status, "count_mismatch")
  expect_false(pts$bindable)
  lbl <- lv[lv$name == "lbl", ]
  expect_equal(c(lbl$n_expected, lbl$n_drawn), c(1L, 2L))
  expect_false(lbl$bindable)
})

test_that("a leaf that defines its own group is refused, not misattributed", {
  inner <- grid::groupGrob(grid::rectGrob(gp = grid::gpar(fill = "red")))
  g <- grid::gTree(children = grid::gList(inner, grid::circleGrob(r = 0.2)))
  expect_error(gloss(g, width = 2, height = 2, context = FALSE), "integrity")
})

test_that("drawing order is kept when childrenOrder differs from the child list", {
  a <- grid::rectGrob(name = "a", gp = grid::gpar(fill = "red"))
  b <- grid::circleGrob(name = "b", gp = grid::gpar(fill = "blue"))
  g <- grid::gTree(children = grid::gList(a, b), name = "top")
  g$childrenOrder <- c("b", "a")
  fig <- gloss(g, width = 2, height = 2, context = FALSE)
  plain <- plain_svg(function() grid::grid.draw(g), 2, 2)
  expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain))
})

test_that("dense leaves become a raster plus index, with the same element table", {
  skip_if_no("ggplot2")
  set.seed(3)
  d <- data.frame(x = rnorm(2000), y = rnorm(2000))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point()
  vec <- gloss(p, width = 4, height = 3, dense = Inf, context = FALSE)
  ras <- gloss(p, width = 4, height = 3, dense = 1000, context = FALSE)
  expect_identical(ras$substrate$elements, vec$substrate$elements)
  expect_equal(sum(ras$substrate$leaves$dense), 1L)
  id <- ras$substrate$leaves$id[ras$substrate$leaves$dense]
  png <- ras$substrate$rasters[[id]]
  expect_identical(png[1:4], as.raw(c(0x89, 0x50, 0x4e, 0x47)))
  expect_false(grepl("<circle", ras$substrate$scene))
  expect_true(grepl(paste0("gloss-raster:", id), ras$substrate$scene, fixed = TRUE))
})

test_that("engines are chosen by class and can be named", {
  skip_if_no("ggplot2", "patchwork")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_equal(gloss(p, context = FALSE)$meta$engine, "ggplot")
  expect_equal(gloss(patchwork::wrap_plots(p, p), context = FALSE)$meta$engine, "patchwork")
  # ggplotGrob() measures text, so build it on a null device, not Rplots.pdf.
  g <- local({
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off())
    ggplot2::ggplotGrob(p)
  })
  expect_equal(gloss(g, context = FALSE)$meta$engine, "grid")
  expect_error(gloss(1:3), "No engine plugin")
})

test_that("a ggplot without layers, alone or wrapped in patchwork, is captured", {
  # ggplot_build() adds a geom_blank layer to a plot without layers, so the
  # built data has one entry more than plot$layers. Wrapped elements
  # (wrap_elements(), wrap_ggplot_grob()) are such plots; two development
  # figures of the benchmark failed here (bench run 2026-11-10-1131).
  skip_if_no("ggplot2", "patchwork")
  empty <- gloss(ggplot2::ggplot(mtcars), context = FALSE)
  expect_equal(empty$meta$engine, "ggplot")
  expect_true(any(vapply(empty$tables, function(t) identical(t$role, "built"), logical(1))))
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  wrapped <- p + patchwork::wrap_elements(panel = grid::textGrob("a note"))
  fig <- gloss(wrapped, context = FALSE)
  expect_equal(fig$meta$engine, "patchwork")
  expect_true(any(fig$substrate$elements$text %in% "a note"))
  plain <- plain_svg(function() print(wrapped), 7, 5)
  expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain))
})

test_that("a ggplot extension that builds into something else is refused, alone or in patchwork", {
  # gganimate's ggplot_build() returns a "gganim_built", not a built ggplot;
  # drawing it failed with "no applicable method for `@`" (bench gallery-053).
  skip_if_no("ggplot2", "patchwork")
  registerS3method("ggplot_build", "gloss_test_anim",
                   function(plot, ...) structure(list(), class = "gloss_test_anim_built"),
                   envir = asNamespace("ggplot2"))
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  anim <- p
  class(anim) <- c("gloss_test_anim", class(anim))
  expect_error(gloss(anim, context = FALSE), "not a built ggplot")
  expect_error(gloss(patchwork::wrap_plots(p, anim), context = FALSE), "not a built ggplot")
  expect_equal(gloss(p, context = FALSE)$meta$engine, "ggplot")
})

test_that("fills, clipping paths and gTree alpha are captured unchanged", {
  cases <- list(
    gradient = grid::rectGrob(width = 0.8, height = 0.6,
                              gp = grid::gpar(fill = grid::linearGradient(c("red", "blue")))),
    pattern = grid::rectGrob(gp = grid::gpar(fill = grid::pattern(
      grid::circleGrob(r = 0.1, gp = grid::gpar(fill = "black")), width = 0.2, height = 0.2, extend = "repeat"))),
    clip = grid::gTree(children = grid::gList(grid::rectGrob(gp = grid::gpar(fill = "grey")),
                                              grid::pointsGrob(c(0.2, 0.5, 0.8), c(0.5, 0.5, 0.5), pch = 19)),
                       vp = grid::viewport(clip = grid::circleGrob(r = 0.3))),
    alpha = grid::gTree(children = grid::gList(grid::rectGrob(gp = grid::gpar(fill = "red")),
                                               grid::circleGrob(r = 0.2, gp = grid::gpar(fill = "blue"))),
                        gp = grid::gpar(alpha = 0.5))
  )
  for (nm in names(cases)) {
    g <- cases[[nm]]
    fig <- gloss(g, width = 3, height = 3, context = FALSE)
    plain <- plain_svg(function() grid::grid.draw(g), 3, 3)
    expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain), label = nm)
    expect_true(all(fig$substrate$leaves$status == "ok"), label = nm)
  }
})

test_that("a rect in a rotated viewport is drawn as two polygons and refused for binding", {
  g <- grid::gTree(children = grid::gList(grid::rectGrob(name = "r")),
                   vp = grid::viewport(angle = 30, width = 0.5, height = 0.5))
  fig <- gloss(g, width = 3, height = 3, context = FALSE)
  plain <- plain_svg(function() grid::grid.draw(g), 3, 3)
  expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain))
  r <- fig$substrate$leaves[fig$substrate$leaves$name == "r", ]
  expect_equal(c(r$n_expected, r$n_drawn), c(1L, 2L))
  expect_equal(r$status, "count_mismatch")
})

test_that("a masked figure is refused, because groups drop the mask", {
  g <- grid::gTree(children = grid::gList(grid::rectGrob(gp = grid::gpar(fill = "red"))),
                   vp = grid::viewport(mask = grid::circleGrob(r = 0.3, gp = grid::gpar(fill = "black"))))
  expect_error(gloss(g, width = 3, height = 3, context = FALSE), "mask")
})
