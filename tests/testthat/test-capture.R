test_that("the six input classes draw exactly what plain svglite draws", {
  skip_if_no("ggplot2", "patchwork", "gridGraphics", "ComplexHeatmap", "ggrepel")
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
    g <- ggExtra::ggMarginal(p, type = "histogram")
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
