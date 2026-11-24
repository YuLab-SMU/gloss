test_that("ggrepel dynamic makeContent() labels and leader lines are captured neutrally", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ggrepel")

  df <- datasets::mtcars[1:10, , drop = FALSE]
  df$car <- rownames(df)

  p <- ggplot2::ggplot(df, ggplot2::aes(.data$wt, .data$mpg, label = .data$car)) +
    ggplot2::geom_point() +
    ggrepel::geom_text_repel(seed = 42, min.segment.length = 0) +
    ggrepel::geom_label_repel(
      data = df[1:3, , drop = FALSE],
      ggplot2::aes(.data$wt, .data$mpg, label = .data$car),
      seed = 42,
      min.segment.length = 0
    )

  cap <- gloss(p, width = 7, height = 5)
  expect_true(is_gloss_capture(cap))
  expect_identical(cap$page$engine, "ggplot")

  els <- cap$scene$elements
  # Repelled car labels and leader-line segments appear in elements
  expect_true(all(df$car %in% els$text))
  expect_true(any(els$tag %in% c("line", "polyline")))

  # Lineage neutrally records layer 1 (1:1 points) and layers 2 & 3 (repelled grobs)
  lin <- cap$lineage[!is.na(cap$lineage$layer_id), ]
  expect_true(all(1:3 %in% lin$layer_id))
  expect_identical(lin$cardinality[lin$layer_id == 1L], "1:1")

  bdir <- gl_asset_bundle(cap, path = withr::local_tempdir())
  expect_true(file.exists(file.path(bdir, "scene", "elements.json")))
  expect_true(file.exists(file.path(bdir, "tables", "built_layer2.csv")))
})

test_that("sf geom_sf polygons with holes and CoordSf serialize cleanly to WKT CSV and Schema", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("sf")

  outer <- matrix(c(0, 0, 10, 0, 10, 10, 0, 10, 0, 0), ncol = 2, byrow = TRUE)
  hole <- matrix(c(3, 3, 3, 7, 7, 7, 7, 3, 3, 3), ncol = 2, byrow = TRUE)
  poly1 <- sf::st_polygon(list(outer, hole))
  poly2 <- sf::st_polygon(list(matrix(c(12, 1, 18, 1, 18, 9, 12, 9, 12, 1), ncol = 2, byrow = TRUE)))

  gdf <- sf::st_sf(
    region = c("Atoll", "Island"),
    score = c(2.4, 5.8),
    geometry = sf::st_sfc(poly1, poly2, crs = 4326)
  )

  p <- ggplot2::ggplot(gdf) +
    ggplot2::geom_sf(ggplot2::aes(fill = .data$score))

  cap <- gloss(p, width = 6, height = 4)
  expect_identical(cap$page$engine, "ggplot")
  expect_identical(cap$ir$panels[[1L]]$coord, "CoordSf")

  # Polygon <path> elements have finite, non-degenerate bounding boxes
  path_els <- cap$scene$elements[cap$scene$elements$tag == "path", ]
  expect_gte(nrow(path_els), 2L)
  expect_true(all(is.finite(path_els$bbox_x0) & path_els$bbox_x1 > path_els$bbox_x0))
  expect_true(all(is.finite(path_els$bbox_y0) & path_els$bbox_y1 > path_els$bbox_y0))

  # sfc geometry serializes cleanly to WKT in CSV and records geometry_wkt + CRS in schema.json
  bdir <- gl_asset_bundle(cap, path = withr::local_tempdir())
  raw_csv <- utils::read.csv(file.path(bdir, "tables", "raw.csv"), stringsAsFactors = FALSE)
  expect_equal(nrow(raw_csv), 2L)
  expect_match(raw_csv$geometry[[1L]], "^POLYGON")

  schema <- jsonlite::read_json(file.path(bdir, "tables", "schema.json"))
  geom_col <- Filter(function(c) identical(c$name, "geometry"), schema$tables$raw$columns)[[1L]]
  expect_identical(geom_col$type, "geometry_wkt")
  expect_match(geom_col$crs, "4326")
})

test_that("ggtree phylogenetic trees capture topology branches, tip labels, and bundle assets", {
  skip_if_not_installed("ggtree")
  skip_if_not_installed("ape")

  tr <- ape::read.tree(text = "((Human:0.2,Chimp:0.2):0.3,(Mouse:0.4,Rat:0.4):0.1);")
  p_tree <- ggtree::ggtree(tr) + ggtree::geom_tiplab()

  cap <- gloss(p_tree, width = 6, height = 4)
  expect_true(is_gloss_capture(cap))
  expect_identical(cap$page$engine, "ggplot")
  expect_equal(length(cap$ir$panels), 1L)

  txts <- cap$scene$elements$text[!is.na(cap$scene$elements$text)]
  expect_true(all(c("Human", "Chimp", "Mouse", "Rat") %in% trimws(txts)))

  bdir <- gl_asset_bundle(cap, path = withr::local_tempdir())
  expect_true(file.exists(file.path(bdir, "asset-map.json")))
  expect_true(file.exists(file.path(bdir, "tables", "raw.csv")))
})

test_that("ggbreak broken-axis plots capture composite print.ggbreak sub-panels neutrally", {
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ggbreak")

  df <- data.frame(
    sample = factor(paste0("S", 1:6), levels = paste0("S", 1:6)),
    abundance = c(2, 3.5, 4, 5, 110, 125),
    stringsAsFactors = FALSE
  )
  p_brk <- ggplot2::ggplot(df, ggplot2::aes(.data$sample, .data$abundance)) +
    ggplot2::geom_col(fill = "#2B6CB0") +
    ggbreak::scale_y_break(c(8, 95))

  cap <- gloss(p_brk, width = 6, height = 5)
  expect_true(is_gloss_capture(cap))
  expect_identical(cap$page$engine, "ggplot")
  expect_identical(cap$page$draw_method, "print.ggbreak")
  expect_identical(cap$page$pages, 1L)

  # Both lower and upper broken sub-panel bar leaves are preserved with distinct clip rects
  bar_leaves <- cap$scene$leaves[grepl("^geom_rect", cap$scene$leaves$grob_name), ]
  expect_gte(nrow(bar_leaves), 2L)
  expect_gte(length(unique(bar_leaves$clip_id)), 2L)

  bdir <- gl_asset_bundle(cap, path = withr::local_tempdir())
  expect_true(file.exists(file.path(bdir, "tables", "raw.csv")))
  expect_true(file.exists(file.path(bdir, "tables", "built_layer1.csv")))
})
