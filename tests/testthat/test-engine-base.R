test_that("base engine captures single and multi-panel base plots with plot regions and tables", {
  cap <- gloss(function() {
    graphics::par(mfrow = c(1, 2))
    graphics::plot(
      datasets::mtcars$wt, datasets::mtcars$mpg,
      pch = 16, col = "steelblue", main = "Weight vs MPG"
    )
    graphics::abline(stats::lm(mpg ~ wt, data = datasets::mtcars), col = "firebrick")
    graphics::hist(datasets::mtcars$mpg, col = "tan", main = "MPG Distribution")
  })

  expect_true(is_gloss_capture(cap))
  expect_identical(cap$page$engine, "base")
  expect_identical(cap$page$draw_method, "function")
  expect_identical(cap$page$pages, 1L)

  # Two distinct panels (P1 left, P2 right)
  expect_equal(length(cap$ir$panels), 2L)
  expect_identical(vapply(cap$ir$panels, `[[`, character(1L), "panel_id"), c("P1", "P2"))
  expect_lt(unlist(cap$ir$panels[[1L]]$bbox_pt)[3L], unlist(cap$ir$panels[[2L]]$bbox_pt)[1L])

  # Both SVGs parse cleanly and scene.svg has leaf groups
  ns <- c(d1 = "http://www.w3.org/2000/svg")
  orig_doc <- xml2::read_xml(cap$svg$original$text)
  scene_doc <- xml2::read_xml(cap$svg$scene$text)
  expect_identical(xml2::xml_name(orig_doc), "svg")
  expect_gt(length(xml2::xml_find_all(scene_doc, "//d1:g[@data-gloss-leaf]", ns)), 0L)

  # Extracted plotXY and histogram rect tables linked 1:1
  expect_true(all(c("built_layer1", "built_layer2") %in% names(cap$tables)))
  expect_equal(nrow(gl_tables(cap, "built_layer1")), nrow(datasets::mtcars))

  linked <- cap$lineage[!is.na(cap$lineage$layer_id), ]
  expect_equal(nrow(linked), 2L)
  expect_identical(linked$cardinality, c("1:1", "1:1"))
  expect_identical(linked$n_rows[1L], 32L)
  expect_identical(linked$n_elements[1L], 32L)
})

test_that("base engine handles log scales, recordedplot, dense rasterization, and grid disambiguation", {
  # Log-scale base plot
  cap_log <- gloss(function() {
    graphics::plot(c(1, 10, 100), c(2, 20, 200), log = "xy", pch = 16)
  })
  expect_identical(cap_log$page$engine, "base")
  expect_identical(cap_log$ir$panels[[1L]]$x_trans, "log-10")
  expect_identical(cap_log$ir$panels[[1L]]$y_trans, "log-10")
  expect_gt(unlist(cap_log$ir$panels[[1L]]$x_domain)[2L], 50)

  # Recorded base plot
  tmp_pdf <- withr::local_tempfile(fileext = ".pdf")
  grDevices::pdf(tmp_pdf)
  grDevices::dev.control("enable")
  graphics::plot(1:5, (1:5)^2, pch = 19)
  rp <- grDevices::recordPlot()
  grDevices::dev.off()

  cap_rp <- gloss(rp)
  expect_identical(cap_rp$page$engine, "base")
  expect_identical(cap_rp$page$draw_method, "replayPlot")
  expect_equal(nrow(gl_tables(cap_rp, "built_layer1")), 5L)

  # Dense rasterization on base page
  cap_dense <- gloss(function() {
    graphics::plot(seq_len(40), seq_len(40), pch = 16)
  }, dense = 20)
  expect_equal(length(cap_dense$scene$dense_leaves), 1L)
  expect_equal(length(cap_dense$scene$rasters), 1L)
  expect_identical(cap_dense$scene$rasters[[1L]][1:4], as.raw(c(0x89, 0x50, 0x4e, 0x47)))

  # Function drawing grid graphics disambiguates cleanly to the grid engine
  cap_grid_fn <- gloss(function() {
    grid::grid.newpage()
    grid::grid.rect(width = 0.4, height = 0.4, name = "grid_only")
  })
  expect_identical(cap_grid_fn$page$engine, "grid")
})
