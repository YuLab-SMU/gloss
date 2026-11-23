# Real-world chart archetypes adapted from https://github.com/holtzy/R-graph-gallery
# Self-contained offline datasets ensure fast, deterministic CRAN-clean execution
# while exercising complex real-world geometries, scales, facets, and packaging
# across all built-in engines.

verify_bundle_integrity <- function(cap, bundle_dir) {
  out <- gl_asset_bundle(cap, path = bundle_dir, format = "dir")
  manifest <- jsonlite::fromJSON(file.path(out, "manifest.json"), simplifyVector = FALSE)
  expect_identical(manifest$capture_id, cap$capture_id)
  expect_gt(length(manifest$files), 3L)
  for (fent in manifest$files) {
    full <- file.path(out, fent$path)
    expect_true(file.exists(full), info = paste("missing bundle file:", fent$path))
    expect_identical(sha256_file(full), fent$sha256)
  }
  invisible(out)
}

test_that("R-graph-gallery #301: horizontal lollipop chart (segment + point + coord_flip)", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    item = factor(LETTERS[1:8], levels = LETTERS[8:1]),
    value = c(12, 29, 18, 45, 33, 21, 52, 38),
    stringsAsFactors = FALSE
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$item, y = .data$value)) +
    ggplot2::geom_segment(
      ggplot2::aes(x = .data$item, xend = .data$item, y = 0, yend = .data$value),
      colour = "#69b3a2", linewidth = 1
    ) +
    ggplot2::geom_point(colour = "#404080", size = 4) +
    ggplot2::coord_flip() +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Lollipop Chart (Gallery #301)", x = NULL, y = "Score")

  cap <- gloss(p)
  expect_identical(cap$page$engine, "ggplot")
  expect_true(cap$ir$panels[[1L]]$flipped)
  expect_equal(length(cap$ir$layers), 2L)
  expect_identical(vapply(cap$ir$layers, `[[`, character(1L), "geom"), c("GeomSegment", "GeomPoint"))

  linked <- cap$lineage[!is.na(cap$lineage$layer_id), ]
  expect_equal(nrow(linked), 2L)
  expect_identical(linked$cardinality, c("1:1", "1:1"))
  expect_identical(linked$n_elements, c(8L, 8L))

  tmp <- withr::local_tempdir()
  verify_bundle_integrity(cap, file.path(tmp, "gallery301.gloss"))
})

test_that("R-graph-gallery #299: circular barplot with polar coordinates and rotated labels", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    id = seq_len(10),
    label = paste0("G", seq_len(10)),
    value = c(25, 40, 18, 55, 32, 48, 22, 60, 35, 28),
    group = rep(c("East", "West"), each = 5),
    stringsAsFactors = FALSE
  )
  df$angle <- 90 - 360 * (df$id - 0.5) / nrow(df)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = factor(.data$id), y = .data$value, fill = .data$group)) +
    ggplot2::geom_col(alpha = 0.85) +
    ggplot2::geom_text(
      ggplot2::aes(y = .data$value + 5, label = .data$label, angle = .data$angle),
      size = 3
    ) +
    ggplot2::ylim(-20, 75) +
    ggplot2::coord_polar(start = 0) +
    ggplot2::scale_fill_manual(values = c(East = "#0072B2", West = "#E69F00")) +
    ggplot2::theme_void()

  cap <- gloss(p)
  expect_identical(cap$page$engine, "ggplot")
  expect_identical(cap$ir$panels[[1L]]$coord, "CoordPolar")

  scale_aes <- vapply(cap$ir$scales, `[[`, character(1L), "aesthetic")
  fill_sc <- cap$ir$scales[[match("fill", scale_aes)]]
  expect_identical(fill_sc$scale_type, "discrete")
  expect_equal(length(fill_sc$map), 2L)
  expect_true(all(df$label %in% cap$scene$elements$text))
})

test_that("R-graph-gallery #136 & #320: faceted stacked area and multi-scale bubble chart", {
  skip_if_not_installed("ggplot2")

  # Stacked area chart (N:1 polygons across facets)
  area_df <- expand.grid(year = 2020:2025, series = c("Alpha", "Beta", "Gamma"), region = c("North", "South"))
  area_df$val <- as.numeric(seq_len(nrow(area_df)) %% 7 + 3)

  p_area <- ggplot2::ggplot(area_df, ggplot2::aes(.data$year, .data$val, fill = .data$series)) +
    ggplot2::geom_area(alpha = 0.75) +
    ggplot2::facet_wrap(~ region) +
    ggplot2::scale_fill_manual(values = c(Alpha = "#264653", Beta = "#2a9d8f", Gamma = "#e9c46a"))

  cap_area <- gloss(p_area)
  expect_equal(length(cap_area$ir$panels), 2L)
  linked_area <- cap_area$lineage[!is.na(cap_area$lineage$layer_id), ]
  expect_gt(nrow(linked_area), 0L)
  expect_true(all(linked_area$cardinality %in% c("N:1", "stat_aggregated")))

  # Bubble chart (continuous size + discrete colour scales)
  p_bubble <- ggplot2::ggplot(
    datasets::mtcars,
    ggplot2::aes(x = .data$wt, y = .data$mpg, size = .data$hp, colour = factor(.data$cyl))
  ) +
    ggplot2::geom_point(alpha = 0.7) +
    ggplot2::scale_size(range = c(2, 10)) +
    ggplot2::theme_bw()

  cap_bubble <- gloss(p_bubble)
  scale_aes <- vapply(cap_bubble$ir$scales, `[[`, character(1L), "aesthetic")
  expect_true(all(c("x", "y", "size", "colour") %in% scale_aes))
})

test_that("R-graph-gallery #71: base R 2x2 split-screen multi-panel figure with polygon band", {
  cap <- gloss(function() {
    graphics::par(mfrow = c(2, 2), mar = c(4, 4, 2, 1))
    x <- seq(1, 10, length.out = 20)
    y <- 2 * x + sin(x) * 2
    # Panel 1: scatter + shaded confidence polygon + line
    graphics::plot(x, y, type = "n", main = "Confidence Band")
    graphics::polygon(c(x, rev(x)), c(y + 1.5, rev(y - 1.5)), col = "#dceef2", border = NA)
    graphics::lines(x, y, col = "#1d3557", lwd = 2)
    graphics::points(x, y, pch = 16, col = "#e63946")
    # Panel 2: histogram
    graphics::hist(datasets::iris$Sepal.Length, col = "#a8dadc", main = "Histogram")
    # Panel 3: boxplot
    graphics::boxplot(Sepal.Length ~ Species, data = datasets::iris, col = "#f4a261", main = "Boxplot")
    # Panel 4: barplot
    graphics::barplot(table(datasets::mtcars$cyl), col = "#2a9d8f", main = "Barplot")
  }, width = 8, height = 6)

  expect_identical(cap$page$engine, "base")
  expect_equal(length(cap$ir$panels), 4L)
  expect_gt(length(cap$tables), 2L)

  tmp <- withr::local_tempdir()
  verify_bundle_integrity(cap, file.path(tmp, "gallery71.gloss"))
})

test_that("R-graph-gallery composite story (patchwork) and clustered heatmap end-to-end bundles", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("patchwork")
  skip_if_not_installed("ComplexHeatmap")

  tmp <- withr::local_tempdir()

  # Composite patchwork story
  p_left <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg, colour = factor(.data$cyl))) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::theme_minimal()
  p_right <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(factor(.data$cyl), .data$mpg, fill = factor(.data$cyl))) +
    ggplot2::geom_boxplot(alpha = 0.7) +
    ggplot2::theme_minimal()

  cap_pw <- gloss((p_left | p_right) + patchwork::plot_annotation(title = "Gallery Composite"))
  expect_identical(cap_pw$page$engine, "patchwork")
  expect_equal(length(cap_pw$ir$panels), 2L)
  verify_bundle_integrity(cap_pw, file.path(tmp, "gallery_pw.gloss"))

  # Clustered expression heatmap with splits & annotation
  set.seed(2026)
  expr_mat <- matrix(stats::rnorm(30), nrow = 6, ncol = 5,
                     dimnames = list(paste0("G", 1:6), paste0("S", 1:5)))
  top_ha <- ComplexHeatmap::HeatmapAnnotation(
    condition = c("WT", "WT", "KO", "KO", "KO")
  )
  ht <- ComplexHeatmap::Heatmap(expr_mat, name = "zscore", row_split = 2, top_annotation = top_ha)
  cap_ht <- gloss(ht)
  expect_identical(cap_ht$page$engine, "heatmap")
  expect_true("zscore" %in% names(cap_ht$ir$orders))
  verify_bundle_integrity(cap_ht, file.path(tmp, "gallery_ht.gloss"))
})
