test_that("heatmap engine captures ComplexHeatmap matrix, clustering orders, annotations, and slices", {
  skip_if_not_installed("ComplexHeatmap")

  set.seed(123)
  m <- matrix(
    stats::rnorm(24),
    nrow = 6,
    ncol = 4,
    dimnames = list(paste0("Gene", 1:6), paste0("Sample", 1:4))
  )
  ha <- ComplexHeatmap::HeatmapAnnotation(
    group = c("Ctrl", "Ctrl", "Treat", "Treat"),
    score = c(1.0, 2.5, 3.2, 4.8)
  )
  ht <- ComplexHeatmap::Heatmap(
    m,
    name = "expr",
    row_split = 2,
    column_split = 2,
    top_annotation = ha
  )

  cap <- gloss(ht, width = 7, height = 5)

  expect_true(is_gloss_capture(cap))
  expect_identical(cap$page$engine, "heatmap")
  expect_identical(cap$page$draw_method, "ComplexHeatmap::draw")

  # Matrix and annotation tables extracted
  expect_true("matrix_expr" %in% names(cap$tables))
  expect_true("anno_top_expr" %in% names(cap$tables))
  expect_identical(cap$tables$matrix_expr$key, "row_label")
  expect_equal(nrow(gl_tables(cap, "matrix_expr")), 6L)
  expect_equal(nrow(gl_tables(cap, "anno_top_expr")), 4L)

  # Clustering permutations captured in ir$orders
  expect_true("expr" %in% names(cap$ir$orders))
  ord <- cap$ir$orders$expr
  expect_identical(ord$nrow, 6L)
  expect_identical(ord$ncol, 4L)
  expect_equal(length(ord$row_order), 2L)
  expect_equal(length(ord$column_order), 2L)
  all_row_idx <- sort(unlist(lapply(ord$row_order, function(s) unlist(s$indices))))
  all_col_idx <- sort(unlist(lapply(ord$column_order, function(s) unlist(s$indices))))
  expect_identical(all_row_idx, 1:6)
  expect_identical(all_col_idx, 1:4)

  # Scales include main matrix ColorMapping + 2 annotation scales
  scale_fields <- vapply(cap$ir$scales, `[[`, character(1L), "field")
  expect_true(all(c("expr", "group", "score") %in% scale_fields))

  # 4 slice panels (2 x 2) linked 1:1 to matrix cells summing to 24 cells
  expect_equal(length(cap$ir$panels), 4L)
  linked <- cap$lineage[!is.na(cap$lineage$layer_id), ]
  expect_equal(nrow(linked), 4L)
  expect_true(all(linked$cardinality == "1:1"))
  expect_identical(sum(linked$n_rows), 24L)
  expect_identical(sum(linked$n_elements), 24L)
})

test_that("heatmap engine supports HeatmapList (ht1 + ht2) and open asset bundling", {
  skip_if_not_installed("ComplexHeatmap")

  set.seed(7)
  m1 <- matrix(stats::rnorm(12), 4, 3, dimnames = list(paste0("R", 1:4), paste0("A", 1:3)))
  m2 <- matrix(stats::rnorm(8), 4, 2, dimnames = list(paste0("R", 1:4), paste0("B", 1:2)))
  hl <- ComplexHeatmap::Heatmap(m1, name = "h1") + ComplexHeatmap::Heatmap(m2, name = "h2")

  cap <- gloss(hl)
  expect_identical(cap$page$engine, "heatmap")
  expect_true(all(c("matrix_h1", "matrix_h2") %in% names(cap$tables)))
  expect_true(all(c("h1", "h2") %in% names(cap$ir$orders)))
  expect_equal(length(cap$ir$panels), 2L)

  tmp <- withr::local_tempdir()
  map <- gl_asset_map(cap, path = file.path(tmp, "hm-map.json"))
  parsed <- jsonlite::fromJSON(file.path(tmp, "hm-map.json"), simplifyVector = FALSE)
  expect_true(all(c("h1", "h2") %in% names(parsed$ir$orders)))
})
