# Built-in ComplexHeatmap plotting engine (Suggests: ComplexHeatmap).
#
# Executes ComplexHeatmap::draw() once so clustering permutations exist on the
# drawn HeatmapList, then captures row_order/column_order into ir$orders,
# matrix & annotation tables, ColorMapping scale dictionaries (with continuous
# stops), slice panels with shared axis_group & order_slice ranges, and neutral
# cell/annotation lineage.

register_engine_heatmap <- function() {
  gl_register_engine(
    name = "heatmap",
    classes = c("Heatmap", "HeatmapList"),
    capture_fn = engine_heatmap_capture,
    packages = "ComplexHeatmap",
    description = "ComplexHeatmap heatmaps: clustering orders, matrix/annotation tables, color stops, shared-axis slice panels, and cell lineage",
    priority = 0L,
    page_kind = "grid",
    overwrite = TRUE
  )
}

heatmap_slice_ranges <- function(slice_list) {
  if (is.null(slice_list) || length(slice_list) == 0L) return(list())
  out <- vector("list", length(slice_list))
  cur <- 1L
  for (s in seq_along(slice_list)) {
    len <- length(slice_list[[s]])
    if (len > 0L) {
      out[[s]] <- c(cur, cur + len - 1L)
      cur <- cur + len
    } else {
      out[[s]] <- c(cur, cur)
    }
  }
  out
}

# Literal matching against known heatmap names to avoid underscore regex ambiguity (ISS-HM-01)
heatmap_parse_body_vp <- function(vp_path, known_ht_names) {
  if (is.na(vp_path) || !nzchar(vp_path)) return(NULL)
  segs <- strsplit(vp_path, "::", fixed = TRUE)[[1L]]
  last_seg <- segs[[length(segs)]]
  # Sort longest-first so prefix collisions (e.g. "hm" vs "hm_1") resolve deterministically
  ord <- order(nchar(known_ht_names), decreasing = TRUE)
  for (nm in known_ht_names[ord]) {
    pfx <- paste0(nm, "_heatmap_body_")
    if (startsWith(last_seg, pfx)) {
      rest <- substr(last_seg, nchar(pfx) + 1L, nchar(last_seg))
      m <- regmatches(rest, regexec("^([0-9]+)_([0-9]+)$", rest))[[1L]]
      if (length(m) == 3L) {
        return(list(ht_nm = nm, r_slice = as.integer(m[[2L]]), c_slice = as.integer(m[[3L]])))
      }
    }
  }
  # Fallback regex if a dynamic heatmap name wasn't listed
  m <- regmatches(last_seg, regexec("^(.+)_heatmap_body_([0-9]+)_([0-9]+)$", last_seg, perl = TRUE))[[1L]]
  if (length(m) == 4L) {
    return(list(ht_nm = m[[2L]], r_slice = as.integer(m[[3L]]), c_slice = as.integer(m[[4L]])))
  }
  NULL
}

heatmap_parse_anno_vp <- function(vp_path, anno_registry) {
  if (is.na(vp_path) || !nzchar(vp_path) || length(anno_registry) == 0L) return(NULL)
  segs <- strsplit(vp_path, "::", fixed = TRUE)[[1L]]
  hm_segs <- segs[startsWith(segs, "heatmap_")]
  anno_segs <- segs[startsWith(segs, "annotation_")]
  if (length(anno_segs) == 0L) return(NULL)

  hm_cand <- if (length(hm_segs) > 0L) sub("^heatmap_", "", hm_segs[[1L]]) else NULL
  a_seg <- anno_segs[[length(anno_segs)]]

  # Exact literal match against registered (ht_nm, anno_name) pairs (longest anno_name first)
  reg_keys <- names(anno_registry)
  an_lens <- vapply(reg_keys, function(k) nchar(anno_registry[[k]]$anno_name), integer(1L))
  for (rk in reg_keys[order(an_lens, decreasing = TRUE)]) {
    reg <- anno_registry[[rk]]
    if (!is.null(hm_cand) && !identical(reg$ht_nm, hm_cand)) next
    pfx <- paste0("annotation_", reg$anno_name, "_")
    if (startsWith(a_seg, pfx)) {
      rest <- substr(a_seg, nchar(pfx) + 1L, nchar(a_seg))
      if (grepl("^[0-9]+$", rest)) {
        return(list(reg_key = rk, ht_nm = reg$ht_nm, anno_name = reg$anno_name, slice = as.integer(rest)))
      }
    }
  }
  # Standalone rowAnnotation/columnAnnotation may sit outside heatmap_<name>
  for (rk in reg_keys[order(an_lens, decreasing = TRUE)]) {
    reg <- anno_registry[[rk]]
    pfx <- paste0("annotation_", reg$anno_name, "_")
    if (startsWith(a_seg, pfx)) {
      rest <- substr(a_seg, nchar(pfx) + 1L, nchar(a_seg))
      if (grepl("^[0-9]+$", rest)) {
        return(list(reg_key = rk, ht_nm = reg$ht_nm, anno_name = reg$anno_name, slice = as.integer(rest)))
      }
    }
  }
  NULL
}

engine_heatmap_capture <- function(x, ctx) {
  drawn <- ComplexHeatmap::draw(x)
  ctx$ensure_device()

  sc <- ctx$capture_grid(draw_method = "ComplexHeatmap::draw")
  leaves <- sc$leaves
  elements <- ensure_df_columns(sc$elements, empty_elements_df())

  ht_names <- names(drawn@ht_list)
  st <- new.env(parent = emptyenv())
  st$tables <- stats::setNames(list(), character())
  st$orders <- stats::setNames(list(), character())
  st$scales <- list()
  st$layers <- list()
  st$ht_layer_map <- stats::setNames(integer(), character())
  st$ht_table_map <- stats::setNames(character(), character())
  st$ht_safe_map <- stats::setNames(character(), character())
  st$ht_orders_raw <- list()
  st$ht_slice_ranges <- list()
  st$anno_registry <- list()
  st$default_orders <- NULL
  st$default_safe_nm <- NULL
  st$used_safe_ids <- character()
  st$layer_counter <- 0L

  register_ha_block <- function(ha, hm_key, side, safe_nm) {
    if (is.null(ha) || !methods::is(ha, "HeatmapAnnotation")) return(invisible(NULL))
    anno_res <- heatmap_extract_annotations(ha, side = side, safe_nm = safe_nm)
    anno_scale_by_field <- stats::setNames(character(), character())
    if (length(anno_res$scales) > 0L) {
      for (asc in anno_res$scales) {
        st$scales[[length(st$scales) + 1L]] <- asc
        if (!is.null(asc$field) && !is.null(asc$scale_id)) {
          anno_scale_by_field[[asc$field]] <- asc$scale_id
        }
      }
    }
    for (atbl in anno_res$tables) {
      st$layer_counter <- st$layer_counter + 1L
      li <- st$layer_counter
      atbl$layer_id <- li
      st$tables[[atbl$table_id]] <- atbl
      srefs <- stats::setNames(list(), character())
      for (an in atbl$anno_names) {
        if (an %in% names(anno_scale_by_field)) {
          srefs[[an]] <- anno_scale_by_field[[an]]
        }
      }
      st$layers[[length(st$layers) + 1L]] <- make_layer_ir(
        layer_id = li,
        geom = "HeatmapAnnotation",
        stat = "StatIdentity",
        position = "PositionIdentity",
        aes = list(annotation = json_array(atbl$anno_names)),
        raw_table = atbl$table_id,
        built_table = atbl$table_id,
        params = list(side = side, heatmap = hm_key),
        scale_refs = if (length(srefs) > 0L) srefs else NULL
      )
      dim_kind <- if (side %in% c("top", "bottom", "column")) "col" else "row"
      for (an in atbl$anno_names) {
        reg_key <- paste0(hm_key, "::", an)
        st$anno_registry[[reg_key]] <- list(
          ht_nm = hm_key,
          safe_nm = safe_nm,
          anno_name = an,
          side = side,
          dim = dim_kind,
          layer_id = li,
          table_id = atbl$table_id,
          scale_id = if (an %in% names(anno_scale_by_field)) unname(anno_scale_by_field[[an]]) else NULL,
          total_nrow = as.integer(nrow(atbl$data))
        )
      }
    }
    invisible(NULL)
  }

  for (nm in ht_names) {
    h <- drawn@ht_list[[nm]]
    if (methods::is(h, "Heatmap")) {
      st$layer_counter <- st$layer_counter + 1L
      li <- st$layer_counter
      base_safe <- sanitize_heatmap_id(nm, fallback = paste0("ht", li))
      safe_nm <- make_unique_heatmap_id(base_safe, st$used_safe_ids)
      st$used_safe_ids <- c(st$used_safe_ids, safe_nm)
      tbl_id <- if (startsWith(safe_nm, "matrix_")) safe_nm else paste0("matrix_", safe_nm)

      st$ht_layer_map[[nm]] <- li
      st$ht_table_map[[nm]] <- tbl_id
      st$ht_safe_map[[nm]] <- safe_nm

      # 1. Matrix table (preserve rownames in an explicit column when present)
      m <- h@matrix
      df <- as.data.frame(m, stringsAsFactors = FALSE, check.names = FALSE)
      key_col <- character()
      if (!is.null(rownames(m))) {
        df <- cbind(
          data.frame(row_label = rownames(m), stringsAsFactors = FALSE, check.names = FALSE),
          df
        )
        if (!anyNA(rownames(m)) && length(unique(rownames(m))) == nrow(m)) {
          key_col <- "row_label"
        }
      }
      st$tables[[tbl_id]] <- list(
        table_id = tbl_id,
        role = "raw",
        key = key_col,
        layer_id = li,
        matrix_rownames = rownames(m),
        matrix_colnames = colnames(m),
        data = df
      )

      # 2. Draw-time row & column clustering permutations & cumulative slice ranges
      ro <- heatmap_extract_order(drawn, nm, dim = "row")
      co <- heatmap_extract_order(drawn, nm, dim = "column")
      st$ht_orders_raw[[nm]] <- list(row = ro, col = co)
      st$ht_slice_ranges[[nm]] <- list(
        row = heatmap_slice_ranges(ro),
        col = heatmap_slice_ranges(co)
      )
      if (is.null(st$default_orders)) {
        st$default_orders <- list(row = ro, col = co)
        st$default_safe_nm <- safe_nm
      }

      st$orders[[safe_nm]] <- list(
        heatmap = nm,
        nrow = as.integer(nrow(m)),
        ncol = as.integer(ncol(m)),
        row_order = heatmap_format_order_slices(ro, rownames(m)),
        column_order = heatmap_format_order_slices(co, colnames(m))
      )

      # 3. Matrix color mapping dictionary
      cm <- tryCatch(h@matrix_color_mapping, error = function(e) NULL)
      main_sid <- NULL
      if (!is.null(cm)) {
        main_sid <- paste0(safe_nm, "_main_fill")
        st$scales[[length(st$scales) + 1L]] <- heatmap_color_mapping_to_scale(
          cm, field = nm, scale_id = main_sid
        )
        st$ht_scale_map <- c(st$ht_scale_map %||% stats::setNames(character(), character()), stats::setNames(main_sid, nm))
      }

      # 4. HeatmapBody layer recipe
      st$layers[[length(st$layers) + 1L]] <- make_layer_ir(
        layer_id = li,
        geom = "HeatmapBody",
        stat = "StatCluster",
        position = "PositionIdentity",
        aes = list(fill = nm),
        raw_table = tbl_id,
        built_table = tbl_id,
        scale_refs = if (!is.null(main_sid)) list(fill = main_sid) else NULL
      )

      # 5. Attached annotations (tables + scales + HeatmapAnnotation layers)
      anno_sides <- list(
        top = tryCatch(h@top_annotation, error = function(e) NULL),
        bottom = tryCatch(h@bottom_annotation, error = function(e) NULL),
        left = tryCatch(h@left_annotation, error = function(e) NULL),
        right = tryCatch(h@right_annotation, error = function(e) NULL)
      )
      for (side in names(anno_sides)) {
        register_ha_block(anno_sides[[side]], hm_key = nm, side = side, safe_nm = safe_nm)
      }
    } else if (methods::is(h, "HeatmapAnnotation")) {
      which_dir <- tryCatch(as.character(h@which)[[1L]], error = function(e) "row")
      side <- if (identical(which_dir, "column")) "top" else "right"
      base_safe <- sanitize_heatmap_id(nm, fallback = "anno")
      safe_nm <- make_unique_heatmap_id(base_safe, st$used_safe_ids)
      st$used_safe_ids <- c(st$used_safe_ids, safe_nm)
      register_ha_block(h, hm_key = nm, side = side, safe_nm = safe_nm)
    }
  }

  # Determine primary axis groups for horizontally/vertically concatenated HeatmapLists
  hm_dir <- tryCatch(as.character(drawn@direction)[[1L]], error = function(e) "horizontal")
  shared_row_grp <- if (identical(hm_dir, "horizontal") && !is.null(st$default_safe_nm)) {
    paste0(st$default_safe_nm, "_rows")
  } else {
    NULL
  }
  shared_col_grp <- if (identical(hm_dir, "vertical") && !is.null(st$default_safe_nm)) {
    paste0(st$default_safe_nm, "_cols")
  } else {
    NULL
  }

  # 6. Body slice panels, shared axis groups & cell-level element bridging
  n_leaves <- nrow(leaves)
  panel_ids <- rep(NA_character_, n_leaves)
  layer_ids <- rep(NA_integer_, n_leaves)
  table_ids <- rep(NA_character_, n_leaves)
  cardinalities <- rep("unlinked", n_leaves)
  n_rows_vec <- rep(NA_integer_, n_leaves)
  deg_reasons <- rep(NA_character_, n_leaves)
  attached_list <- vector("list", n_leaves)

  panels <- list()
  vp_to_panel <- stats::setNames(character(), character())
  known_hm <- names(st$ht_layer_map)

  for (r in seq_len(n_leaves)) {
    bm <- heatmap_parse_body_vp(leaves$vp_path[[r]], known_hm)
    if (is.null(bm)) next

    ht_nm <- bm$ht_nm
    r_slice <- bm$r_slice
    c_slice <- bm$c_slice
    vp_key <- sprintf("%s_heatmap_body_%d_%d", ht_nm, r_slice, c_slice)
    safe_nm <- if (ht_nm %in% names(st$ht_safe_map)) st$ht_safe_map[[ht_nm]] else sanitize_heatmap_id(ht_nm)
    rng_info <- st$ht_slice_ranges[[ht_nm]]
    r_rng <- if (!is.null(rng_info$row) && r_slice <= length(rng_info$row)) rng_info$row[[r_slice]] else NULL
    c_rng <- if (!is.null(rng_info$col) && c_slice <= length(rng_info$col)) rng_info$col[[c_slice]] else NULL

    if (!(vp_key %in% names(vp_to_panel))) {
      pid <- sprintf("P%d", length(panels) + 1L)
      vp_to_panel[[vp_key]] <- pid
      bbox_pt <- c(leaves$bbox_x0[[r]], leaves$bbox_y0[[r]], leaves$bbox_x1[[r]], leaves$bbox_y1[[r]])
      panels[[length(panels) + 1L]] <- make_panel_ir(
        panel_id = pid,
        facet_vars = list(heatmap = ht_nm, row_slice = r_slice, col_slice = c_slice),
        bbox_pt = bbox_pt,
        x_domain = c(leaves$xscale0[[r]], leaves$xscale1[[r]]),
        y_domain = c(leaves$yscale0[[r]], leaves$yscale1[[r]]),
        coord = "ComplexHeatmap",
        flipped = FALSE,
        row = r_slice,
        col = c_slice,
        row_axis_group = shared_row_grp %||% paste0(safe_nm, "_rows"),
        col_axis_group = shared_col_grp %||% paste0(safe_nm, "_cols"),
        row_order_ref = paste0(safe_nm, ".row_order"),
        col_order_ref = paste0(safe_nm, ".column_order"),
        row_slice_range = r_rng,
        col_slice_range = c_rng,
        panel_role = "heatmap_body"
      )
    }

    pid <- vp_to_panel[[vp_key]]
    panel_ids[[r]] <- pid

    if (ht_nm %in% names(st$ht_layer_map)) {
      li <- st$ht_layer_map[[ht_nm]]
      layer_ids[[r]] <- li
      table_ids[[r]] <- st$ht_table_map[[ht_nm]]

      ord_info <- st$ht_orders_raw[[ht_nm]]
      r_idx_vec <- if (!is.null(ord_info$row) && r_slice <= length(ord_info$row)) ord_info$row[[r_slice]] else integer()
      c_idx_vec <- if (!is.null(ord_info$col) && c_slice <= length(ord_info$col)) ord_info$col[[c_slice]] else integer()
      n_r <- if (length(r_idx_vec) > 0L) length(r_idx_vec) else NA_integer_
      n_c <- if (length(c_idx_vec) > 0L) length(c_idx_vec) else NA_integer_
      n_cells <- if (!is.na(n_r) && !is.na(n_c)) as.integer(n_r * n_c) else NA_integer_
      n_rows_vec[[r]] <- n_cells

      nel <- leaves$n_elements[[r]]
      el_idx <- which(!is.na(elements$leaf_id) & elements$leaf_id == leaves$leaf_id[[r]])
      ht_sid <- if (!is.null(st$ht_scale_map) && ht_nm %in% names(st$ht_scale_map)) st$ht_scale_map[[ht_nm]] else NULL
      ht_sc <- if (!is.null(ht_sid)) Filter(function(s) identical(s$scale_id, ht_sid), st$scales)[[1L]] else NULL
      if (!is.na(n_cells) && nel == n_cells) {
        cardinalities[[r]] <- "1:1"
        if (length(el_idx) == n_cells) {
          # ComplexHeatmap draws cells row-by-row (top to bottom) or col-by-col; match by y-bin to exact matrix row
          elements$part_role[el_idx] <- "cell"
          el_cy <- 0.5 * (elements$bbox_y0[el_idx] + elements$bbox_y1[el_idx])
          bb <- c(leaves$bbox_y0[[r]], leaves$bbox_y1[[r]])
          if (all(is.finite(bb)) && bb[[2L]] > bb[[1L]]) {
            row_pos <- pmin(n_r, pmax(1L, as.integer(floor((el_cy - bb[[1L]]) / (bb[[2L]] - bb[[1L]]) * n_r)) + 1L))
            elements$built_row_id[el_idx] <- as.integer(r_idx_vec[row_pos])
          }
          if (!is.null(ht_sc)) {
            if (identical(ht_sc$scale_type, "continuous")) {
              elements$fill_token[el_idx] <- paste0(ht_sid, "::continuous")
            } else {
              for (ei in el_idx) {
                tok <- format_style_token(ht_sc, mapped_value = elements$fill[[ei]])
                if (!is.na(tok)) elements$fill_token[[ei]] <- tok
              }
            }
          }
        }
      } else if (!is.na(n_cells) && nel == 1L && n_cells > 1L) {
        cardinalities[[r]] <- "N:1"
        deg_reasons[[r]] <- "rasterized_heatmap_body"
        if (length(el_idx) == 1L) elements$part_role[[el_idx]] <- "raster_slice"
      } else {
        cardinalities[[r]] <- infer_lineage_cardinality("GeomTile", "StatIdentity", n_cells, nel)
      }
    }
  }

  # 7. Annotation slice panels, shared axis groups & lineage (ISS-ASSET-05 & ISS-HM-01)
  if (n_leaves > 0L && length(st$anno_registry) > 0L) {
    filled_lids <- if (nrow(elements) > 0L) {
      unique(elements$leaf_id[!is.na(elements$leaf_id) & !is.na(elements$fill) & elements$fill != "none"])
    } else {
      character()
    }
    leaf_has_fill <- leaves$leaf_id %in% filled_lids

    cand_groups <- list()
    parsed_anno <- vector("list", n_leaves)
    for (r in seq_len(n_leaves)) {
      if (!is.na(layer_ids[[r]])) next
      am <- heatmap_parse_anno_vp(leaves$vp_path[[r]], st$anno_registry)
      if (is.null(am)) next
      parsed_anno[[r]] <- am
      grp_key <- paste0(am$reg_key, "::", am$slice)
      cand_groups[[grp_key]] <- c(cand_groups[[grp_key]], r)
    }

    anno_panel_counter <- 0L
    for (gk in names(cand_groups)) {
      cands <- cand_groups[[gk]]
      am <- parsed_anno[[cands[[1L]]]]
      ht_nm <- am$ht_nm
      an_nm <- am$anno_name
      sl_idx <- am$slice
      reg <- st$anno_registry[[am$reg_key]]

      ord_info <- st$ht_orders_raw[[ht_nm]] %||% st$default_orders
      rng_info <- st$ht_slice_ranges[[ht_nm]] %||%
        if (!is.null(st$default_safe_nm)) st$ht_slice_ranges[[names(st$ht_slice_ranges)[[1L]]]] else NULL
      owner_safe <- if (ht_nm %in% names(st$ht_safe_map)) st$ht_safe_map[[ht_nm]] else (st$default_safe_nm %||% reg$safe_nm)

      slice_list <- if (identical(reg$dim, "col")) ord_info$col else ord_info$row
      slice_rngs <- if (identical(reg$dim, "col")) rng_info$col else rng_info$row
      sl_indices <- if (!is.null(slice_list) && sl_idx <= length(slice_list)) slice_list[[sl_idx]] else integer()
      sl_range <- if (!is.null(slice_rngs) && sl_idx <= length(slice_rngs)) slice_rngs[[sl_idx]] else NULL
      n_slice <- if (length(sl_indices) > 0L) as.integer(length(sl_indices)) else reg$total_nrow

      # Create an annotation panel sharing the exact row/col axis_group with the main heatmap body
      anno_panel_counter <- anno_panel_counter + 1L
      apid <- sprintf("A%d", anno_panel_counter)
      valid_c <- cands[is.finite(leaves$bbox_x0[cands]) & is.finite(leaves$bbox_y0[cands]) &
                         is.finite(leaves$bbox_x1[cands]) & is.finite(leaves$bbox_y1[cands])]
      abbox <- if (length(valid_c) > 0L) {
        c(min(leaves$bbox_x0[valid_c]), min(leaves$bbox_y0[valid_c]),
          max(leaves$bbox_x1[valid_c]), max(leaves$bbox_y1[valid_c]))
      } else {
        NULL
      }
      is_col_dim <- identical(reg$dim, "col")
      panels[[length(panels) + 1L]] <- make_panel_ir(
        panel_id = apid,
        facet_vars = list(heatmap = ht_nm, annotation = an_nm, side = reg$side, slice = sl_idx),
        bbox_pt = abbox,
        x_domain = c(leaves$xscale0[[cands[[1L]]]], leaves$xscale1[[cands[[1L]]]]),
        y_domain = c(leaves$yscale0[[cands[[1L]]]], leaves$yscale1[[cands[[1L]]]]),
        coord = "ComplexHeatmapAnnotation",
        flipped = FALSE,
        row_axis_group = if (!is_col_dim) (shared_row_grp %||% paste0(owner_safe, "_rows")) else NULL,
        col_axis_group = if (is_col_dim) (shared_col_grp %||% paste0(owner_safe, "_cols")) else NULL,
        row_order_ref = if (!is_col_dim) paste0(owner_safe, ".row_order") else NULL,
        col_order_ref = if (is_col_dim) paste0(owner_safe, ".column_order") else NULL,
        row_slice_range = if (!is_col_dim) sl_range else NULL,
        col_slice_range = if (is_col_dim) sl_range else NULL,
        panel_role = "annotation"
      )

      gcls <- leaves$grob_class[cands]
      keep <- cands[
        gcls %in% c("points", "polygon", "rastergrob") |
          (gcls == "rect" & (leaf_has_fill[cands] | length(cands) == 1L))
      ]
      if (length(keep) == 0L) {
        line_cands <- cands[gcls %in% c("lines", "polyline")]
        if (length(line_cands) > 0L) {
          keep <- line_cands[[1L]]
        }
      }

      for (r in cands) {
        # K2: Attach every annotation leaf (marks + label) to matching heatmap_body slice panels
        target_body_pids <- vapply(
          Filter(function(p) {
            identical(p$panel_role, "heatmap_body") &&
              (identical(p$facet_vars$heatmap, ht_nm) || !(ht_nm %in% known_hm)) &&
              (if (is_col_dim) identical(p$facet_vars$col_slice, sl_idx) else identical(p$facet_vars$row_slice, sl_idx))
          }, panels),
          `[[`, character(1L), "panel_id"
        )
        if (length(target_body_pids) > 0L) {
          att_side <- if (reg$side %in% c("top", "bottom", "left", "right")) reg$side else if (is_col_dim) "top" else "right"
          attached_list[[r]] <- make_attachment(
            target_body_pids,
            side = att_side,
            align_axis = if (is_col_dim) "x" else "y"
          )
        }
      }

      for (r in keep) {
        panel_ids[[r]] <- apid
        layer_ids[[r]] <- reg$layer_id
        table_ids[[r]] <- reg$table_id
        n_rows_vec[[r]] <- n_slice
        nel <- leaves$n_elements[[r]]
        cardinalities[[r]] <- if (!is.na(n_slice) && nel == n_slice) {
          "1:1"
        } else if (!is.na(n_slice) && nel < n_slice) {
          "N:1"
        } else if (!is.na(n_slice) && nel > n_slice) {
          "1:M"
        } else {
          "unknown"
        }

        el_idx <- which(!is.na(elements$leaf_id) & elements$leaf_id == leaves$leaf_id[[r]])
        if (length(el_idx) > 0L) {
          elements$part_role[el_idx] <- "annotation_mark"
          if (length(el_idx) == length(sl_indices) && length(sl_indices) > 0L) {
            elements$built_row_id[el_idx] <- as.integer(sl_indices)
          }
          if (!is.null(reg$scale_id)) {
            a_sc_hits <- Filter(function(s) identical(s$scale_id, reg$scale_id), st$scales)
            if (length(a_sc_hits) > 0L) {
              a_sc <- a_sc_hits[[1L]]
              if (identical(a_sc$scale_type, "continuous")) {
                elements$fill_token[el_idx] <- paste0(reg$scale_id, "::continuous")
              } else {
                for (ei in el_idx) {
                  tok <- format_style_token(a_sc, mapped_value = elements$fill[[ei]])
                  if (!is.na(tok)) elements$fill_token[[ei]] <- tok
                }
              }
            }
          }
        }
      }
    }
  }

  # K2: Attach ComplexHeatmap dendrograms & row/column name leaves to body slice panels
  body_panels_list <- Filter(function(p) identical(p$panel_role, "heatmap_body"), panels)
  if (n_leaves > 0L && length(body_panels_list) > 0L) {
    for (r in seq_len(n_leaves)) {
      if (!is.null(attached_list[[r]]) || !is.na(panel_ids[[r]])) next
      vp <- leaves$vp_path[[r]] %||% ""
      if (!nzchar(vp)) next
      segs <- strsplit(vp, "::", fixed = TRUE)[[1L]]
      # Match <ht>_dend_row_<k>, <ht>_dend_column_<k>, <ht>_row_names_<k>, <ht>_column_names_<k>
      m_seg <- grep("_(dend_row|dend_column|row_names|column_names|row_title|column_title)_([0-9]+)$", segs, value = TRUE)
      if (length(m_seg) == 0L) next
      seg <- m_seg[[length(m_seg)]]
      mm <- regmatches(seg, regexec("^(.+)_(dend_row|dend_column|row_names|column_names|row_title|column_title)_([0-9]+)$", seg))[[1L]]
      if (length(mm) != 4L) next
      h_nm <- mm[[2L]]
      kind_s <- mm[[3L]]
      sl_k <- as.integer(mm[[4L]])
      is_col_k <- grepl("column", kind_s, fixed = TRUE)

      t_pans <- Filter(function(p) {
        (identical(p$facet_vars$heatmap, h_nm) || !(h_nm %in% known_hm)) &&
          (if (is_col_k) identical(p$facet_vars$col_slice, sl_k) else identical(p$facet_vars$row_slice, sl_k))
      }, body_panels_list)
      if (length(t_pans) == 0L) next
      t_pids <- vapply(t_pans, `[[`, character(1L), "panel_id")
      ref_bb <- unlist(t_pans[[1L]]$bbox_pt)
      l_cx <- 0.5 * (leaves$bbox_x0[[r]] + leaves$bbox_x1[[r]])
      l_cy <- 0.5 * (leaves$bbox_y0[[r]] + leaves$bbox_y1[[r]])
      side_s <- if (is_col_k) {
        if (length(ref_bb) == 4L && is.finite(l_cy) && l_cy > 0.5 * (ref_bb[[2L]] + ref_bb[[4L]])) "bottom" else "top"
      } else {
        if (length(ref_bb) == 4L && is.finite(l_cx) && l_cx > 0.5 * (ref_bb[[1L]] + ref_bb[[3L]])) "right" else "left"
      }
      attached_list[[r]] <- make_attachment(t_pids, side = side_s, align_axis = if (is_col_k) "x" else "y")
    }
  }

  # Full item-level ComplexHeatmap legend guides extraction (K3)
  guides_ir <- heatmap_extract_guides(leaves, elements, st$scales)
  if (!is.null(guides_ir)) {
    elements <- tag_guide_element_tokens(elements, guides_ir, st$scales)
  }
  sc$elements <- elements

  lineage <- make_lineage_df(
    leaves = leaves,
    panel_id = panel_ids,
    layer_id = layer_ids,
    table_id = table_ids,
    cardinality = cardinalities,
    n_rows = n_rows_vec,
    degradation_reason = deg_reasons,
    attached_to = attached_list
  )

  ir_out <- list(
    panels = panels,
    layers = st$layers,
    scales = st$scales,
    orders = st$orders
  )
  if (!is.null(guides_ir)) {
    ir_out$guides <- guides_ir
  }

  list(
    scene = sc,
    ir = ir_out,
    tables = st$tables,
    lineage = lineage
  )
}

heatmap_extract_guides <- function(leaves, elements, scales_ir) {
  if (!is.data.frame(leaves) || nrow(leaves) == 0L) return(NULL)
  leg_idx <- which(grepl("legend", leaves$vp_path, ignore.case = TRUE))
  if (length(leg_idx) == 0L) return(NULL)

  bbox_of_idx <- function(idx_vec) {
    valid <- idx_vec[
      is.finite(leaves$bbox_x0[idx_vec]) & is.finite(leaves$bbox_y0[idx_vec]) &
        is.finite(leaves$bbox_x1[idx_vec]) & is.finite(leaves$bbox_y1[idx_vec])
    ]
    if (length(valid) == 0L) return(NULL)
    json_array(round_pt(c(
      min(leaves$bbox_x0[valid]), min(leaves$bbox_y0[valid]),
      max(leaves$bbox_x1[valid]), max(leaves$bbox_y1[valid])
    )))
  }

  # Partition legend leaves into per-legend containers:
  # Every ComplexHeatmap legend puts title at VP `P` and body at `P::GRID.VP.*`.
  # Assigning each leaf to the shortest legend leaf `vp_path` that is a `::`-prefix
  # of its own `vp_path` cleanly groups each title + body together without merging siblings.
  leg_vps <- leaves$vp_path[leg_idx]
  u_vps <- unique(leg_vps)
  u_vps_ord <- u_vps[order(nchar(u_vps))]
  containers <- character(length(leg_idx))
  for (k in seq_along(leg_idx)) {
    vp <- leg_vps[[k]]
    owner <- vp
    for (cand in u_vps_ord) {
      if (identical(vp, cand) || startsWith(vp, paste0(cand, "::"))) {
        owner <- cand
        break
      }
    }
    containers[[k]] <- owner
  }

  entries <- list()
  unique_containers <- unique(containers)
  for (ci in seq_along(unique_containers)) {
    ck <- unique_containers[[ci]]
    g_idx <- leg_idx[containers == ck]
    g_lids <- leaves$leaf_id[g_idx]
    g_els <- elements[!is.na(elements$leaf_id) & elements$leaf_id %in% g_lids, , drop = FALSE]
    if (nrow(g_els) == 0L) next

    # Identify title leaf (direct child of container VP `ck` with text, when deeper body leaves exist)
    is_direct <- leaves$vp_path[g_idx] == ck
    has_deeper <- any(!is_direct)
    title_lids <- if (has_deeper) {
      g_lids[is_direct & leaves$grob_class[g_idx] == "text"]
    } else {
      character()
    }
    title_txt <- NULL
    if (length(title_lids) > 0L) {
      t_rows <- g_els[g_els$leaf_id %in% title_lids & g_els$tag == "text" & !is.na(g_els$text), , drop = FALSE]
      if (nrow(t_rows) > 0L) title_txt <- paste(t_rows$text, collapse = " ")
    }

    body_lids <- setdiff(g_lids, title_lids)
    body_els <- g_els[g_els$leaf_id %in% body_lids, , drop = FALSE]
    body_txts <- body_els[body_els$tag == "text" & !is.na(body_els$text), , drop = FALSE]
    body_rects <- body_els[body_els$tag %in% c("rect", "polygon", "circle", "image"), , drop = FALSE]
    body_ticks <- body_els[body_els$tag %in% c("line", "polyline", "path"), , drop = FALSE]

    # Match against scales_ir by title/name/field or label overlap
    lbl_strs <- trimws(as.character(body_txts$text))
    matched_sc <- NULL
    for (sc in scales_ir) {
      if (!is.null(title_txt) && (identical(sc$name, title_txt) || identical(sc$field, title_txt))) {
        matched_sc <- sc
        break
      }
    }
    if (is.null(matched_sc) && length(lbl_strs) > 0L) {
      for (sc in scales_ir) {
        sc_lbls <- unique(c(
          as.character(unlist(sc$labels)),
          vapply(sc$map, function(m) as.character(m$label %||% ""), character(1L)),
          vapply(sc$map, function(m) as.character(m$domain %||% ""), character(1L))
        ))
        if (any(lbl_strs %in% sc_lbls)) {
          matched_sc <- sc
          break
        }
      }
    }

    is_cbar <- if (!is.null(matched_sc)) {
      identical(matched_sc$scale_type, "continuous")
    } else {
      nrow(body_rects) > max(10L, nrow(body_txts) * 2L) || nrow(body_ticks) > 0L
    }

    items <- list()
    if (is_cbar) {
      items[[1L]] <- list(
        domain = if (!is.null(matched_sc) && !is.null(matched_sc$limits)) matched_sc$limits else list(),
        bar_elements = json_array(body_rects$element_id),
        tick_elements = json_array(body_ticks$element_id),
        label_elements = json_array(body_txts$element_id)
      )
    } else if (nrow(body_txts) > 0L) {
      # Pair each discrete label text with its nearest swatch element by center distance
      lbl_to_dom <- stats::setNames(character(), character())
      if (!is.null(matched_sc)) {
        for (m in (matched_sc$map %||% list())) {
          dm <- as.character(m$domain %||% "")
          lb <- as.character(m$label %||% dm)
          if (nzchar(lb) && !(lb %in% names(lbl_to_dom))) lbl_to_dom[[lb]] <- dm
        }
      }
      t_cy <- 0.5 * (body_txts$bbox_y0 + body_txts$bbox_y1)
      t_cx <- 0.5 * (body_txts$bbox_x0 + body_txts$bbox_x1)
      r_cy <- 0.5 * (body_rects$bbox_y0 + body_rects$bbox_y1)
      r_cx <- 0.5 * (body_rects$bbox_x0 + body_rects$bbox_x1)
      used_r <- logical(nrow(body_rects))

      for (ti in seq_len(nrow(body_txts))) {
        sw_ids <- character()
        avail <- which(!used_r)
        if (length(avail) > 0L && is.finite(t_cx[[ti]]) && is.finite(t_cy[[ti]])) {
          # Weight vertical alignment strongly for standard vertical swatch-label rows
          dists <- sqrt((r_cx[avail] - t_cx[[ti]])^2 * 0.25 + (r_cy[avail] - t_cy[[ti]])^2 * 4.0)
          if (any(is.finite(dists))) {
            pick <- avail[[which.min(dists)]]
            used_r[[pick]] <- TRUE
            sw_ids <- body_rects$element_id[[pick]]
          }
        }
        lb <- body_txts$text[[ti]]
        dm <- if (lb %in% names(lbl_to_dom)) unname(lbl_to_dom[[lb]]) else lb
        items[[length(items) + 1L]] <- list(
          domain = dm,
          label = lb,
          swatch_elements = json_array(sw_ids),
          label_elements = json_array(body_txts$element_id[[ti]])
        )
      }
    }

    sid <- if (!is.null(matched_sc)) matched_sc$scale_id else NULL
    aes_v <- if (!is.null(matched_sc)) matched_sc$aesthetic %||% "fill" else "fill"
    ent <- list(
      guide_id = sprintf("G%d", ci),
      kind = if (is_cbar) "colorbar" else "legend",
      scale_id = sid,
      scale_ids = json_array(if (!is.null(sid)) sid else character()),
      aesthetics = json_array(aes_v),
      bbox_pt = bbox_of_idx(g_idx),
      leaf_ids = json_array(g_lids),
      items = json_array(items)
    )
    if (!is.null(title_txt) && nzchar(title_txt)) {
      ent$title <- title_txt
    }
    entries[[length(entries) + 1L]] <- ent
  }

  list(
    collected = TRUE,
    bbox_pt = bbox_of_idx(leg_idx),
    leaf_ids = json_array(leaves$leaf_id[leg_idx]),
    aesthetics = json_array(unique(vapply(scales_ir, function(s) s$aesthetic %||% "fill", character(1L)))),
    entries = json_array(entries)
  )
}

sanitize_heatmap_id <- function(name, fallback = "ht") {
  clean <- gsub("[^A-Za-z0-9_]+", "_", as.character(name %||% "")[[1L]])
  clean <- gsub("^_+|_+$", "", clean)
  if (!nzchar(clean)) fallback else clean
}

make_unique_heatmap_id <- function(base_id, used_ids) {
  if (!(base_id %in% used_ids)) return(base_id)
  k <- 2L
  repeat {
    cand <- paste0(base_id, "_", k)
    if (!(cand %in% used_ids)) return(cand)
    k <- k + 1L
  }
}

heatmap_extract_order <- function(drawn, ht_name, dim = c("row", "column")) {
  dim <- match.arg(dim)
  ord <- tryCatch(
    if (identical(dim, "row")) {
      ComplexHeatmap::row_order(drawn)
    } else {
      ComplexHeatmap::column_order(drawn)
    },
    error = function(e) NULL
  )
  if (is.null(ord)) return(NULL)
  if (is.list(ord) && ht_name %in% names(ord)) {
    ord <- ord[[ht_name]]
  }
  if (!is.list(ord)) {
    ord <- list(as.integer(ord))
  } else {
    ord <- lapply(ord, as.integer)
  }
  ord
}

heatmap_format_order_slices <- function(slices, labels = NULL) {
  if (is.null(slices) || length(slices) == 0L) return(list())
  lapply(seq_along(slices), function(s) {
    idx <- as.integer(slices[[s]])
    out <- list(
      slice = as.integer(s),
      indices = json_array(idx)
    )
    if (!is.null(labels) && length(labels) >= max(c(0L, idx))) {
      out$labels <- json_array(labels[idx])
    }
    out
  })
}

heatmap_color_mapping_to_scale <- function(cm, field = NULL, scale_id = NULL) {
  cm_type <- tryCatch(as.character(cm@type)[[1L]], error = function(e) "unknown")
  scale_type <- if (identical(cm_type, "discrete")) "discrete" else "continuous"
  lvls <- tryCatch(cm@levels, error = function(e) NULL)
  cols <- tryCatch(as.character(cm@colors), error = function(e) character())
  cm_name <- tryCatch(as.character(cm@name)[[1L]], error = function(e) NULL)
  na_col <- tryCatch(as.character(cm@na_col)[[1L]], error = function(e) NULL)

  n <- min(length(lvls), length(cols))
  map_entries <- if (n > 0L) {
    lapply(seq_len(n), function(k) {
      dom <- lvls[[k]]
      list(
        domain = if (identical(scale_type, "discrete")) as.character(dom) else as.numeric(dom),
        value = cols[[k]],
        label = as.character(dom)
      )
    })
  } else {
    list()
  }

  dom_vals <- if (length(lvls) > 0L) {
    if (identical(scale_type, "continuous") && is.numeric(lvls)) range(lvls, na.rm = TRUE) else as.character(lvls)
  } else {
    NULL
  }

  stops_entries <- NULL
  if (identical(scale_type, "continuous") && is.numeric(dom_vals) && length(dom_vals) == 2L &&
      all(is.finite(dom_vals)) && dom_vals[[2L]] > dom_vals[[1L]]) {
    stop_pos <- seq(0.0, 1.0, length.out = 11L)
    stop_dom <- dom_vals[[1L]] + stop_pos * (dom_vals[[2L]] - dom_vals[[1L]])
    cm_fun <- tryCatch(cm@col_fun, error = function(e) NULL)
    stop_cols <- if (is.function(cm_fun)) {
      tryCatch(as.character(cm_fun(stop_dom)), error = function(e) NULL)
    } else {
      NULL
    }
    if (!is.null(stop_cols) && length(stop_cols) == length(stop_dom)) {
      stops_entries <- lapply(seq_along(stop_pos), function(k) {
        list(pos = round(stop_pos[[k]], 4L), domain = as.numeric(stop_dom[[k]]), value = stop_cols[[k]])
      })
    }
  }

  make_scale_ir(
    scale_id = scale_id,
    aesthetic = "fill",
    field = field %||% cm_name,
    scale_type = scale_type,
    map = map_entries,
    domain = dom_vals,
    limits = if (identical(scale_type, "continuous") && is.numeric(dom_vals) && length(dom_vals) == 2L) dom_vals else NULL,
    breaks = if (length(lvls) > 0L) lvls else NULL,
    labels = if (length(lvls) > 0L) as.character(lvls) else NULL,
    name = cm_name,
    stops = stops_entries,
    na_value = na_col,
    oob = if (identical(scale_type, "continuous")) "squish" else NULL
  )
}

# Safely probe known ComplexHeatmap annotation closure variable names (ISS-HM-01)
heatmap_probe_anno_values <- function(a) {
  venv <- tryCatch(a@fun@var_env, error = function(e) NULL)
  if (!is.environment(venv)) return(NULL)
  for (vname in c("value", "x", "matrix", "mat", "labels")) {
    if (exists(vname, envir = venv, inherits = FALSE)) {
      vals <- tryCatch(get(vname, envir = venv, inherits = FALSE), error = function(e) NULL)
      if ((is.matrix(vals) && nrow(vals) > 0L) || (is.atomic(vals) && length(vals) > 0L)) {
        return(vals)
      }
    }
  }
  NULL
}

heatmap_extract_annotations <- function(ha, side, safe_nm) {
  anno_list <- tryCatch(ha@anno_list, error = function(e) list())
  if (length(anno_list) == 0L) {
    return(list(tables = list(), scales = list()))
  }

  cols <- list()
  col_owner <- list()
  scales <- list()
  for (an in names(anno_list)) {
    a <- anno_list[[an]]
    if (!methods::is(a, "SingleAnnotation")) next
    cm <- tryCatch(a@color_mapping, error = function(e) NULL)
    if (!is.null(cm)) {
      a_sid <- paste0(safe_nm, "_", side, "_", sanitize_heatmap_id(an, fallback = "anno"), "_fill")
      scales[[length(scales) + 1L]] <- heatmap_color_mapping_to_scale(cm, field = an, scale_id = a_sid)
    }
    vals <- heatmap_probe_anno_values(a)
    if (is.matrix(vals) && nrow(vals) > 0L) {
      if (ncol(vals) == 1L) {
        cols[[an]] <- as.vector(vals)
        col_owner[[an]] <- an
      } else {
        cnames <- colnames(vals) %||% as.character(seq_len(ncol(vals)))
        for (j in seq_len(ncol(vals))) {
          cn <- paste0(an, "_", cnames[[j]])
          cols[[cn]] <- as.vector(vals[, j])
          col_owner[[cn]] <- an
        }
      }
    } else if (is.atomic(vals) && length(vals) > 0L) {
      cols[[an]] <- vals
      col_owner[[an]] <- an
    }
  }

  tables_out <- list()
  if (length(cols) > 0L) {
    lens <- lengths(cols)
    if (length(unique(lens)) == 1L) {
      tbl_id <- sprintf("anno_%s_%s", side, safe_nm)
      tables_out[[1L]] <- list(
        table_id = tbl_id,
        role = "annotation",
        key = character(),
        layer_id = NULL,
        anno_dim = if (side %in% c("top", "bottom", "column")) "col" else "row",
        anno_names = unique(unlist(col_owner, use.names = FALSE)),
        data = as.data.frame(cols, stringsAsFactors = FALSE, check.names = FALSE)
      )
    } else {
      owners <- unique(unlist(col_owner, use.names = FALSE))
      for (own in owners) {
        sub_cols <- cols[vapply(col_owner, identical, logical(1L), own)]
        tbl_id <- sprintf("anno_%s_%s_%s", side, safe_nm, sanitize_heatmap_id(own, fallback = "item"))
        tables_out[[length(tables_out) + 1L]] <- list(
          table_id = tbl_id,
          role = "annotation",
          key = character(),
          layer_id = NULL,
          anno_dim = if (side %in% c("top", "bottom", "column")) "col" else "row",
          anno_names = own,
          data = as.data.frame(sub_cols, stringsAsFactors = FALSE, check.names = FALSE)
        )
      }
    }
  }

  list(tables = tables_out, scales = scales)
}
