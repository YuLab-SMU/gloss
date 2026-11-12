test_that("the six input classes draw exactly what plain svglite draws", {
  # The base input's reference is its own page on svglite (it was gridGraphics'
  # page until page-capture plan Task 5).
  skip_if_no("ggplot2", "patchwork", "ComplexHeatmap", "ggrepel")
  inputs <- six_inputs()
  for (nm in names(inputs)) {
    inp <- inputs[[nm]]
    fig <- suppressWarnings(gloss(inp$x, width = 7, height = 5, dense = Inf, context = FALSE))
    plain <- suppressWarnings(plain_svg(inp$draw, 7, 5))
    expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain), label = nm)
    expect_identical(clip_regions(fig$substrate$scene), clip_regions(plain), label = paste(nm, "clip regions"))
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
  # The points leaf used to be the mismatch here: one expected per point,
  # the point at x = NA included. R's engine does not draw a point whose
  # position is not finite, so 2 is what the device draws, and capture now
  # counts it so (plan 2026-11-11-tree-binding, Task 5; base pages always
  # did). The text leaf is still the mismatch this test is about.
  pts <- lv[lv$name == "pts", ]
  expect_equal(pts$n_expected, 2L)
  expect_equal(pts$n_drawn, 2L)
  expect_equal(pts$status, "ok")
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

test_that("an object whose print method draws another figure is captured as what print draws", {
  # Replaces "a figure that prints through its own method is refused"
  # (efe9936): ADR-0006 point 5 removes the refusal by class. ggbreak's ggcut
  # (exts-018) prints a cut axis, and the engine-built grob was the uncut plot;
  # gloss now captures the page print() draws. ggExtra (gallery-052) was
  # refused by class although its capture was correct.
  skip_if_no("ggplot2")
  registerS3method("print", "gloss_test_print", function(x, ...) {
    y <- x
    class(y) <- setdiff(class(x), "gloss_test_print")
    print(y + ggplot2::labs(title = "drawn by print"))
    invisible(x)
  }, envir = baseenv())
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  custom <- p
  class(custom) <- c("gloss_test_print", class(p))
  fig <- gloss(custom, width = 5, height = 4, context = FALSE)
  plain <- plain_svg(function() print(custom), 5, 4)
  expect_equal(fig$meta$engine, "ggplot")
  expect_true("drawn by print" %in% fig$substrate$elements$text)
  expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain))
  expect_identical(clip_regions(fig$substrate$scene), clip_regions(plain))
  expect_equal(fig$meta$page$verdict, "equal")
  # Its built data and panels describe the plot before print.gloss_test_print,
  # not the page: they are withheld with the reason; the raw data is kept.
  expect_false(any(grepl("^built_", names(fig$tables))))
  expect_true("raw" %in% names(fig$tables))
  expect_equal(nrow(fig$substrate$panels), 0L)
  w <- fig$status$withheld
  expect_setequal(w$what, c("built_layer1", "panels"))
  expect_true(all(grepl("print.gloss_test_print", w$reason, fixed = TRUE)))
  expect_output(print(fig), "withheld panels: print.gloss_test_print")
  # A plain ggplot keeps its built tables and panels.
  plain_fig <- gloss(p, width = 5, height = 4, context = FALSE)
  expect_true("built_layer1" %in% names(plain_fig$tables))
  expect_equal(nrow(plain_fig$substrate$panels), 1L)
  expect_null(plain_fig$status$withheld)
  if (requireNamespace("ggExtra", quietly = TRUE)) {
    # ggMarginal() builds grobs, which needs a device: a null one, not
    # Rplots.pdf in the working directory (read-only in the bench container)
    g <- local({
      grDevices::pdf(NULL)
      on.exit(grDevices::dev.off())
      ggExtra::ggMarginal(p, type = "histogram")
    })
    fig <- gloss(g, width = 5, height = 4, context = FALSE)
    plain <- plain_svg(function() print(g), 5, 4)
    expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain), label = "ggExtra")
    expect_identical(clip_regions(fig$substrate$scene), clip_regions(plain), label = "ggExtra clip regions")
  }
})

test_that("a grob whose name is a vector is captured", {
  # treemap draws grid.rect(name = <one name per rectangle>) (bench
  # gallery-056); grid draws it, grid.grab() returned a tree it cannot index.
  draw <- function() {
    grid::grid.newpage()
    grid::grid.rect(x = c(0.25, 0.75), width = 0.3, height = 0.3,
                    gp = grid::gpar(fill = c("red", "blue")), name = c("left", "right"))
  }
  fig <- gloss(draw, width = 3, height = 3, context = FALSE)
  plain <- plain_svg(draw, 3, 3)
  expect_equal(fig$meta$engine, "grid")
  expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain))
  lv <- fig$substrate$leaves
  expect_equal(nrow(lv), 1L)
  expect_equal(lv$name, "left")
  expect_equal(c(lv$n_expected, lv$n_drawn), c(2L, 2L))
  expect_equal(fig$meta$page$renamed, 1L)
})

test_that("a function or a recorded plot that draws with grid is captured by the grid engine", {
  # A function drawing with grid stopped with "EXPR must be a length 1 vector"
  # (dev log 2026-11-10-page-capture-spike): the base engine took every
  # function. Class does not fix the page kind; the page drawn does.
  f <- function() {
    grid::grid.newpage()
    grid::pushViewport(grid::viewport(width = 0.8, height = 0.8, xscale = c(0, 10), yscale = c(0, 10)))
    grid::grid.rect(gp = grid::gpar(fill = "grey95"))
    grid::grid.points(c(2, 5, 8), c(3, 7, 4), pch = 19, default.units = "native")
    grid::upViewport()
    grid::grid.text("title", y = 0.95)
  }
  fig <- gloss(f, width = 3, height = 3, context = FALSE)
  plain <- plain_svg(f, 3, 3)
  expect_equal(fig$meta$engine, "grid")
  expect_equal(fig$meta$page$kind, "grid")
  expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain))
  pts <- fig$substrate$leaves[fig$substrate$leaves$class == "points", ]
  expect_equal(c(pts$xscale0, pts$xscale1), c(0, 10))
  rp <- local({
    s <- svglite::svgstring(width = 3, height = 3)
    on.exit(grDevices::dev.off())
    grDevices::dev.control("enable")
    f()
    grDevices::recordPlot()
  })
  fig <- gloss(rp, width = 3, height = 3, context = FALSE)
  expect_equal(fig$meta$engine, "grid")
  expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain))
})

test_that("an empty page and a page mixing base and grid are refused with the reason", {
  expect_error(gloss(function() invisible(NULL), context = FALSE), "drew nothing")
  mixed <- function() {
    graphics::plot(1:3)
    grid::grid.text("on top", y = 0.9)
  }
  expect_error(gloss(mixed, context = FALSE), "base graphics and grid")
})

test_that("a base page drawn after a grid page is a base page, and a grid page after a base page a grid page", {
  # Held-out run 2026-11-11-0837 (this test is made after looking at it): two
  # base figures at the end of a vignette were refused as mixed pages. A new
  # base page does not clear grid's display list, so the grobs of the page
  # before were counted as drawn on this one. Reproduced here on a hand-built
  # page; the device's display list for the page holds no grid operation.
  scatter <- function() graphics::plot(mtcars$wt, mtcars$mpg, pch = 19, main = "second page")
  two <- function() {
    grid::grid.newpage()
    grid::grid.rect(gp = grid::gpar(fill = "red"))
    grid::grid.text("first page")
    scatter()
  }
  rp <- local({
    s <- svglite::svgstring(width = 5, height = 4)
    on.exit(grDevices::dev.off())
    grDevices::dev.control("enable")
    two()
    grDevices::recordPlot()
  })
  plain <- plain_svg(scatter, 5, 4)
  expect_warning(drawn <- gloss(two, width = 5, height = 4, context = FALSE), "2 pages")
  figs <- list(drawn = drawn, recorded = gloss(rp, width = 5, height = 4, context = FALSE))
  for (nm in names(figs)) {
    fig <- figs[[nm]]
    expect_equal(fig$meta$engine, "base", label = nm)
    expect_equal(fig$meta$page$kind, "base", label = nm)
    expect_equal(fig$meta$page$verdict, "equal", label = nm)
    expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain), label = nm)
    expect_identical(clip_regions(fig$substrate$scene), clip_regions(plain), label = paste(nm, "clip regions"))
    expect_false(any(grepl("first page", fig$substrate$elements$text, fixed = TRUE)), label = nm)
  }
  # the other order: the base page before is gone from the device's display list
  after_base <- function() {
    graphics::plot(1:3)
    grid::grid.newpage()
    grid::grid.circle(r = 0.3, gp = grid::gpar(fill = "blue"))
  }
  expect_warning(fig <- gloss(after_base, width = 3, height = 3, context = FALSE), "2 pages")
  expect_equal(fig$meta$page$kind, "grid")
  expect_equal(fig$substrate$leaves$class, "circle")
  # a recorded page that does mix the two is still refused
  mixed <- local({
    s <- svglite::svgstring(width = 5, height = 4)
    on.exit(grDevices::dev.off())
    grDevices::dev.control("enable")
    graphics::plot(1:3)
    grid::grid.text("on top", y = 0.9)
    grDevices::recordPlot()
  })
  expect_error(gloss(mixed, context = FALSE), "base graphics and grid")
})

test_that("an input that draws several pages is captured as its last page, with a warning", {
  f <- function() {
    grid::grid.newpage()
    grid::grid.rect(gp = grid::gpar(fill = "red"))
    grid::grid.newpage()
    grid::grid.circle(r = 0.3, gp = grid::gpar(fill = "blue"))
  }
  expect_warning(fig <- gloss(f, width = 3, height = 3, context = FALSE), "2 pages")
  expect_equal(fig$meta$page$pages, 2L)
  expect_equal(fig$substrate$leaves$class, "circle")
  expect_identical(scene_signatures(fig$substrate$scene),
                   scene_signatures(plain_svg(function() grid::grid.circle(r = 0.3, gp = grid::gpar(fill = "blue")), 3, 3)))
})

test_that("the self-check compares the captured page with the page drawn", {
  # Equal: captured, and the verdict is stored and printed.
  fig <- gloss(grid::circleGrob(r = 0.3), width = 2, height = 2, context = FALSE)
  expect_equal(fig$meta$page$verdict, "equal")
  expect_equal(fig$meta$page$differ, 0L)
  expect_output(print(fig), "page: grid, .*equal to the page drawn")
  # Not deterministic: every drawing differs, so does a plain redraw.
  registerS3method("makeContent", "gloss_test_random", function(x) {
    grid::setChildren(x, grid::gList(grid::pointsGrob(stats::runif(5), stats::runif(5), pch = 19)))
  }, envir = asNamespace("grid"))
  rnd <- grid::gTree(cl = "gloss_test_random", name = "rnd")
  expect_warning(fig <- gloss(rnd, width = 2, height = 2, context = FALSE), "not deterministic")
  expect_equal(fig$meta$page$verdict, "not_deterministic")
  expect_gt(fig$meta$page$differ, 0L)
  expect_output(print(fig), "not deterministic")
  # Capture changed the figure while a plain redraw does not: abort.
  local_mocked_bindings(scalar_names = function(x, acc) {
    if (inherits(x, "rect")) x$gp <- grid::gpar(fill = "purple")
    x
  })
  expect_error(gloss(grid::rectGrob(gp = grid::gpar(fill = "grey")), width = 2, height = 2, context = FALSE),
               "changed the figure")
})

test_that("the self-check verdict follows from the three pages", {
  a <- c("rect x=1", "circle r=2")
  b <- c("rect x=1", "circle r=3")
  expect_equal(page_verdict(a, a, redraw = function() stop("not needed"))$verdict, "equal")
  expect_equal(page_verdict(a, b, redraw = function() b)$verdict, "not_deterministic")
  expect_error(page_verdict(a, b, redraw = function() a), "changed the figure")
  # random at draw time: the second plain redraw differs from the first
  draws <- list(c("rect x=1", "circle r=4"), c("rect x=1", "circle r=5"))
  n <- new.env()
  n$k <- 0L
  redraw <- function() {
    n$k <- n$k + 1L
    draws[[n$k]]
  }
  expect_equal(page_verdict(a, b, redraw = redraw)$verdict, "not_deterministic")
  # deterministic redraws that disagree with the captured page: abort
  expect_error(page_verdict(a, b, redraw = function() c("rect x=1", "circle r=4")), "changed the figure")
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
    expect_identical(clip_regions(fig$substrate$scene), clip_regions(plain), label = paste(nm, "clip regions"))
    expect_true(all(fig$substrate$leaves$status == "ok"), label = nm)
  }
})

test_that("a clipping grob keeps clipping the leaves drawn after it", {
  # A clipGrob draws nothing and sets the clip for what follows. Wrapped in a
  # graphics group like any leaf, its clip ended with the group and the next
  # leaf was drawn unclipped, with every primitive unchanged, so the signature
  # comparison could not see it (dev log 2026-11-10-page-capture-spike).
  g <- grid::gTree(children = grid::gList(
    grid::clipGrob(width = 0.4, height = 0.4, name = "window"),
    grid::circleGrob(r = 0.45, gp = grid::gpar(fill = "blue"), name = "disc")
  ))
  fig <- gloss(g, width = 3, height = 3, context = FALSE)
  plain <- plain_svg(function() grid::grid.draw(g), 3, 3)
  expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain))
  expect_true(any(nzchar(clip_regions(plain)) & grepl("rect", clip_regions(plain))))
  expect_identical(clip_regions(fig$substrate$scene), clip_regions(plain))
  expect_equal(fig$substrate$leaves$name, "disc")
  # two clips in a row, and a clip inside a viewport followed by a sibling outside it
  two <- grid::gTree(children = grid::gList(
    grid::clipGrob(width = 0.9, height = 0.9), grid::rectGrob(gp = grid::gpar(fill = "grey")),
    grid::clipGrob(width = 0.3, height = 0.3), grid::circleGrob(r = 0.4)
  ))
  nested <- grid::gTree(children = grid::gList(
    grid::gTree(children = grid::gList(grid::clipGrob(width = 0.5, height = 0.5),
                                       grid::rectGrob(gp = grid::gpar(fill = "red"))),
                vp = grid::viewport(width = 0.8, height = 0.8)),
    grid::circleGrob(r = 0.5, gp = grid::gpar(fill = "green"))
  ))
  for (g in list(two, nested)) {
    fig <- gloss(g, width = 3, height = 3, context = FALSE)
    plain <- plain_svg(function() grid::grid.draw(g), 3, 3)
    expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain))
    expect_identical(clip_regions(fig$substrate$scene), clip_regions(plain))
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

test_that("the page signature reads every primitive with its clip regions, as a node-by-node read does", {
  # page_signature() reads each top-level child of svglite's page once; the
  # node-by-node read through XPath is the reference it must agree with.
  by_nodes <- function(doc) {
    defs <- xml2::xml_find_all(doc, "//d1:clipPath", svg_ns(doc))
    geom <- vapply(defs, function(d) paste(as.character(xml2::xml_children(d)), collapse = ";"), "")
    names(geom) <- xml2::xml_attr(defs, "id")
    signature_nodes(doc, geom)
  }
  pages <- list(
    clip_window = function() grid::grid.draw(grid::gTree(children = grid::gList(
      grid::clipGrob(width = 0.4, height = 0.4), grid::circleGrob(r = 0.45)))),
    clip_path = function() grid::grid.draw(grid::gTree(
      children = grid::gList(grid::rectGrob(gp = grid::gpar(fill = "grey")), grid::pointsGrob(c(0.2, 0.8), c(0.5, 0.5))),
      vp = grid::viewport(clip = grid::circleGrob(r = 0.3)))),
    pattern = function() grid::grid.draw(grid::rectGrob(gp = grid::gpar(fill = grid::pattern(
      grid::circleGrob(r = 0.1, gp = grid::gpar(fill = "black")), width = 0.2, height = 0.2, extend = "repeat")))),
    text = function() grid::grid.text(c("a < b & c", "two"), y = c(0.3, 0.7))
  )
  if (requireNamespace("ggplot2", quietly = TRUE)) pages$ggplot <- function() print(p_facet())
  for (nm in names(pages)) {
    doc <- xml2::read_xml(suppressWarnings(plain_svg(pages[[nm]], 3, 3)))
    expect_identical(page_signature(doc), by_nodes(doc), label = nm)
    expect_equal(length(page_signature(doc)), length(scene_signatures(as.character(doc))), label = nm)
  }
  # A primitive that loses its clip changes the signature.
  doc <- xml2::read_xml(plain_svg(pages$clip_window, 3, 3))
  before <- page_signature(doc)
  for (g in xml2::xml_find_all(doc, "//d1:g[@clip-path]", svg_ns(doc))) xml2::xml_set_attr(g, "clip-path", NULL)
  expect_false(identical(page_signature(doc), before))
})

test_that("a base page is captured as base graphics draws it, one leaf per display-list entry", {
  # gridGraphics redrew base pages with a second implementation of base
  # graphics: rect(border = 0) differed in 2 primitives, a plot recorded on
  # svglite in 1 (the background rect), 9 of 10 development base figures
  # differed (dev log 2026-11-10-page-capture-spike). Page-capture plan Task 5.
  border0 <- function() {
    graphics::plot.new()
    graphics::rect(0.2, 0.2, 0.8, 0.8, col = "white", border = 0)
  }
  scatter <- function() graphics::plot(mtcars$wt, mtcars$mpg, pch = 19, main = "A title")
  rp <- local({
    s <- svglite::svgstring(width = 5, height = 4)
    on.exit(grDevices::dev.off())
    grDevices::dev.control("enable")
    scatter()
    grDevices::recordPlot()
  })
  cases <- list(border0 = list(x = border0, draw = border0), scatter = list(x = scatter, draw = scatter),
                recorded = list(x = rp, draw = scatter))
  for (nm in names(cases)) {
    fig <- gloss(cases[[nm]]$x, width = 5, height = 4, context = FALSE)
    plain <- plain_svg(cases[[nm]]$draw, 5, 4)
    expect_equal(fig$meta$engine, "base", label = nm)
    expect_equal(fig$meta$page$kind, "base", label = nm)
    expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain), label = nm)
    expect_identical(clip_regions(fig$substrate$scene), clip_regions(plain), label = paste(nm, "clip regions"))
    el <- fig$substrate$elements
    expect_equal(sum(is.na(el$leaf)), 1L, label = paste(nm, "unowned"))
    expect_equal(sum(fig$substrate$leaves$n_drawn), sum(!is.na(el$leaf)), label = nm)
  }
  expect_match(fig$meta$page$note, "text metrics")
  # Leaves are display-list entries, named by their call, with expected counts.
  lv <- gloss(scatter, width = 5, height = 4, context = FALSE)$substrate$leaves
  expect_true(all(c("plotXY", "axis", "box", "title") %in% lv$name))
  pts <- lv[lv$name == "plotXY", ]
  expect_equal(c(pts$n_expected, pts$n_drawn), c(32L, 32L))
  expect_equal(pts$status, "ok")
  expect_true(all(is.na(lv$n_expected[lv$name == "axis"])))
  expect_match(pts$path, "^base/[0-9]+/plotXY$")
})

test_that("base data-mark calls without a count before M1 Task 5 have one, equal to what svglite draws", {
  # Development set, capture 2026-11-11-1307: 574 base leaves had no expected
  # count; among the data-mark calls, path (483), polygon (21), symbols (8)
  # and plotXY of types other than "p" and "l" (5). The rules were measured
  # on hand-built pages first (dev log 2026-11-11), each with NAs and the
  # cases svglite draws nothing for.
  x <- c(1, 2, 3, NA, 5, 6, 7, 8)
  y <- c(2, 4, 3, 5, NA, 1, 2, 2)
  page <- function() {
    graphics::par(mfrow = c(2, 4))
    for (ty in c("b", "o", "h", "s", "S", "c")) graphics::plot(x, y, type = ty)
    graphics::plot(1:10)
    graphics::polygon(c(1, 2, 3, NA, 5, NA, 8, 9, NA, NA, 4, 5, 6), c(1, 3, 1, NA, 5, NA, 2, 9, NA, NA, 4, 6, 4))
    graphics::polypath(c(1, 5, 5, 1, NA, 2, 3, 3, 2), c(1, 1, 5, 5, NA, 2, 2, 3, 3))
    suppressWarnings(graphics::arrows(c(1, 2, 3, NA), c(1, 2, 3, 1), c(4, 2, 6, 5), c(8, 2, 10, 9), code = 3))
    graphics::arrows(1:2, 1:2, 3:4, 5:6, code = 0)
    graphics::abline(h = c(2, 100, NA), v = 5)
    graphics::abline(1, 1)
    graphics::symbols(1:3, 1:3, circles = c(1, 2, NA), inches = 0.2, add = TRUE)
    graphics::symbols(1:3, 1:3, squares = c(1, 1, 1), inches = 0.2, add = TRUE)
    graphics::symbols(1:3, 1:3, rectangles = cbind(1:3, c(1, NA, 1)), inches = 0.3, add = TRUE)
    graphics::plot(1:3)
    graphics::symbols(1:3, 1:3, thermometers = cbind(1, 2, c(0.2, 0.5, 0.8)), inches = 0.3, add = TRUE)
  }
  # replaying the page repeats the figure's own warning about the zero-length
  # arrow; that one is muffled, any other warning is not
  lv <- withCallingHandlers(gloss(page, width = 9, height = 5, context = FALSE),
                            warning = function(w) if (grepl("zero-length arrow", conditionMessage(w))) invokeRestart("muffleWarning"))$substrate$leaves
  counted <- lv[lv$name %in% c("plotXY", "polygon", "path", "arrows", "abline", "symbols"), ]
  thermo <- utils::tail(which(counted$name == "symbols"), 1L)
  expect_true(is.na(counted$n_expected[thermo]))           # thermometers: no rule
  rest <- counted[-thermo, ]
  expect_false(anyNA(rest$n_expected))
  expect_equal(rest$n_expected, rest$n_drawn)
  expect_true(all(rest$status == "ok"))
  # the drawn counts the rules were measured against: x and y leave 6 finite
  # points in two runs of 3; "b" draws the points and a segment per adjacent
  # pair (6 + 4), "o" the points and a polyline per run (6 + 2), "h" a line
  # per point, "s" and "S" a polyline per run, "c" the segments only
  xy <- rest$n_drawn[rest$name == "plotXY"][1:6]
  expect_equal(xy, c(10L, 8L, 6L, 2L, 2L, 4L))
  # polygon: runs of 2 or more points (3, 2, 3; not the single point);
  # arrows with code 3: 3 finite shafts, 2 heads each but on the zero-length one;
  # abline: h = 2 and 100 (outside the range, still drawn), v = 5; then a, b
  expect_equal(rest$n_drawn[rest$name %in% c("polygon", "path", "arrows", "abline")], c(3L, 1L, 7L, 2L, 3L, 1L))
  expect_equal(rest$n_drawn[rest$name == "symbols"], c(2L, 3L, 2L))
})

test_that("base text drawn as plotmath or with multibyte characters is split by entry", {
  # p5-base-fixtures: an expression label made base_expected() fail on anyNA();
  # behind it, the page was cut at byte offsets with substr(), which counts
  # characters, so a multibyte character (plotmath writes alpha as U+03B1)
  # left the split page not well-formed.
  pm <- function() {
    graphics::plot(1:3, 1:3, main = quote(alpha^2 + beta[i]))
    graphics::text(2, 2, expression(sqrt(x), bar(y)))
    graphics::text(2.5, 1.2, "µg/L")
    graphics::text(1.5, 1.5, "plain")
  }
  fig <- gloss(pm, width = 5, height = 4, context = FALSE)
  plain <- plain_svg(pm, 5, 4)
  expect_identical(scene_signatures(fig$substrate$scene), scene_signatures(plain))
  expect_true("µg/L" %in% fig$substrate$elements$text)
  lv <- fig$substrate$leaves
  expect_equal(fig$meta$page$verdict, "equal")
  expect_true(all(is.na(lv$n_expected[lv$name %in% c("title", "text")][1:2])))
  plain <- lv[lv$name == "text", ]
  expect_equal(plain$n_expected[nrow(plain)], 1L)
  expect_equal(plain$status[nrow(plain)], "ok")
})

test_that("base leaves keep the counts read while replaying, also across clip changes", {
  # An entry's primitives between two clip changes are wrapped separately;
  # the wrapped scene must hold, per leaf, the count read during the replay.
  chunk <- paste(c("<circle cx='1' cy='1' r='1' />", "<circle cx='2' cy='2' r='1' />",
                   "</g>", "<defs>", "  <clipPath id='cpX'>", "    <rect x='0' y='0' width='9' height='9' />",
                   "  </clipPath>", "</defs>", "<g clip-path='url(#cpX)'>",
                   "<text x='1' y='1'>a</text>", ""), collapse = "\n")
  w <- wrap_entry(chunk, "L007")
  expect_equal(w$n, 3L)
  expect_equal(lengths(regmatches(w$text, gregexpr("<g data-gloss-leaf='L007'>", w$text, fixed = TRUE))), 2L)
  # many entries, linear reading: 5000 segments() calls
  skip_on_cran()
  many <- function() {
    graphics::plot(0:1, 0:1, type = "n")
    set.seed(1)
    for (i in seq_len(5000)) graphics::segments(stats::runif(1), stats::runif(1), stats::runif(1), stats::runif(1))
  }
  t0 <- proc.time()[["elapsed"]]
  fig <- gloss(many, width = 5, height = 4, context = FALSE)
  secs <- proc.time()[["elapsed"]] - t0
  expect_equal(sum(fig$substrate$leaves$name == "segments"), 5000L)
  expect_equal(fig$meta$page$verdict, "equal")
  expect_lt(secs, 30)
})

test_that("a dense base leaf becomes a raster with the same element table", {
  big <- function() {
    set.seed(6)
    graphics::plot(stats::rnorm(3000), stats::rnorm(3000), pch = 19)
  }
  vec <- gloss(big, width = 4, height = 3, dense = Inf, context = FALSE)
  ras <- gloss(big, width = 4, height = 3, dense = 1000, context = FALSE)
  expect_identical(ras$substrate$elements, vec$substrate$elements)
  expect_equal(sum(ras$substrate$leaves$dense), 1L)
  id <- ras$substrate$leaves$id[ras$substrate$leaves$dense]
  expect_equal(ras$substrate$leaves$name[ras$substrate$leaves$id == id], "plotXY")
  png <- ras$substrate$rasters[[id]]
  expect_identical(png[1:4], as.raw(c(0x89, 0x50, 0x4e, 0x47)))
})

test_that("gloss() leaves a recorded plot unchanged, so it can be captured again", {
  # Development binding run 2026-11-11-1205: three grid figures, handed to
  # gloss as recorded plots, failed their second capture in the same session
  # ("0 probes drew"). The first capture had wrapped the leaves of grid's
  # display list in place, and that list is the one inside the recording.
  record <- function(draw) local({
    s <- svglite::svgstring(width = 4, height = 3)
    on.exit(grDevices::dev.off())
    grDevices::dev.control("enable")
    draw()
    grDevices::recordPlot()
  })
  pages <- list(
    grid = record(function() {
      grid::grid.newpage()
      grid::grid.rect(gp = grid::gpar(fill = "grey90"))
      grid::grid.points(grid::unit(c(0.2, 0.5), "npc"), grid::unit(c(0.3, 0.6), "npc"))
    }),
    base = record(function() graphics::plot(1:10, (1:10)^2))
  )
  for (nm in names(pages)) {
    rp <- pages[[nm]]
    before <- serialize(rp, NULL)
    first <- gloss(rp, width = 4, height = 3, context = FALSE)
    expect_identical(serialize(rp, NULL), before, label = paste(nm, "recording after the first capture"))
    second <- gloss(rp, width = 4, height = 3, context = FALSE)
    expect_identical(second$substrate$elements, first$substrate$elements, label = nm)
    expect_identical(second$substrate$leaves, first$substrate$leaves, label = nm)
  }
})

test_that("a page with an image over the XML parser's limit is captured and bound, on both routes", {
  # Bench tree-041 (plan 2026-11-11-tree-binding, Task 1): a page whose
  # embedded images exceed libxml2's limit for one node (10^7 bytes). gloss
  # stopped with the parser's error ("Huge input lookup" in the container,
  # "AttValue length too long" on the host), neither capturing the page nor
  # refusing it with a reason; on the base route the same page was called
  # "not well-formed".
  skip_on_cran()
  set.seed(1)
  n <- 1900
  img <- matrix(grDevices::rgb(stats::runif(n * n), stats::runif(n * n), stats::runif(n * n)), n, n)
  pages <- list(
    grid = function() {
      grid::grid.newpage()
      grid::grid.raster(img, width = 0.5, height = 0.5, name = "photo")
      grid::grid.points(grid::unit(c(0.1, 0.9), "npc"), grid::unit(c(0.1, 0.9), "npc"), pch = 19)
    },
    base = function() {
      graphics::plot.new()
      graphics::rasterImage(img, 0.25, 0.25, 0.75, 0.75)
      graphics::points(c(0.1, 0.9), c(0.1, 0.9), pch = 19)
    }
  )
  for (nm in names(pages)) {
    b <- bind_capture(pages[[nm]], width = 4, height = 4)
    fig <- b$fig
    expect_gt(nchar(fig$substrate$scene), 1e7, label = nm)
    expect_equal(fig$meta$page$verdict, "equal", label = nm)
    el <- fig$substrate$elements
    expect_equal(sum(el$tag == "image" & !is.na(el$leaf)), 1L, label = paste(nm, "images"))
    expect_equal(sum(el$tag == "circle" & !is.na(el$leaf)), 2L, label = paste(nm, "points"))
    expect_equal(nrow(b$leaves), nrow(fig$substrate$leaves), label = paste(nm, "bound leaves"))
  }
  # base binds its points through their arguments, on the page with the image
  pts <- b$leaves[b$leaves$verified > 0, ]
  expect_equal(sum(pts$verified), 2L)
})

# Points drawn as several elements (plan 2026-11-11-tree-binding, Task 5).
# Bench tree-014: 8100 points in shapes 1-8 drew 12690 elements, and capture
# expected one per point, a count mismatch over half the tree stratum's layer
# elements. What each symbol draws, and what removes parts:
# dev_docs/research/point-symbols.

svglite_count <- function(draw) {
  svg <- plain_svg(function() {
    grid::grid.newpage()
    suppressWarnings(draw())
  }, 3, 3)
  doc <- read_page(svg)
  nodes <- xml2::xml_find_all(doc, prim_xpath(), svg_ns(doc))
  # the device's own background
  sum(!(xml2::xml_name(nodes) == "rect" & xml2::xml_attr(nodes, "width") %in% "100%"))
}

test_that("a points grob is expected to draw what svglite draws for its symbols", {
  x <- grid::unit(c(0.2, 0.5, 0.8), "npc")
  cases <- c(lapply(0:25, function(p) list(pch = p)), list(
    list(pch = c(3L, 8L, 7L)), list(pch = 46L), list(pch = "."), list(pch = c("a", "", NA)),
    list(pch = c(26L, NA, -65L)), list(pch = 200L), list(pch = c(0.5, 2.7, 25.9)),
    list(pch = 8, gp = grid::gpar(lty = 0)), list(pch = c(7, 10, 13), gp = grid::gpar(lty = c(0, 1, 1))),
    list(pch = c(9, 12, 14), gp = grid::gpar(lty = "blank")), list(pch = 3, gp = grid::gpar(lwd = NA)),
    list(pch = c(8, 3, 4), gp = grid::gpar(lwd = c(NA, 1, 0), lex = 1)),
    list(pch = c(1, 3, 21), size = grid::unit(0, "pt")), list(pch = c(10, 16, 0), gp = grid::gpar(fontsize = 0)),
    list(pch = c(13, 19, 20), gp = grid::gpar(cex = c(0, 1, 0))), list(pch = "a", gp = grid::gpar(fontsize = 0)),
    list(pch = 3, x = grid::unit(c(0.2, NA, Inf), "npc")), list(pch = 8, size = grid::unit(c(1, NA, 1), "char"))
  ))
  for (cs in cases) {
    g <- grid::pointsGrob(cs$x %||% x, x, pch = cs$pch, size = cs$size %||% grid::unit(1, "char"),
                          gp = cs$gp %||% grid::gpar())
    expect_equal(expected_count(g), svglite_count(function() grid::grid.draw(g)), label = paste(deparse(cs$pch), deparse(unclass(cs$gp)), deparse(cs$size)))
  }
})

test_that("settings a points leaf inherits from its parents count where the leaf is drawn", {
  x <- grid::unit(c(0.2, 0.5, 0.8), "npc")
  kids <- function(...) grid::gList(grid::pointsGrob(x, x, name = "pts", ...))
  cases <- list(
    lty = grid::gTree(gp = grid::gpar(lty = 0), children = kids(pch = 7)),
    lty_leaf = grid::gTree(gp = grid::gpar(lty = 0), children = kids(pch = 7, gp = grid::gpar(lty = 1))),
    lex = grid::gTree(gp = grid::gpar(lex = NA), children = kids(pch = c(3, 10, 0))),
    cex = grid::gTree(gp = grid::gpar(cex = 0), children = kids(pch = c(1, 3, 13), gp = grid::gpar(cex = 2))),
    fontsize = grid::gTree(gp = grid::gpar(fontsize = 0), children = kids(pch = c(1, 19), gp = grid::gpar(fontsize = c(0, 12)))),
    viewport = grid::gTree(vp = grid::viewport(gp = grid::gpar(lty = "blank")), children = kids(pch = c(8, 9, 12))),
    font = grid::gTree(gp = grid::gpar(fontface = 5), children = kids(pch = 200L))
  )
  for (nm in names(cases)) {
    fig <- suppressWarnings(gloss(cases[[nm]], width = 3, height = 3, context = FALSE))
    lv <- fig$substrate$leaves[fig$substrate$leaves$name == "pts", ]
    expect_equal(lv$n_drawn, svglite_count(function() grid::grid.draw(cases[[nm]])), label = nm)
    expect_equal(lv$n_expected, lv$n_drawn, label = nm)
    expect_equal(lv$status, "ok", label = nm)
  }
})

test_that("ggplot2 points in all 26 shapes are counted, and tree-014's eight shapes", {
  skip_if_no("ggplot2")
  d <- data.frame(x = 1:26, y = 1:26, s = 0:25)
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y, shape = .data$s)) + ggplot2::geom_point(fill = "grey") +
    ggplot2::scale_shape_identity()
  lv <- gloss(p, width = 4, height = 4, context = FALSE)$substrate$leaves
  pts <- lv[grepl("geom_point", lv$path), ]
  expect_equal(nrow(pts), 1L)
  # parts per shape 0-25, from dev_docs/research/point-symbols
  parts <- c(1, 1, 1, 2, 2, 1, 1, 3, 4, 3, 3, 2, 3, 3, 2, rep(1, 11))
  expect_equal(pts$n_drawn, sum(parts))
  expect_equal(pts$status, "ok")
  # shapes by name, as GeomPoint translates them when it draws
  p2 <- ggplot2::ggplot(d[1:3, ], ggplot2::aes(.data$x, .data$y)) + ggplot2::geom_point(shape = "asterisk")
  lv <- gloss(p2, width = 4, height = 4, context = FALSE)$substrate$leaves
  expect_equal(lv$status[grepl("geom_point", lv$path)], "ok")
})
