# Schema v1.2 / Package 0.2.0 Kernel Upgrade Tests (Step 0 + K1-K6)

test_that("Step 0: package_version and schema_version are explicitly decoupled with 8 exports", {
  cap <- gloss(grid::rectGrob(width = 0.5, height = 0.5, name = "box"), preview = FALSE)

  expect_identical(cap$schema_version, "1.2.0")
  expect_identical(cap$package_version, "0.2.0")

  map <- gl_asset_map(cap)
  expect_identical(map$schema_version, "1.2.0")
  expect_identical(map$package_version, "0.2.0")

  bdir <- gl_asset_bundle(cap, path = withr::local_tempdir())
  mf <- jsonlite::read_json(file.path(bdir, "manifest.json"))
  am <- jsonlite::read_json(file.path(bdir, "asset-map.json"))
  expect_identical(mf$package_version, "0.2.0")
  expect_identical(mf$schema_version, "1.2.0")
  expect_identical(am$package_version, "0.2.0")
  expect_identical(am$schema_version, "1.2.0")

  # Strict 8-export invariant
  exports <- sort(getNamespaceExports("gloss"))
  expect_identical(
    exports,
    sort(c(
      "gloss", "gl_asset_map", "gl_asset_bundle", "gl_scene",
      "gl_tables", "gl_sources", "gl_query", "gl_register_engine"
    ))
  )
})

test_that("K1: Cross-figure entity coordinate system handles long tables, explicit bindings, patchwork merges, and ComplexHeatmap", {
  skip_if_not_installed("ggplot2")

  # 1. Longitudinal repeated-measures long table (non-unique patient_id)
  long_df <- data.frame(
    patient_id = rep(c("P001", "P002", "P003", "P004"), each = 3L),
    timepoint = rep(c("T0", "T1", "T2"), times = 4L),
    seq_run = rep(c("B1", "B1", "B2", "B2"), each = 3L),
    biomarker = c(1.2, 1.8, 2.5, 0.9, 1.1, 1.3, 2.0, 2.4, 3.1, 1.5, 1.4, 1.9),
    stringsAsFactors = FALSE
  )

  p1 <- ggplot2::ggplot(long_df, ggplot2::aes(.data$timepoint, .data$biomarker, group = .data$patient_id, colour = .data$seq_run)) +
    ggplot2::geom_line() +
    ggplot2::geom_point()

  cap1 <- gloss(p1, entities = c(subject = "patient_id", batch = "seq_run"), preview = FALSE)
  map1 <- gl_asset_map(cap1)

  expect_gte(length(map1$entities), 3L)
  subj_ent <- Filter(function(e) identical(e$entity_role, "subject") && identical(e$name, "patient_id"), map1$entities)[[1L]]
  expect_identical(subj_ent$n_distinct, 4L)
  expect_false(subj_ent$bindings[[1L]]$unique)
  expect_match(subj_ent$domain_sha256, "^sha256:[0-9a-f]{64}$")
  expect_identical(unlist(subj_ent$sample_values), c("P001", "P002", "P003", "P004"))

  # Verify entity_role is propagated into tables/schema.json
  bdir <- gl_asset_bundle(cap1, path = withr::local_tempdir())
  sch <- jsonlite::read_json(file.path(bdir, "tables", "schema.json"))
  raw_cols <- sch$tables$raw$columns
  pat_col <- Filter(function(c) identical(c$name, "patient_id"), raw_cols)[[1L]]
  batch_col <- Filter(function(c) identical(c$name, "seq_run"), raw_cols)[[1L]]
  expect_identical(pat_col$entity_role, "subject")
  expect_identical(batch_col$entity_role, "batch")

  # 2. Independent figure with same patients in shuffled order -> IDENTICAL domain_sha256
  other_df <- data.frame(
    patient_id = c("P004", "P002", "P001", "P003"),
    age = c(52, 61, 47, 58),
    response = c(0.8, 0.3, 0.9, 0.5),
    stringsAsFactors = FALSE
  )
  p2 <- ggplot2::ggplot(other_df, ggplot2::aes(.data$age, .data$response)) + ggplot2::geom_point()
  cap2 <- gloss(p2, preview = FALSE)
  subj_ent2 <- Filter(function(e) identical(e$entity_role, "subject") && identical(e$name, "patient_id"), cap2$entities)[[1L]]
  expect_identical(subj_ent2$domain_sha256, subj_ent$domain_sha256)
  expect_true(subj_ent2$bindings[[1L]]$unique)

  # 3. Patchwork merges shared patient_id across p1_raw and p2_raw
  if (requireNamespace("patchwork", quietly = TRUE)) {
    pw <- patchwork::wrap_plots(p1, p2, ncol = 2)
    cap_pw <- gloss(pw, preview = FALSE)
    pw_subj <- Filter(function(e) identical(e$entity_role, "subject") && identical(e$name, "patient_id"), cap_pw$entities)[[1L]]
    expect_equal(length(pw_subj$bindings), 2L)
    bound_tbls <- sort(vapply(pw_subj$bindings, `[[`, character(1L), "table_id"))
    expect_identical(bound_tbls, c("p1_raw", "p2_raw"))
    expect_identical(pw_subj$domain_sha256, subj_ent$domain_sha256)
  }

  # 4. ComplexHeatmap bidirectional row (feature) & col (sample) entities
  if (requireNamespace("ComplexHeatmap", quietly = TRUE)) {
    set.seed(1)
    m <- matrix(
      stats::rnorm(12),
      nrow = 3,
      ncol = 4,
      dimnames = list(c("EGFR", "KRAS", "TP53"), c("P001", "P002", "P003", "P004"))
    )
    cap_hm <- gloss(
      ComplexHeatmap::Heatmap(m, name = "expr"),
      entities = c(feature = "gene_symbol", subject = "patient_id"),
      preview = FALSE
    )
    feat_ent <- Filter(function(e) identical(e$entity_role, "feature"), cap_hm$entities)[[1L]]
    hm_subj <- Filter(function(e) identical(e$entity_role, "subject"), cap_hm$entities)[[1L]]
    expect_identical(feat_ent$name, "gene_symbol")
    expect_identical(feat_ent$bindings[[1L]]$axis, "row")
    expect_identical(feat_ent$n_distinct, 3L)
    expect_identical(hm_subj$name, "patient_id")
    expect_identical(hm_subj$bindings[[1L]]$axis, "col")
    # Column-axis subjects match ggplot's subject domain_sha256 identically!
    expect_identical(hm_subj$domain_sha256, subj_ent$domain_sha256)
  }
})

test_that("K2: Semantic layout topology, attached_to, aspect_lock, layout_tracks, and patchwork peripheral ownership work", {
  skip_if_not_installed("ggplot2")

  # 1. Fixed aspect ratio vs free Cartesian vs polar
  df <- data.frame(x = 0:10, y = 0:10, grp = rep(c("A", "B"), length.out = 11))
  cap_fix <- gloss(ggplot2::ggplot(df, ggplot2::aes(.data$x, .data$y)) + ggplot2::geom_point() + ggplot2::coord_fixed(ratio = 2), preview = FALSE)
  expect_equal(cap_fix$ir$panels[[1L]]$aspect_lock, 2.0)
  expect_identical(cap_fix$ir$panels[[1L]]$resize_mode, "proportional_only")

  cap_free <- gloss(ggplot2::ggplot(df, ggplot2::aes(.data$x, .data$y)) + ggplot2::geom_point(), preview = FALSE)
  expect_null(cap_free$ir$panels[[1L]]$aspect_lock)
  expect_identical(cap_free$ir$panels[[1L]]$resize_mode, "free_xy")

  cap_pol <- gloss(ggplot2::ggplot(df, ggplot2::aes(.data$grp)) + ggplot2::geom_bar() + ggplot2::coord_polar(), preview = FALSE)
  expect_equal(cap_pol$ir$panels[[1L]]$aspect_lock, 1.0)
  expect_identical(cap_pol$ir$panels[[1L]]$resize_mode, "proportional_only")

  # 2. Faceted ggplot layout_tracks & attached_to on axes/strips/titles
  p_fac <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~ am) +
    ggplot2::labs(title = "Faceted", x = "Weight", y = "MPG")
  cap_fac <- gloss(p_fac, preview = FALSE)
  expect_true(!is.null(cap_fac$scene$layout_tracks))
  col_kinds <- vapply(cap_fac$scene$layout_tracks$col_tracks, `[[`, character(1L), "kind")
  expect_true(all(c("flex_null", "fixed_pt") %in% col_kinds))
  expect_equal(length(cap_fac$scene$layout_tracks$panel_cells), 2L)

  strips <- cap_fac$scene$leaves[cap_fac$scene$leaves$semantic_role == "strip_label", ]
  expect_equal(nrow(strips), 2L)
  expect_identical(unlist(strips$attached_to[[1L]]$panel_ids), "P1")
  expect_identical(strips$attached_to[[1L]]$side, "top")
  expect_identical(unlist(strips$attached_to[[2L]]$panel_ids), "P2")

  # 3. Patchwork peripheral subplot attribution (axes, strips, titles)
  if (requireNamespace("patchwork", quietly = TRUE)) {
    p1 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) +
      ggplot2::geom_point() + ggplot2::labs(title = "Sub 1")
    p2 <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$disp, .data$hp)) +
      ggplot2::geom_point() + ggplot2::facet_wrap(~ am) + ggplot2::labs(title = "Sub 2")
    pw <- patchwork::wrap_plots(p1, p2, ncol = 2) + patchwork::plot_annotation(title = "Main")
    cap_pw <- gloss(pw, width = 8, height = 4, preview = FALSE)
    lvs <- cap_pw$scene$leaves

    ax_ticks <- lvs[lvs$semantic_role == "axis_tick", ]
    expect_gt(nrow(ax_ticks), 0L)
    expect_true(all(!is.na(ax_ticks$subplot)))
    expect_true(all(c(1L, 2L) %in% ax_ticks$subplot))
    expect_true(all(vapply(ax_ticks$attached_to, function(a) !is.null(a) && length(a$panel_ids) >= 1L, logical(1L))))

    pw_strips <- lvs[lvs$semantic_role == "strip_label", ]
    expect_equal(nrow(pw_strips), 2L)
    expect_true(all(pw_strips$subplot == 2L))
    expect_identical(sort(vapply(pw_strips$attached_to, function(a) unlist(a$panel_ids)[[1L]], character(1L))), c("p2_P1", "p2_P2"))

    # Subplot titles carry subplot=1/2 while top-level Main title has subplot=NA
    pw_titles <- lvs[lvs$semantic_role == "plot_title", ]
    expect_true(all(c(1L, 2L) %in% pw_titles$subplot))
    expect_true(any(is.na(pw_titles$subplot)))
  }

  # 4. ComplexHeatmap annotations & dendrograms attached_to heatmap_body panels
  if (requireNamespace("ComplexHeatmap", quietly = TRUE)) {
    set.seed(42)
    m <- matrix(stats::rnorm(24), 6, 4, dimnames = list(paste0("G", 1:6), paste0("S", 1:4)))
    ha <- ComplexHeatmap::HeatmapAnnotation(group = c("Ctrl", "Ctrl", "Treat", "Treat"))
    ra <- ComplexHeatmap::rowAnnotation(score = 1:6)
    cap_hm <- gloss(ComplexHeatmap::Heatmap(m, name = "expr", top_annotation = ha, right_annotation = ra), preview = FALSE)
    lvs_hm <- cap_hm$scene$leaves

    dends <- lvs_hm[lvs_hm$semantic_role == "dendrogram", ]
    expect_equal(nrow(dends), 2L)
    expect_true(all(vapply(dends$attached_to, function(a) !is.null(a) && "P1" %in% unlist(a$panel_ids), logical(1L))))
    dend_axes <- sort(vapply(dends$attached_to, `[[`, character(1L), "align_axis"))
    expect_identical(dend_axes, c("x", "y"))

    anno_top_lvs <- lvs_hm[grepl("annotation_group_1", lvs_hm$vp_path), ]
    expect_true(all(vapply(anno_top_lvs$attached_to, function(a) !is.null(a) && identical(a$side, "top") && identical(a$align_axis, "x"), logical(1L))))
  }
})

test_that("K3 & K4: Style tokens, scale_id, Heatmap ir.guides, and role_contracts work accurately", {
  skip_if_not_installed("ggplot2")

  # K3 acceptance test: boxplot(alpha = 0.3) + geom_point() + manual geom_hline(#E64B35) + constant override point
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(factor(.data$cyl), .data$mpg, colour = factor(.data$cyl))) +
    ggplot2::geom_boxplot(alpha = 0.3) +
    ggplot2::geom_point() +
    ggplot2::geom_hline(yintercept = 20, colour = "#E64B35") +
    ggplot2::geom_point(data = datasets::mtcars[1, , drop = FALSE], colour = "#E64B35", size = 4) +
    ggplot2::scale_colour_manual(values = c("4" = "#E64B35", "6" = "#4DBBD5", "8" = "#00A087"))

  cap <- gloss(p, preview = FALSE)
  map <- gl_asset_map(cap)

  # Deterministic scale_id on every scale
  sids <- vapply(map$ir$scales, `[[`, character(1L), "scale_id")
  expect_true(all(nzchar(sids)))
  expect_equal(length(unique(sids)), length(sids))
  col_sc <- Filter(function(s) identical(s$aesthetic, "colour"), map$ir$scales)[[1L]]

  # Layer scale_refs: layers 1 & 2 carry colour scale_id; layers 3 (hline) & 4 (fixed colour override) do NOT
  expect_identical(map$ir$layers[[1L]]$scale_refs$colour, col_sc$scale_id)
  expect_identical(map$ir$layers[[2L]]$scale_refs$colour, col_sc$scale_id)
  expect_null(map$ir$layers[[3L]]$scale_refs$colour)
  expect_null(map$ir$layers[[4L]]$scale_refs$colour)

  # Element tokens: boxplot + point + legend swatches tokenized; manual hline & constant-color point untouched
  els <- cap$scene$elements
  l1_lids <- cap$lineage$leaf_id[!is.na(cap$lineage$layer_id) & cap$lineage$layer_id == 1L]
  l2_lids <- cap$lineage$leaf_id[!is.na(cap$lineage$layer_id) & cap$lineage$layer_id == 2L]
  l3_lids <- cap$lineage$leaf_id[!is.na(cap$lineage$layer_id) & cap$lineage$layer_id == 3L]
  l4_lids <- cap$lineage$leaf_id[!is.na(cap$lineage$layer_id) & cap$lineage$layer_id == 4L]

  expect_true(all(grepl(paste0("^", col_sc$scale_id, "::"), els$color_token[els$leaf_id %in% l1_lids])))
  expect_true(all(grepl(paste0("^", col_sc$scale_id, "::"), els$color_token[els$leaf_id %in% l2_lids])))
  expect_true(all(is.na(els$color_token[els$leaf_id %in% l3_lids])))
  expect_true(all(is.na(els$color_token[els$leaf_id %in% l4_lids])))

  # Guide entries reference scale_id and tag swatches
  expect_identical(map$ir$guides$entries[[1L]]$scale_id, col_sc$scale_id)
  sw_ids <- unlist(lapply(map$ir$guides$entries[[1L]]$items, `[[`, "swatch_elements"))
  expect_true(all(grepl(paste0("^", col_sc$scale_id, "::"), els$color_token[els$element_id %in% sw_ids])))

  # K4: role_contracts covers 100% of emitted semantic_roles with locked/editable/gated
  contracts <- map$scene$role_contracts
  expect_true(all(unique(cap$scene$leaves$semantic_role) %in% names(contracts)))
  expect_true("data_position" %in% unlist(contracts$data_mark$locked))
  expect_true("point_size" %in% unlist(contracts$data_mark$editable))
  expect_true("rotation" %in% unlist(contracts$axis_tick$editable))
  expect_true("text_content" %in% unlist(contracts$axis_tick$locked))

  # K3 Heatmap unified ir.guides
  if (requireNamespace("ComplexHeatmap", quietly = TRUE)) {
    set.seed(123)
    m <- matrix(stats::rnorm(24), 6, 4, dimnames = list(paste0("G", 1:6), paste0("S", 1:4)))
    ha <- ComplexHeatmap::HeatmapAnnotation(
      group = c("Ctrl", "Ctrl", "Treat", "Treat"),
      score = c(1.0, 2.5, 3.2, 4.8)
    )
    cap_h <- gloss(ComplexHeatmap::Heatmap(m, name = "expr", top_annotation = ha), preview = FALSE)
    ents <- cap_h$ir$guides$entries
    expect_equal(length(ents), 3L)
    expect_true(all(vapply(ents, function(e) !is.null(e$scale_id) && nzchar(e$scale_id), logical(1L))))
    disc_e <- Filter(function(e) identical(e$kind, "legend"), ents)[[1L]]
    cbar_es <- Filter(function(e) identical(e$kind, "colorbar"), ents)
    expect_equal(length(cbar_es), 2L)
    expect_equal(length(disc_e$items), 2L)
    expect_true(all(vapply(disc_e$items, function(it) length(it$swatch_elements) == 1L && length(it$label_elements) == 1L, logical(1L))))
    expect_true(length(cbar_es[[1L]]$items[[1L]]$bar_elements) > 10L)
    expect_true(length(cbar_es[[1L]]$items[[1L]]$tick_elements) > 0L)
    expect_true(all(unique(cap_h$scene$leaves$semantic_role) %in% names(contracts)))
  }
})

test_that("K5: Logical text blocks, exact measured widths, and universal non-repel label target_anchor_pt work", {
  skip_if_not_installed("ggplot2")

  df <- data.frame(
    x = c(1, 5, 9),
    y = c(2, 6, 10),
    lbl = c("Alpha", "Beta", "Gamma"),
    stringsAsFactors = FALSE
  )
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$x, .data$y, label = .data$lbl)) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_text(nudge_y = 1.5) +
    ggplot2::labs(title = "Main Study Title\nSecondary Line")

  cap <- gloss(p, preview = FALSE)

  # Universal label_links for non-repel geom_text (leader_element_id = NULL, exact un-nudged target_anchor_pt!)
  expect_equal(length(cap$scene$label_links), 3L)
  expect_true(all(vapply(cap$scene$label_links, function(lk) is.null(lk$leader_element_id), logical(1L))))

  # Compare target_anchor_pt against actual drawn circle centers of geom_point (layer 1)
  pt_lid <- cap$lineage$leaf_id[!is.na(cap$lineage$layer_id) & cap$lineage$layer_id == 1L][[1L]]
  pt_els <- cap$scene$elements[!is.na(cap$scene$elements$leaf_id) & cap$scene$elements$leaf_id == pt_lid, ]
  pt_cx <- 0.5 * (pt_els$bbox_x0 + pt_els$bbox_x1)
  pt_cy <- 0.5 * (pt_els$bbox_y0 + pt_els$bbox_y1)
  for (lk in cap$scene$label_links) {
    br <- lk$built_row_id
    tap <- unlist(lk$target_anchor_pt)
    expect_lt(abs(tap[[1L]] - pt_cx[[br]]), 1.0)
    expect_lt(abs(tap[[2L]] - pt_cy[[br]]), 1.0)
  }

  # Multiline title merges into a single text_block_id in scene/texts.json while Y-axis ticks stay separate
  bdir <- gl_asset_bundle(cap, path = withr::local_tempdir())
  txts <- jsonlite::read_json(file.path(bdir, "scene", "texts.json"))
  title_txts <- Filter(function(t) identical(t$semantic_role, "plot_title"), txts)
  expect_equal(length(title_txts), 2L)
  expect_identical(title_txts[[1L]]$text_block_id, title_txts[[2L]]$text_block_id)
  expect_identical(title_txts[[1L]]$line_index, 1L)
  expect_identical(title_txts[[2L]]$line_index, 2L)
  expect_identical(title_txts[[1L]]$block_text, "Main Study Title\nSecondary Line")
  expect_true(is.numeric(title_txts[[1L]]$measured_width_pt) && title_txts[[1L]]$measured_width_pt > 0)
  expect_equal(length(title_txts[[1L]]$anchor_pt), 2L)

  dl_txts <- Filter(function(t) identical(t$semantic_role, "data_label"), txts)
  expect_equal(length(dl_txts), 3L)
  expect_true(all(vapply(dl_txts, function(t) length(t$target_anchor_pt) == 2L, logical(1L))))

  tick_txts <- Filter(function(t) identical(t$semantic_role, "axis_tick"), txts)
  tick_blocks <- unique(vapply(tick_txts, `[[`, character(1L), "text_block_id"))
  expect_equal(length(tick_blocks), length(tick_txts))

  # BaseText also generates universal label_links with target_anchor_pt
  cap_base <- gloss(function() {
    graphics::plot(c(1, 2, 3), c(2, 4, 6), pch = 16)
    graphics::text(c(1, 3), c(2, 6), labels = c("Low", "High"), pos = 3)
  }, preview = FALSE)
  expect_equal(length(cap_base$scene$label_links), 2L)
  expect_true(all(vapply(cap_base$scene$label_links, function(lk) length(lk$target_anchor_pt) == 2L, logical(1L))))
})

test_that("K6: Pre-plot upstream data funnel and gl_query() context_summary work accurately", {
  skip_if_not_installed("ggplot2")

  full_df <- data.frame(
    patient_id = sprintf("P%03d", seq_len(20)),
    arm = rep(c("A", "B"), each = 10L),
    qc_pass = c(rep(TRUE, 8L), FALSE, FALSE, rep(TRUE, 9L), FALSE),
    x = c(1:10, 1:10),
    y = c(10, 11, 10.5, 11.2, 10.8, 10.1, 11.4, 38.0, 10, 10,
          20, 21, 20.5, 21.2, 20.8, 20.1, 21.4, 20.9, 21.0, 20),
    stringsAsFactors = FALSE
  )
  plot_df <- subset(full_df, qc_pass)

  p <- ggplot2::ggplot(plot_df, ggplot2::aes(.data$x, .data$y, colour = .data$arm)) +
    ggplot2::geom_point(size = 3)

  cap <- gloss(
    p,
    upstream = list(data = full_df, note = "subset(full_df, qc_pass)"),
    preview = FALSE
  )

  # 1. Compact ir$data_funnel without bloating tables/
  expect_false("upstream" %in% names(cap$tables))
  fnl <- cap$ir$data_funnel
  expect_identical(fnl$n_upstream, 20L)
  expect_identical(fnl$n_plot_input, 17L)
  expect_identical(fnl$n_upstream_excluded, 3L)
  expect_identical(fnl$entity_role, "subject")
  expect_identical(fnl$entity_column, "patient_id")
  expect_identical(unlist(fnl$excluded_entities_sample), c("P009", "P010", "P020"))
  expect_identical(fnl$filter_hint, "subset(full_df, qc_pass)")

  map <- gl_asset_map(cap)
  expect_identical(map$ir$data_funnel$n_upstream_excluded, 3L)

  # 2. gl_query(box = ...) brushing the single upper outlier P008 (y = 38 in arm A)
  pan <- cap$ir$panels[[1L]]
  bb <- unlist(pan$bbox_pt)
  # Upper 25% of panel captures P008 cleanly
  q_box <- c(bb[[1L]], bb[[2L]], bb[[3L]], bb[[2L]] + 0.25 * (bb[[4L]] - bb[[2L]]))
  q <- gl_query(cap, box = q_box)

  expect_true("context_summary" %in% names(q))
  expect_true("patient_id" %in% names(q$context_summary$entities))
  expect_identical(q$context_summary$entities$patient_id$values, "P008")

  expect_equal(length(q$context_summary$comparisons), 1L)
  cmp <- q$context_summary$comparisons[[1L]]
  expect_identical(cmp$panel_id, "P1")
  expect_identical(cmp$group, "A")
  expect_identical(cmp$selected_n, 1L)
  expect_identical(cmp$group_n, 8L)
  expect_equal(cmp$metrics$y$selected_mean, 38.0)
  expect_gt(cmp$metrics$y$max_abs_z, 2.0)
  expect_gt(cmp$metrics$y$max_iqr_multiple, 10.0)
})
