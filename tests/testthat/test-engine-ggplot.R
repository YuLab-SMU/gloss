test_that("ggplot engine captures single-panel scatter with scales, layers, and 1:1 lineage", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    patient_id = paste0("P", seq_len(6)),
    time = c(1, 2, 3, 4, 5, 6),
    survival = c(0.95, 0.88, 0.80, 0.62, 0.45, 0.30),
    cohort = factor(c("A", "A", "A", "B", "B", "B"), levels = c("A", "B")),
    stringsAsFactors = FALSE
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(.data$time, .data$survival, colour = .data$cohort, shape = .data$cohort)) +
    ggplot2::geom_point(size = 3) +
    ggplot2::scale_colour_manual(
      values = c("A" = "#0072B2", "B" = "#D55E00"),
      labels = c("Cohort A (n=3)", "Cohort B (n=3)")
    ) +
    ggplot2::labs(title = "Survival Overview", x = "Months", y = "Survival")

  cap <- gloss(p)

  expect_true(is_gloss_capture(cap))
  expect_identical(cap$page$engine, "ggplot")
  expect_identical(cap$page$draw_method, "ggplot_gtable")
  expect_identical(cap$page$pages, 1L)

  # Tables
  expect_true(all(c("raw", "built_layer1") %in% names(cap$tables)))
  expect_identical(cap$tables$raw$key, "patient_id")
  expect_equal(nrow(gl_tables(cap, "raw")), 6L)
  expect_equal(nrow(gl_tables(cap, "built_layer1")), 6L)

  # Panels IR
  expect_equal(length(cap$ir$panels), 1L)
  pan <- cap$ir$panels[[1L]]
  expect_identical(pan$panel_id, "P1")
  expect_identical(pan$coord, "CoordCartesian")
  expect_false(pan$flipped)
  expect_equal(length(pan$bbox_pt), 4L)
  expect_lt(unlist(pan$bbox_pt)[1L], unlist(pan$bbox_pt)[3L])
  expect_lt(unlist(pan$bbox_pt)[2L], unlist(pan$bbox_pt)[4L])

  # Layers IR
  expect_equal(length(cap$ir$layers), 1L)
  lyr <- cap$ir$layers[[1L]]
  expect_identical(lyr$geom, "GeomPoint")
  expect_identical(lyr$stat, "StatIdentity")
  expect_identical(lyr$aes$x, "time")
  expect_identical(lyr$aes$y, "survival")
  expect_identical(lyr$aes$colour, "cohort")
  expect_identical(lyr$raw_table, "raw")
  expect_identical(lyr$built_table, "built_layer1")

  # Scales IR (x, y, colour, shape)
  scale_aes <- vapply(cap$ir$scales, `[[`, character(1L), "aesthetic")
  expect_true(all(c("x", "y", "colour", "shape") %in% scale_aes))
  col_sc <- cap$ir$scales[[match("colour", scale_aes)]]
  expect_identical(col_sc$scale_type, "discrete")
  expect_identical(col_sc$field, "cohort")
  expect_equal(length(col_sc$map), 2L)
  expect_identical(col_sc$map[[1L]]$domain, "A")
  expect_identical(col_sc$map[[1L]]$value, "#0072B2")
  expect_identical(col_sc$map[[1L]]$label, "Cohort A (n=3)")

  # Lineage links geom_point leaf 1:1 with built_layer1
  linked <- cap$lineage[!is.na(cap$lineage$layer_id), ]
  expect_equal(nrow(linked), 1L)
  expect_identical(linked$panel_id, "P1")
  expect_identical(linked$layer_id, 1L)
  expect_identical(linked$table_id, "built_layer1")
  expect_identical(linked$cardinality, "1:1")
  expect_identical(linked$n_rows, 6L)
  expect_identical(linked$n_elements, 6L)
})

test_that("ggplot engine handles facets, multi-layer lineage, and gl_query(panel = ...)", {
  skip_if_not_installed("ggplot2")

  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg, colour = factor(.data$cyl))) +
    ggplot2::geom_point() +
    ggplot2::geom_line() +
    ggplot2::facet_wrap(~ am)

  cap <- gloss(p)

  expect_equal(length(cap$ir$panels), 2L)
  expect_identical(vapply(cap$ir$panels, `[[`, character(1L), "panel_id"), c("P1", "P2"))
  expect_identical(cap$ir$panels[[1L]]$facet_vars$am, 0)
  expect_identical(cap$ir$panels[[2L]]$facet_vars$am, 1)

  # P1 is to the left of P2 on the page
  expect_lt(unlist(cap$ir$panels[[1L]]$bbox_pt)[3L], unlist(cap$ir$panels[[2L]]$bbox_pt)[1L])

  # Layer 1 (GeomPoint): 1:1 with 19 rows in P1 and 13 rows in P2
  l1 <- cap$lineage[!is.na(cap$lineage$layer_id) & cap$lineage$layer_id == 1L, ]
  expect_equal(nrow(l1), 2L)
  expect_identical(l1$cardinality, c("1:1", "1:1"))
  expect_identical(l1$n_rows, c(19L, 13L))
  expect_identical(l1$n_elements, c(19L, 13L))

  # Layer 2 (GeomLine): N:1 grouped lines
  l2 <- cap$lineage[!is.na(cap$lineage$layer_id) & cap$lineage$layer_id == 2L, ]
  expect_gt(nrow(l2), 0L)
  expect_true(all(l2$cardinality == "N:1"))

  # gl_query by panel cleanly isolates P2
  q2 <- gl_query(cap, panel = "P2")
  expect_true(all(q2$lineage$panel_id == "P2"))
  expect_true("built_layer1" %in% names(q2$tables))
})

test_that("ggplot engine captures stochastic geom_jitter in a single build", {
  skip_if_not_installed("ggplot2")

  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(factor(.data$cyl), .data$mpg)) +
    ggplot2::geom_jitter(width = 0.3, height = 0.5)

  cap <- gloss(p)
  expect_identical(cap$page$pages, 1L)

  # original.svg and scene.svg share identical circle centers (zero redraw)
  ns <- c(d1 = "http://www.w3.org/2000/svg")
  orig_c <- xml2::xml_find_all(xml2::read_xml(cap$svg$original$text), "//d1:circle", ns)
  scene_c <- xml2::xml_find_all(xml2::read_xml(cap$svg$scene$text), "//d1:circle", ns)
  expect_equal(length(orig_c), nrow(datasets::mtcars))
  expect_identical(xml2::xml_attr(orig_c, "cx"), xml2::xml_attr(scene_c, "cx"))
  expect_identical(xml2::xml_attr(orig_c, "cy"), xml2::xml_attr(scene_c, "cy"))

  # Built layer 1 jittered x coordinates linearly match SVG circle cx coordinates
  b1 <- gl_tables(cap, "built_layer1")
  linked <- cap$lineage[!is.na(cap$lineage$layer_id), ]
  el <- cap$scene$elements[!is.na(cap$scene$elements$leaf_id) & cap$scene$elements$leaf_id == linked$leaf_id[[1L]], ]
  cx <- (el$bbox_x0 + el$bbox_x1) / 2
  expect_gt(stats::cor(b1$x, cx), 0.9999)
})

test_that("ggplot engine handles continuous scales, log10 trans, coord_flip, coord_polar, and stats", {
  skip_if_not_installed("ggplot2")

  # Continuous colour + log10 + coord_flip
  p_flip <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg, colour = .data$hp)) +
    ggplot2::geom_point() +
    ggplot2::scale_x_log10() +
    ggplot2::coord_flip()

  cap_flip <- gloss(p_flip)
  expect_true(cap_flip$ir$panels[[1L]]$flipped)
  expect_identical(cap_flip$ir$panels[[1L]]$coord, "CoordFlip")
  expect_identical(cap_flip$ir$panels[[1L]]$x_trans, "log-10")

  scale_aes <- vapply(cap_flip$ir$scales, `[[`, character(1L), "aesthetic")
  col_sc <- cap_flip$ir$scales[[match("colour", scale_aes)]]
  expect_identical(col_sc$scale_type, "continuous")
  expect_gt(length(col_sc$map), 0L)
  # All sampled continuous colour values are valid hex colors (not out-of-range grey50)
  mapped_cols <- vapply(col_sc$map, `[[`, character(1L), "value")
  expect_true(all(grepl("^#", mapped_cols)))

  # StatCount / GeomBar -> stat_aggregated
  p_bar <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(factor(.data$cyl))) +
    ggplot2::geom_bar()
  cap_bar <- gloss(p_bar)
  bar_lin <- cap_bar$lineage[!is.na(cap_bar$lineage$layer_id), ]
  expect_identical(bar_lin$cardinality, "stat_aggregated")

  # CoordPolar
  p_polar <- p_bar + ggplot2::coord_polar()
  cap_polar <- gloss(p_polar)
  expect_identical(cap_polar$ir$panels[[1L]]$coord, "CoordPolar")
})

test_that("ggplot engine handles layer-specific data, custom print.* fallback, and full asset bundling", {
  skip_if_not_installed("ggplot2")

  # Layer-specific override data
  df2 <- data.frame(wt = c(2, 4), mpg = c(30, 15))
  p_ov <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) +
    ggplot2::geom_point() +
    ggplot2::geom_point(data = df2, colour = "red", size = 4)

  cap_ov <- gloss(p_ov)
  expect_true(all(c("raw", "raw_layer2", "built_layer1", "built_layer2") %in% names(cap_ov$tables)))
  expect_identical(cap_ov$ir$layers[[1L]]$raw_table, "raw")
  expect_identical(cap_ov$ir$layers[[2L]]$raw_table, "raw_layer2")

  # Bundle round-trip on a real ggplot capture
  tmp <- withr::local_tempdir()
  bundle_dir <- gl_asset_bundle(cap_ov, path = file.path(tmp, "mtcars.gloss"))
  expect_true(file.exists(file.path(bundle_dir, "asset-map.json")))
  expect_true(file.exists(file.path(bundle_dir, "tables/raw.csv")))
  expect_true(file.exists(file.path(bundle_dir, "tables/raw_layer2.csv")))
  expect_true(file.exists(file.path(bundle_dir, "tables/built_layer1.csv")))
  expect_true(file.exists(file.path(bundle_dir, "tables/built_layer2.csv")))

  # Custom print.* subclass fallback records raw + scene neutrally without error
  p_custom <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) +
    ggplot2::geom_point()
  class(p_custom) <- c("mock_custom_gg", class(p_custom))

  registerS3method(
    "print", "mock_custom_gg",
    function(x, ...) {
      class(x) <- setdiff(class(x), "mock_custom_gg")
      print(x, ...)
    },
    envir = asNamespace("base")
  )
  withr::defer({
    s3tbl <- get(".__S3MethodsTable__.", envir = asNamespace("base"))
    if (exists("print.mock_custom_gg", envir = s3tbl, inherits = FALSE)) {
      rm("print.mock_custom_gg", envir = s3tbl)
    }
  })

  cap_cust <- gloss(p_custom)
  expect_identical(cap_cust$page$draw_method, "print.mock_custom_gg")
  expect_true("raw" %in% names(cap_cust$tables))
  expect_gt(nrow(cap_cust$scene$leaves), 0L)
})
