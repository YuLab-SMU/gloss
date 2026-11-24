test_that("gloss captures a grid grobTree with dual SVG, viewport probes, and elements", {
  devs_before <- grDevices::dev.list()

  vp <- grid::viewport(
    x = 0.5, y = 0.5, width = 0.6, height = 0.6,
    xscale = c(0, 10), yscale = c(-5, 5),
    name = "panel-1-1"
  )
  g <- grid::grobTree(
    grid::rectGrob(name = "bg", gp = grid::gpar(fill = "#f0f0f0", col = "#333333")),
    grid::pointsGrob(
      x = grid::unit(c(2, 5, 8), "native"),
      y = grid::unit(c(-2, 0, 3), "native"),
      pch = 16,
      name = "pts",
      gp = grid::gpar(col = "#0072B2")
    ),
    grid::linesGrob(
      x = grid::unit(c(2, 8), "native"),
      y = grid::unit(c(-2, 3), "native"),
      name = "trend"
    ),
    grid::textGrob("Sample Title", x = 0.5, y = 0.9, rot = 15, name = "title"),
    vp = vp
  )

  cap <- gloss(g, width = 7, height = 5)

  expect_true(is_gloss_capture(cap))
  expect_identical(cap$page$engine, "grid")
  expect_identical(cap$page$draw_method, "grid.draw")
  expect_equal(cap$page$width_in, 7)
  expect_equal(cap$page$height_in, 5)
  expect_equal(cap$page$width_pt, 504)
  expect_equal(cap$page$height_pt, 360)
  expect_identical(grDevices::dev.list(), devs_before)

  # Both SVGs are well-formed XML and differ (scene.svg injects leaf groups)
  orig_doc <- xml2::read_xml(cap$svg$original$text)
  scene_doc <- xml2::read_xml(cap$svg$scene$text)
  expect_identical(xml2::xml_name(orig_doc), "svg")
  expect_identical(xml2::xml_name(scene_doc), "svg")
  expect_false(identical(cap$svg$original$sha256, cap$svg$scene$sha256))

  # Leaf groups are inlined with stable id="L..." and no dangling <use>
  ns <- c(d1 = "http://www.w3.org/2000/svg")
  expect_equal(length(xml2::xml_find_all(scene_doc, "//d1:use", ns)), 0L)
  leaf_nodes <- xml2::xml_find_all(scene_doc, "//d1:g[@data-gloss-leaf]", ns)
  expect_equal(length(leaf_nodes), 4L)
  expect_identical(xml2::xml_attr(leaf_nodes, "id"), c("L001", "L002", "L003", "L004"))

  # Probe viewport coordinates and native scales match exact geometry
  leaves <- cap$scene$leaves
  expect_equal(nrow(leaves), 4L)
  expect_identical(leaves$grob_name, c("bg", "pts", "trend", "title"))
  expect_true(all(leaves$layout_slot == "panel-1-1"))
  expect_equal(leaves$bbox_x0, rep(100.8, 4L), tolerance = 0.01)
  expect_equal(leaves$bbox_x1, rep(403.2, 4L), tolerance = 0.01)
  expect_equal(leaves$bbox_y0, rep(72.0, 4L), tolerance = 0.01)
  expect_equal(leaves$bbox_y1, rep(288.0, 4L), tolerance = 0.01)
  expect_equal(leaves$xscale0, rep(0, 4L))
  expect_equal(leaves$xscale1, rep(10, 4L))
  expect_equal(leaves$yscale0, rep(-5, 4L))
  expect_equal(leaves$yscale1, rep(5, 4L))
  expect_identical(leaves$n_elements, c(1L, 3L, 1L, 1L))

  # Elements preserve text, tags, styles, and bboxes
  elems <- cap$scene$elements
  pts_el <- elems[!is.na(elems$leaf_id) & elems$leaf_id == "L002", ]
  expect_equal(nrow(pts_el), 3L)
  expect_true(all(pts_el$tag == "circle"))
  expect_identical(pts_el$ordinal, 1:3)

  txt_el <- elems[!is.na(elems$leaf_id) & elems$leaf_id == "L004", ]
  expect_equal(nrow(txt_el), 1L)
  expect_identical(txt_el$text, "Sample Title")
  expect_true(all(is.finite(c(txt_el$bbox_x0, txt_el$bbox_y0, txt_el$bbox_x1, txt_el$bbox_y1))))

  # Lineage aligns 1-to-1 with leaves
  expect_equal(nrow(cap$lineage), 4L)
  expect_identical(cap$lineage$leaf_id, leaves$leaf_id)
  expect_identical(cap$lineage$n_elements, leaves$n_elements)
})

test_that("gloss never re-evaluates stochastic plotting functions between original and scene SVG", {
  counter <- new.env(parent = emptyenv())
  counter$n <- 0L
  stochastic_fn <- function() {
    counter$n <- counter$n + 1L
    grid::grid.newpage()
    grid::grid.points(
      x = stats::runif(8, 0.1, 0.9),
      y = stats::runif(8, 0.1, 0.9),
      pch = 16,
      name = "rand_pts"
    )
  }

  cap <- gloss(stochastic_fn)
  expect_identical(counter$n, 1L)

  ns <- c(d1 = "http://www.w3.org/2000/svg")
  orig_circles <- xml2::xml_find_all(xml2::read_xml(cap$svg$original$text), "//d1:circle", ns)
  scene_circles <- xml2::xml_find_all(xml2::read_xml(cap$svg$scene$text), "//d1:circle", ns)

  expect_equal(length(orig_circles), 8L)
  expect_equal(length(scene_circles), 8L)
  expect_identical(xml2::xml_attr(orig_circles, "cx"), xml2::xml_attr(scene_circles, "cx"))
  expect_identical(xml2::xml_attr(orig_circles, "cy"), xml2::xml_attr(scene_circles, "cy"))
})

test_that("gloss rasterizes dense non-text leaves and rewrites scene.svg cleanly", {
  f <- function() {
    grid::grid.newpage()
    grid::pushViewport(grid::viewport(width = 0.8, height = 0.8, name = "dense_vp"))
    grid::grid.points(
      x = seq(0.05, 0.95, length.out = 40),
      y = seq(0.05, 0.95, length.out = 40),
      pch = 16,
      name = "dense_pts"
    )
    grid::grid.text(
      label = paste0("T", seq_len(25)),
      x = seq(0.05, 0.95, length.out = 25),
      y = rep(0.5, 25),
      name = "many_labels"
    )
    grid::popViewport()
  }

  cap <- gloss(f, dense = 20)

  # Only the non-text leaf is rasterized; text leaf stays vector
  expect_identical(cap$scene$dense_leaves, "L001")
  expect_identical(cap$scene$leaves$dense, c(TRUE, FALSE))
  expect_identical(cap$scene$leaves$n_elements, c(40L, 25L))
  expect_true("L001" %in% names(cap$scene$rasters))
  expect_true(is.raw(cap$scene$rasters$L001))
  expect_gt(length(cap$scene$rasters$L001), 100L)
  # PNG magic header: 89 50 4E 47
  expect_identical(cap$scene$rasters$L001[1:4], as.raw(c(0x89, 0x50, 0x4e, 0x47)))

  # Original SVG keeps all 40 circles untouched; scene.svg replaces L001 with <image>
  ns <- c(d1 = "http://www.w3.org/2000/svg")
  orig_doc <- xml2::read_xml(cap$svg$original$text)
  scene_doc <- xml2::read_xml(cap$svg$scene$text)
  expect_equal(length(xml2::xml_find_all(orig_doc, "//d1:circle", ns)), 40L)
  expect_equal(length(xml2::xml_find_all(scene_doc, "//d1:circle", ns)), 0L)

  img <- xml2::xml_find_first(scene_doc, "//d1:g[@id='L001']/d1:image", ns)
  expect_identical(xml2::xml_attr(img, "href"), "rasters/L001.png")
})

test_that("gloss handles clipGrob, polygon, path, multi-name grobs, and recordedplot", {
  draw_shapes <- function() {
    grid::grid.newpage()
    grid::grid.draw(grid::clipGrob(x = 0.5, y = 0.5, width = 0.5, height = 0.5))
    grid::grid.polygon(
      x = c(0.2, 0.8, 0.5),
      y = c(0.2, 0.2, 0.8),
      name = c("poly_a", "poly_b")
    )
    grid::grid.path(
      x = c(0.1, 0.9, 0.9, 0.1),
      y = c(0.1, 0.1, 0.9, 0.9),
      name = "outline"
    )
    grid::grid.draw(grid::nullGrob(name = "empty_null"))
  }

  cap <- gloss(draw_shapes)
  # clipGrob and nullGrob are not wrapped as leaves; multi-name grob normalized to scalar
  expect_equal(nrow(cap$scene$leaves), 2L)
  expect_identical(cap$scene$leaves$grob_name, c("poly_a", "outline"))

  # Recorded grid plot can be captured twice without mutating caller object
  tmp_pdf <- withr::local_tempfile(fileext = ".pdf")
  grDevices::pdf(tmp_pdf)
  grDevices::dev.control("enable")
  grid::grid.newpage()
  grid::grid.circle(x = 0.5, y = 0.5, r = 0.25, name = "rec_circ")
  rp <- grDevices::recordPlot()
  grDevices::dev.off()

  cap_rp1 <- gloss(rp)
  cap_rp2 <- gloss(rp)
  expect_identical(cap_rp1$capture_id, cap_rp2$capture_id)
  expect_identical(cap_rp1$scene$leaves$grob_name, "rec_circ")
})

test_that("gloss captures a ggplot gtable cleanly via the grid engine", {
  skip_if_not_installed("ggplot2")

  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) +
    ggplot2::geom_point() +
    ggplot2::labs(title = "Fuel Economy")
  gt <- withr::with_pdf(NULL, ggplot2::ggplotGrob(p))

  cap <- gloss(gt)
  expect_true(is_gloss_capture(cap))
  expect_identical(cap$page$engine, "grid")
  expect_gt(nrow(cap$scene$leaves), 5L)
  expect_true(any(cap$scene$leaves$layout_slot == "panel"))
  expect_true("Fuel Economy" %in% cap$scene$elements$text)
})

test_that("gloss validates arguments and allows custom engine capture_fn", {
  withr::defer(reset_engine_registry(register_builtins = TRUE))

  expect_error(gloss(grid::rectGrob(), width = -1), "positive finite")
  expect_error(gloss(grid::rectGrob(), dense = 0), "positive number")

  gl_register_engine(
    name = "custom_box",
    classes = "custom_box_obj",
    capture_fn = function(x, ctx) {
      grid::grid.newpage()
      grid::grid.rect(width = x$w, height = x$h, name = "custom_rect")
      sc <- ctx$capture_grid(draw_method = "custom_box_draw")
      list(
        scene = sc,
        tables = list(raw = data.frame(w = x$w, h = x$h))
      )
    }
  )

  obj <- structure(list(w = 0.5, h = 0.5), class = "custom_box_obj")
  cap <- gloss(obj)
  expect_identical(cap$page$engine, "custom_box")
  expect_identical(cap$page$draw_method, "custom_box_draw")
  expect_identical(names(cap$tables), "raw")
  expect_identical(cap$scene$leaves$grob_name, "custom_rect")
})

test_that("gloss aligns nested user groupGrob, parses SVG path commands accurately, and explains mixed pages", {
  # Nested user groupGrob (GridGroup) must not shift subsequent leaf attributions
  g_grp <- grid::grobTree(
    grid::groupGrob(grid::circleGrob(r = 0.2), name = "user_grp"),
    grid::rectGrob(width = 0.3, height = 0.3, name = "after_grp")
  )
  cap_grp <- expect_no_warning(gloss(g_grp))
  expect_identical(cap_grp$scene$leaves$grob_name, c("user_grp", "after_grp"))
  expect_identical(cap_grp$scene$leaves$n_elements, c(1L, 1L))
  el_l1 <- cap_grp$scene$elements[!is.na(cap_grp$scene$elements$leaf_id) & cap_grp$scene$elements$leaf_id == "L001", ]
  el_l2 <- cap_grp$scene$elements[!is.na(cap_grp$scene$elements$leaf_id) & cap_grp$scene$elements$leaf_id == "L002", ]
  expect_identical(el_l1$tag, "circle")
  expect_identical(el_l2$tag, "rect")

  # SVG path bbox parser handles V/H, relative m/h/v, cubic C, and arc A cleanly
  expect_equal(parse_single_path_bbox("M 10 20 V 80 H 50 L 30 40 Z"), c(10, 50, 20, 80))
  expect_equal(parse_single_path_bbox("m 10 20 v 60 h 40 z"), c(10, 50, 20, 80))
  expect_equal(parse_single_path_bbox("M 0 0 A 25 25 0 0 1 50 30"), c(0, 50, 0, 30))
  expect_equal(parse_single_path_bbox("M 0 0 c 10 5 20 15 30 40"), c(0, 30, 0, 40))

  # Mixed base + grid page emits a clear diagnostic error
  expect_error(
    gloss(function() {
      graphics::plot(1:5, 1:5)
      grid::grid.text("overlay")
    }),
    "mixed base graphics and grid graphics"
  )
})

test_that("Schema v1.0 captures typography, opacity, clip-paths, guide-box slots, and stat roles", {
  skip_if_not_installed("ggplot2")

  p <- ggplot2::ggplot(
    datasets::mtcars,
    ggplot2::aes(factor(.data$cyl), .data$mpg, colour = factor(.data$cyl))
  ) +
    ggplot2::geom_boxplot(alpha = 0.4) +
    ggplot2::stat_summary(fun.data = ggplot2::mean_se, geom = "errorbar", width = 0.2) +
    ggplot2::labs(colour = "Cylinders") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  cap <- gloss(p)
  els <- cap$scene$elements
  lvs <- cap$scene$leaves

  # T1.1: Typography, stroke_width, and opacity
  txts <- els[els$tag == "text", ]
  expect_gt(nrow(txts), 0L)
  expect_true(all(is.finite(txts$font_size) & txts$font_size > 0))
  expect_true(any(!is.na(txts$font_family) & nzchar(txts$font_family)))
  expect_true(all(txts$text_anchor %in% c("start", "middle", "end")))
  rot_x <- txts[txts$text %in% c("4", "6", "8"), ]
  expect_true(any(abs(rot_x$rotation - (-45)) < 0.01))
  expect_true(any(abs(els$opacity - 0.4) < 0.02))
  expect_true(any(is.finite(els$stroke_width) & els$stroke_width > 0))

  # T1.2: Clip-path rects on both leaves and elements (ggplot + base)
  panel_leaves <- lvs[lvs$layout_slot == "panel", ]
  expect_gt(nrow(panel_leaves), 0L)
  expect_true(all(!is.na(panel_leaves$clip_id)))
  expect_true(all(is.finite(panel_leaves$clip_x0) & panel_leaves$clip_x1 > panel_leaves$clip_x0))
  expect_true(all(is.finite(panel_leaves$clip_y0) & panel_leaves$clip_y1 > panel_leaves$clip_y0))
  expect_true(any(!is.na(els$clip_id) & is.finite(els$clip_x1)))

  cap_base <- gloss(function() graphics::plot(1:5, 1:5))
  expect_true(any(!is.na(cap_base$scene$leaves$clip_id) & is.finite(cap_base$scene$leaves$clip_x1)))

  # T1.3: Legend title ("Cylinders") and inner legend background resolve to guide-box*, not "title"/"background"
  cyl_lbl <- els[!is.na(els$text) & els$text == "Cylinders", ]
  expect_gte(nrow(cyl_lbl), 1L)
  cyl_slot <- lvs$layout_slot[match(cyl_lbl$leaf_id[[1L]], lvs$leaf_id)]
  expect_match(cyl_slot, "^guide-box")
  guide_vp_leaves <- lvs[grepl("guide-box", lvs$vp_path, fixed = TRUE), ]
  expect_gt(nrow(guide_vp_leaves), 0L)
  expect_true(all(grepl("^guide-box", guide_vp_leaves$layout_slot)))

  # T1.4: Stat column role semantics in ir$layers, asset-map.json, and tables/schema.json
  expect_identical(cap$ir$layers[[1L]]$stat_columns$middle, "median")
  expect_identical(cap$ir$layers[[1L]]$stat_columns$lower, "quartile_low")
  expect_identical(cap$ir$layers[[1L]]$stat_columns$upper, "quartile_high")
  expect_identical(cap$ir$layers[[2L]]$stat_columns$ymin, "interval_low")
  expect_identical(cap$ir$layers[[2L]]$stat_columns$ymax, "interval_high")

  bdir <- gl_asset_bundle(cap, path = withr::local_tempdir())
  schema <- jsonlite::read_json(file.path(bdir, "tables", "schema.json"))
  b1_cols <- schema$tables$built_layer1$columns
  mid_col <- Filter(function(c) identical(c$name, "middle"), b1_cols)[[1L]]
  expect_identical(mid_col$stat_role, "median")
})
