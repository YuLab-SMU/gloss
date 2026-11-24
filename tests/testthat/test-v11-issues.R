test_that("ISS-ASSET-01 & ISS-ASSET-06: row bridges, boxplot part_roles, stat_params, and row_accounting work", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    sample_id = paste0("S", 1:8),
    x = c(1, 5, NA, 10, 500, 15, 20, 25),
    y = c(2, 4, 6, 8, 10, 12, 14, 16),
    grp = factor(c("A", "A", "A", "B", "B", "B", "A", "B"), levels = c("A", "B")),
    stringsAsFactors = FALSE
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(.data$x, .data$y, colour = .data$grp)) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_smooth(method = "lm", formula = y ~ x, level = 0.90) +
    ggplot2::scale_x_continuous(limits = c(0, 100))

  cap <- suppressWarnings(gloss(p, width = 7, height = 5))

  # ISS-ASSET-06: row_accounting detects 1 NA drop (row 3) + 1 OOB drop (row 5)
  acc1 <- cap$ir$layers[[1L]]$row_accounting
  expect_identical(acc1$n_raw, 8L)
  expect_identical(acc1$n_built, 6L)
  expect_identical(acc1$n_dropped_na, 1L)
  expect_identical(acc1$n_dropped_oob, 1L)
  expect_identical(unlist(acc1$dropped_raw_row_ids), c(3L, 5L))

  # ISS-ASSET-06: stat_params & geom_params (method, level, formula) captured cleanly
  p2 <- cap$ir$layers[[2L]]$params
  expect_identical(p2$method, "lm")
  expect_equal(p2$level, 0.90)
  expect_identical(p2$formula, "y ~ x")

  # ISS-ASSET-01: built_layer1 carries _raw_row_id, elements carry exact surviving built_row_id (skipping 3 & 5)
  b1 <- gl_tables(cap, "built_layer1")
  expect_identical(b1[["_raw_row_id"]], 1:8)

  pt_lid <- cap$lineage$leaf_id[!is.na(cap$lineage$layer_id) & cap$lineage$layer_id == 1L][[1L]]
  pt_els <- cap$scene$elements[!is.na(cap$scene$elements$leaf_id) & cap$scene$elements$leaf_id == pt_lid, ]
  expect_equal(nrow(pt_els), 6L)
  expect_identical(sort(pt_els$built_row_id), c(1L, 2L, 4L, 6L, 7L, 8L))
  expect_true(all(pt_els$part_role == "point"))

  # Composite 1:M boxplot part_roles (box, median, whisker) + group_index bridge back to raw rows
  p_box <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(factor(.data$cyl), .data$mpg, fill = factor(.data$cyl))) +
    ggplot2::geom_boxplot() +
    ggplot2::stat_summary(fun.data = ggplot2::mean_se, geom = "errorbar", width = 0.2)

  cap_box <- gloss(p_box)
  expect_identical(cap_box$ir$layers[[2L]]$params$fun.data, "mean_se")
  expect_true("built_layer1" %in% names(cap_box$ir$group_indices))
  gidx <- cap_box$ir$group_indices$built_layer1
  expect_equal(length(gidx), 3L)
  expect_identical(sort(unlist(gidx, use.names = FALSE)), seq_len(nrow(datasets::mtcars)))

  box_lids <- cap_box$lineage$leaf_id[!is.na(cap_box$lineage$layer_id) & cap_box$lineage$layer_id == 1L]
  box_els <- cap_box$scene$elements[cap_box$scene$elements$leaf_id %in% box_lids, ]
  expect_true(all(c("box", "median", "whisker") %in% box_els$part_role))
  expect_true(all(!is.na(box_els$built_row_id)))
  expect_true(all(!is.na(box_els$group_id)))
})

test_that("ISS-ASSET-02, 03, 04 & ISS-AGENT-02: scene_coord, stops, guides, roles, texts.json, and preview.png work", {
  skip_if_not_installed("ggplot2")

  df <- datasets::mtcars
  df$cyl_f <- factor(df$cyl)
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$wt, .data$mpg, colour = .data$cyl_f, fill = .data$hp)) +
    ggplot2::geom_point(shape = 21, size = 3, stroke = 1) +
    ggplot2::scale_x_log10() +
    ggplot2::scale_fill_gradient2(low = "#2166AC", mid = "#F7F7F7", high = "#B2182B", midpoint = 150) +
    ggplot2::labs(title = "Fuel Economy", colour = "Cylinders", fill = "Horsepower")

  cap <- gloss(p, width = 7, height = 5, preview = TRUE)
  map <- gl_asset_map(cap)

  # ISS-ASSET-02: scene_coord + panel transformed & data domains + continuous stops/midpoint/na_value/oob
  expect_identical(map$scene$coord$origin, "top-left")
  expect_identical(map$scene$coord$y_direction, "down")
  expect_equal(unlist(map$scene$coord$viewBox), c(0, 0, 504, 360))

  pan <- map$ir$panels[[1L]]
  expect_identical(pan$domain_space, "transformed")
  expect_identical(pan$x_trans, "log-10")
  expect_true(unlist(pan$x_data_domain)[2L] > unlist(pan$x_domain)[2L])
  expect_identical(pan$x_axis_group, "scale_x_1")

  fill_sc <- Filter(function(s) identical(s$aesthetic, "fill"), map$ir$scales)[[1L]]
  expect_identical(fill_sc$scale_type, "continuous")
  expect_equal(length(fill_sc$stops), 11L)
  expect_equal(fill_sc$midpoint, 150)
  expect_true(!is.null(fill_sc$na_value))
  expect_true(!is.null(fill_sc$oob))

  # ISS-ASSET-03: Item-level ir.guides with discrete swatch_elements + colorbar entry
  expect_true(!is.null(map$ir$guides))
  expect_gte(length(map$ir$guides$entries), 2L)
  disc_guides <- Filter(function(g) identical(g$kind, "legend"), map$ir$guides$entries)
  cbar_guides <- Filter(function(g) identical(g$kind, "colorbar"), map$ir$guides$entries)
  expect_gte(length(disc_guides), 1L)
  expect_gte(length(cbar_guides), 1L)
  expect_equal(length(disc_guides[[1L]]$items), 3L)
  expect_true(all(vapply(disc_guides[[1L]]$items, function(it) length(it$swatch_elements) > 0L, logical(1L))))
  expect_true(all(vapply(disc_guides[[1L]]$items, function(it) length(it$label_elements) > 0L, logical(1L))))

  # ISS-ASSET-04: z_index, semantic_role, edit_policy, lineage_tier
  lvs <- cap$scene$leaves
  expect_identical(lvs$z_index, seq_len(nrow(lvs)))
  expect_true("data_mark" %in% lvs$semantic_role)
  expect_true("geometry_locked" %in% lvs$edit_policy)
  expect_true("plot_title" %in% lvs$semantic_role)
  expect_true("movable" %in% lvs$edit_policy)
  expect_true("row_exact" %in% cap$lineage$lineage_tier)
  expect_true("chrome" %in% cap$lineage$lineage_tier)

  # ISS-AGENT-02: scene/texts.json & assets/preview.png serialized cleanly without redrawing
  bdir <- gl_asset_bundle(cap, path = withr::local_tempdir())
  expect_true(file.exists(file.path(bdir, "scene", "texts.json")))
  expect_true(file.exists(file.path(bdir, "assets", "preview.png")))
  texts <- jsonlite::read_json(file.path(bdir, "scene", "texts.json"), simplifyVector = TRUE)
  expect_true("Fuel Economy" %in% texts$text)
  expect_true("semantic_role" %in% names(texts))
  png_hdr <- readBin(file.path(bdir, "assets", "preview.png"), "raw", n = 4L)
  expect_identical(png_hdr, as.raw(c(0x89, 0x50, 0x4e, 0x47)))

  # Leaves JSON includes clip_bbox_pt
  leaves_j <- jsonlite::read_json(file.path(bdir, "scene", "leaves.json"))
  panel_lj <- Filter(function(l) identical(l$semantic_role, "data_mark"), leaves_j)[[1L]]
  expect_equal(length(panel_lj$clip_bbox_pt), 4L)
})

test_that("ISS-GG-01, ISS-GG-02, ISS-GG-03, ISS-EXT-01 & ISS-SVG-01 capture hardening holds", {
  skip_if_not_installed("ggplot2")

  # ISS-GG-02: Empty layer (zeroGrob in facet) never causes sibling layer to lose lineage!
  df_full <- data.frame(x = 1:6, y = c(2, 4, 3, 5, 7, 6), f = c("F1", "F1", "F1", "F2", "F2", "F2"))
  df_f1_only <- df_full[df_full$f == "F1", , drop = FALSE]
  p_empty <- ggplot2::ggplot(df_full, ggplot2::aes(.data$x, .data$y)) +
    ggplot2::geom_point() +
    ggplot2::geom_line(data = df_f1_only) +
    ggplot2::facet_wrap(~f)

  cap_empty <- gloss(p_empty)
  p2_lin <- cap_empty$lineage[!is.na(cap_empty$lineage$panel_id) & cap_empty$lineage$panel_id == "P2" &
                                !is.na(cap_empty$lineage$layer_id), ]
  expect_equal(nrow(p2_lin), 1L)
  expect_identical(p2_lin$layer_id, 1L)
  expect_identical(p2_lin$cardinality, "1:1")

  # ISS-GG-01: Custom print.* ggplot subclass recovers heuristic layer lineage without gtable
  custom_p <- ggplot2::ggplot(df_full, ggplot2::aes(.data$x, .data$y)) + ggplot2::geom_point()
  class(custom_p) <- c("mock_custom_gg", class(custom_p))
  registerS3method("print", "mock_custom_gg", function(x, ...) {
    class(x) <- setdiff(class(x), "mock_custom_gg")
    print(x)
  }, envir = asNamespace("base"))
  withr::defer(rm("print.mock_custom_gg", envir = asNamespace("base")$.__S3MethodsTable__.))

  cap_cust <- gloss(custom_p)
  expect_identical(cap_cust$page$draw_method, "print.mock_custom_gg")
  cust_lin <- cap_cust$lineage[!is.na(cap_cust$lineage$layer_id), ]
  expect_gte(nrow(cust_lin), 1L)
  expect_identical(cust_lin$layer_id[[1L]], 1L)
  expect_match(cust_lin$degradation_reason[[1L]], "^custom_print_heuristic:")

  # ISS-EXT-01: Generic printable S3 object (not inheriting ggplot/grob) works without cli_abort
  wrapper_obj <- structure(
    list(gtable = withr::with_pdf(NULL, ggplot2::ggplotGrob(ggplot2::ggplot(df_full, ggplot2::aes(.data$x, .data$y)) + ggplot2::geom_point()))),
    class = "mock_pheatmap_like"
  )
  cap_wrap <- gloss(wrapper_obj)
  expect_true(is_gloss_capture(cap_wrap))
  expect_identical(cap_wrap$page$engine, "grid")
  expect_identical(cap_wrap$page$draw_method, "gtable_slot")

  # ISS-SVG-01: CJK wide character width & ancestor <g transform> matrix cascade
  expect_gt(estimate_text_width_units("\u4e2d\u6587"), estimate_text_width_units("AB"))
  svg_tr <- "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 200'><g transform='translate(50,30)'><circle cx='10' cy='10' r='5'/></g></svg>"
  els_tr <- parse_svg_elements(read_svg_doc(svg_tr))
  expect_equal(c(els_tr$bbox_x0, els_tr$bbox_y0, els_tr$bbox_x1, els_tr$bbox_y1), c(55, 35, 65, 45))

  # ISS-GG-03 & ISS-ASSET-04: ggrepel dynamic_makeContent tagging + label_links
  if (requireNamespace("ggrepel", quietly = TRUE)) {
    df_rep <- datasets::mtcars[1:6, , drop = FALSE]
    df_rep$car <- rownames(df_rep)
    p_rep <- ggplot2::ggplot(df_rep, ggplot2::aes(.data$wt, .data$mpg, label = .data$car)) +
      ggplot2::geom_point() +
      ggrepel::geom_text_repel(seed = 42, min.segment.length = 0)
    cap_rep <- gloss(p_rep)
    rep_lin <- cap_rep$lineage[!is.na(cap_rep$lineage$layer_id) & cap_rep$lineage$layer_id == 2L, ]
    expect_true(any(grepl("dynamic_makeContent", rep_lin$degradation_reason)))
    expect_gt(length(cap_rep$scene$label_links), 0L)
  }
})

test_that("ISS-PROTO-01, ISS-AGENT-01, ISS-AGENT-03 & ISS-DEV-01: bidirectional gl_query, dense raster query, parent_capture_id, and multi-page work", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    sample_id = paste0("S", seq_len(30)),
    x = seq_len(30),
    y = seq_len(30) * 2
  )
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$x, .data$y)) + ggplot2::geom_point()

  # Dense rasterized scatter plot (dense = 10 forces >10 pts into raster PNG!)
  cap_dense <- gloss(p, dense = 10)
  expect_equal(length(cap_dense$scene$dense_leaves), 1L)
  pan <- cap_dense$ir$panels[[1L]]
  bb <- unlist(pan$bbox_pt)
  # Brush upper-right quadrant (high x, high y in SVG top-left coords => right half, top half)
  q_box <- c(0.5 * (bb[1L] + bb[3L]), bb[2L], bb[3L], 0.5 * (bb[2L] + bb[4L]))
  q_res <- gl_query(cap_dense, box = q_box)
  expect_gt(nrow(q_res$tables$built_layer1), 0L)
  expect_lt(nrow(q_res$tables$built_layer1), 30L)
  expect_true(all(q_res$tables$built_layer1$x >= 14))
  expect_true("raw" %in% names(q_res$matched_raw_rows))
  expect_true(all(q_res$matched_raw_rows$raw >= 14L))

  # Forward row -> element & focus_bbox_pt query on vector plot
  cap_vec <- gloss(p, dense = Inf)
  q_fwd <- gl_query(cap_vec, table = "raw", rows = c(1L, 30L))
  expect_equal(nrow(q_fwd$elements), 2L)
  expect_equal(length(q_fwd$focus_bbox_pt), 4L)

  # ISS-AGENT-03: parent_capture_id recomputation chain + call_expr in session
  cap_v2 <- gloss(p, parent = cap_vec)
  expect_identical(cap_v2$parent_capture_id, cap_vec$capture_id)
  expect_identical(cap_v2$session$call_expr, "p")
  bdir_v2 <- gl_asset_bundle(cap_v2, path = withr::local_tempdir())
  mf2 <- jsonlite::read_json(file.path(bdir_v2, "manifest.json"))
  expect_identical(mf2$parent_capture_id, cap_vec$capture_id)

  # ISS-BASE-01: segments & arrows call tables extracted
  cap_seg <- gloss(function() {
    graphics::plot(1:4, 1:4, pch = 16)
    graphics::segments(1:4, (1:4) - 0.5, 1:4, (1:4) + 0.5)
    graphics::arrows(1, 1, 2, 2)
  })
  geoms <- vapply(cap_seg$ir$layers, `[[`, character(1L), "geom")
  expect_true(all(c("BasePoints", "BaseSegments", "BaseArrows") %in% geoms))

  # ISS-DEV-01: Multi-page selection records omitted pages cleanly
  cap_mp <- gloss(function() {
    graphics::plot(1:3, 1:3, main = "Page One")
    graphics::plot(4:6, 4:6, main = "Page Two")
  }, page = 1L)
  expect_identical(cap_mp$page$pages, 2L)
  expect_identical(cap_mp$page$selected_page, 1L)
  expect_match(cap_mp$svg$original$text, "Page One")
  bdir_mp <- gl_asset_bundle(cap_mp, path = withr::local_tempdir())
  om_mp <- jsonlite::read_json(file.path(bdir_mp, "omitted.json"))
  expect_true(any(vapply(om_mp$omitted, function(o) identical(o$kind, "pages"), logical(1L))))
})
