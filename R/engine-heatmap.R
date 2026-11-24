# Built-in ComplexHeatmap plotting engine (Suggests: ComplexHeatmap).
#
# Executes ComplexHeatmap::draw() once so clustering permutations exist on the
# drawn HeatmapList, then captures row_order/column_order into ir$orders,
# matrix & annotation tables, ColorMapping scale dictionaries, slice panels,
# and neutral cell/slice lineage.

register_engine_heatmap <- function() {
  gl_register_engine(
    name = "heatmap",
    classes = c("Heatmap", "HeatmapList"),
    capture_fn = engine_heatmap_capture,
    packages = "ComplexHeatmap",
    description = "ComplexHeatmap heatmaps: clustering row/column orders, matrix & annotation tables, color scales, and slice panels",
    priority = 0L,
    page_kind = "grid",
    overwrite = TRUE
  )
}

engine_heatmap_capture <- function(x, ctx) {
  drawn <- ComplexHeatmap::draw(x)
  ctx$ensure_device()

  sc <- ctx$capture_grid(draw_method = "ComplexHeatmap::draw")
  leaves <- sc$leaves

  ht_names <- names(drawn@ht_list)
  st <- new.env(parent = emptyenv())
  st$tables <- stats::setNames(list(), character())
  st$orders <- stats::setNames(list(), character())
  st$scales <- list()
  st$layers <- list()
  st$ht_layer_map <- stats::setNames(integer(), character())
  st$ht_table_map <- stats::setNames(character(), character())
  st$ht_orders_raw <- list()
  st$anno_registry <- list()
  st$default_orders <- NULL
  st$used_safe_ids <- character()
  st$layer_counter <- 0L

  register_ha_block <- function(ha, hm_key, side, safe_nm) {
    if (is.null(ha) || !methods::is(ha, "HeatmapAnnotation")) return(invisible(NULL))
    anno_res <- heatmap_extract_annotations(ha, side = side, safe_nm = safe_nm)
    if (length(anno_res$scales) > 0L) {
      st$scales <- c(st$scales, anno_res$scales)
    }
    for (atbl in anno_res$tables) {
      st$layer_counter <- st$layer_counter + 1L
      li <- st$layer_counter
      atbl$layer_id <- li
      st$tables[[atbl$table_id]] <- atbl
      st$layers[[length(st$layers) + 1L]] <- make_layer_ir(
        layer_id = li,
        geom = "HeatmapAnnotation",
        stat = "StatIdentity",
        position = "PositionIdentity",
        aes = list(annotation = json_array(atbl$anno_names)),
        raw_table = atbl$table_id,
        built_table = atbl$table_id,
        params = list(side = side, heatmap = hm_key)
      )
      dim_kind <- if (side %in% c("top", "bottom", "column")) "col" else "row"
      for (an in atbl$anno_names) {
        reg_key <- paste0(hm_key, "::", an)
        st$anno_registry[[reg_key]] <- list(
          ht_nm = hm_key,
          anno_name = an,
          side = side,
          dim = dim_kind,
          layer_id = li,
          table_id = atbl$table_id,
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
        data = df
      )

      # 2. Draw-time row & column clustering permutations
      ro <- heatmap_extract_order(drawn, nm, dim = "row")
      co <- heatmap_extract_order(drawn, nm, dim = "column")
      st$ht_orders_raw[[nm]] <- list(row = ro, col = co)
      if (is.null(st$default_orders)) {
        st$default_orders <- list(row = ro, col = co)
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
      if (!is.null(cm)) {
        st$scales[[length(st$scales) + 1L]] <- heatmap_color_mapping_to_scale(cm, field = nm)
      }

      # 4. HeatmapBody layer recipe
      st$layers[[length(st$layers) + 1L]] <- make_layer_ir(
        layer_id = li,
        geom = "HeatmapBody",
        stat = "StatCluster",
        position = "PositionIdentity",
        aes = list(fill = nm),
        raw_table = tbl_id,
        built_table = tbl_id
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

  # 6. Slice panels & neutral structural lineage from viewport probes
  body_matches <- regmatches(
    leaves$vp_path,
    regexec("(?:^|::)([^:]+)_heatmap_body_([0-9]+)_([0-9]+)$", leaves$vp_path, perl = TRUE)
  )

  n_leaves <- nrow(leaves)
  panel_ids <- rep(NA_character_, n_leaves)
  layer_ids <- rep(NA_integer_, n_leaves)
  table_ids <- rep(NA_character_, n_leaves)
  cardinalities <- rep("unlinked", n_leaves)
  n_rows_vec <- rep(NA_integer_, n_leaves)

  panels <- list()
  vp_to_panel <- stats::setNames(character(), character())

  for (r in seq_len(n_leaves)) {
    m <- body_matches[[r]]
    if (length(m) != 4L) next

    ht_nm <- m[[2L]]
    r_slice <- as.integer(m[[3L]])
    c_slice <- as.integer(m[[4L]])
    vp_key <- sprintf("%s_heatmap_body_%d_%d", ht_nm, r_slice, c_slice)

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
        col = c_slice
      )
    }

    pid <- vp_to_panel[[vp_key]]
    panel_ids[[r]] <- pid

    if (ht_nm %in% names(st$ht_layer_map)) {
      li <- st$ht_layer_map[[ht_nm]]
      layer_ids[[r]] <- li
      table_ids[[r]] <- st$ht_table_map[[ht_nm]]

      ord_info <- st$ht_orders_raw[[ht_nm]]
      n_r <- if (!is.null(ord_info$row) && r_slice <= length(ord_info$row)) length(ord_info$row[[r_slice]]) else NA_integer_
      n_c <- if (!is.null(ord_info$col) && c_slice <= length(ord_info$col)) length(ord_info$col[[c_slice]]) else NA_integer_
      n_cells <- if (!is.na(n_r) && !is.na(n_c)) as.integer(n_r * n_c) else NA_integer_
      n_rows_vec[[r]] <- n_cells

      cardinalities[[r]] <- if (!is.na(n_cells) && leaves$n_elements[[r]] == n_cells) {
        "1:1"
      } else if (!is.na(n_cells) && leaves$n_elements[[r]] == 1L && n_cells > 1L) {
        "N:1"
      } else {
        infer_lineage_cardinality("GeomTile", "StatIdentity", n_cells, leaves$n_elements[[r]])
      }
    }
  }

  # 7. Annotation leaf lineage (link annotation_<name>_<slice> data leaves to anno_* tables)
  if (n_leaves > 0L && length(st$anno_registry) > 0L) {
    anno_matches <- regmatches(
      leaves$vp_path,
      regexec("(?:^|::)heatmap_([^:]+)::.*::annotation_(.+)_([0-9]+)::.+$", leaves$vp_path, perl = TRUE)
    )
    els <- sc$elements
    filled_lids <- if (nrow(els) > 0L) {
      unique(els$leaf_id[!is.na(els$leaf_id) & !is.na(els$fill) & els$fill != "none"])
    } else {
      character()
    }
    leaf_has_fill <- leaves$leaf_id %in% filled_lids

    cand_groups <- list()
    for (r in seq_len(n_leaves)) {
      if (!is.na(layer_ids[[r]])) next
      am <- anno_matches[[r]]
      if (length(am) != 4L) next
      reg_key <- paste0(am[[2L]], "::", am[[3L]])
      if (!(reg_key %in% names(st$anno_registry))) next
      grp_key <- paste0(reg_key, "::", am[[4L]])
      cand_groups[[grp_key]] <- c(cand_groups[[grp_key]], r)
    }

    for (gk in names(cand_groups)) {
      cands <- cand_groups[[gk]]
      am <- anno_matches[[cands[[1L]]]]
      ht_nm <- am[[2L]]
      an_nm <- am[[3L]]
      sl_idx <- as.integer(am[[4L]])
      reg <- st$anno_registry[[paste0(ht_nm, "::", an_nm)]]

      ord_info <- st$ht_orders_raw[[ht_nm]] %||% st$default_orders
      slice_list <- if (identical(reg$dim, "col")) ord_info$col else ord_info$row
      n_slice <- if (!is.null(slice_list) && sl_idx <= length(slice_list)) {
        as.integer(length(slice_list[[sl_idx]]))
      } else {
        reg$total_nrow
      }

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

      for (r in keep) {
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
      }
    }
  }

  lineage <- make_lineage_df(
    leaves = leaves,
    panel_id = panel_ids,
    layer_id = layer_ids,
    table_id = table_ids,
    cardinality = cardinalities,
    n_rows = n_rows_vec
  )

  list(
    scene = sc,
    ir = list(
      panels = panels,
      layers = st$layers,
      scales = st$scales,
      orders = st$orders
    ),
    tables = st$tables,
    lineage = lineage
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
  # Multi-heatmap HeatmapList returns a list keyed by heatmap name
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

heatmap_color_mapping_to_scale <- function(cm, field = NULL) {
  cm_type <- tryCatch(as.character(cm@type)[[1L]], error = function(e) "unknown")
  scale_type <- if (identical(cm_type, "discrete")) "discrete" else "continuous"
  lvls <- tryCatch(cm@levels, error = function(e) NULL)
  cols <- tryCatch(as.character(cm@colors), error = function(e) character())
  cm_name <- tryCatch(as.character(cm@name)[[1L]], error = function(e) NULL)

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

  make_scale_ir(
    aesthetic = "fill",
    field = field %||% cm_name,
    scale_type = scale_type,
    map = map_entries,
    domain = dom_vals,
    breaks = if (length(lvls) > 0L) lvls else NULL,
    labels = if (length(lvls) > 0L) as.character(lvls) else NULL,
    name = cm_name
  )
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
      scales[[length(scales) + 1L]] <- heatmap_color_mapping_to_scale(cm, field = an)
    }
    vals <- tryCatch(a@fun@var_env$value, error = function(e) NULL)
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
          anno_names = own,
          data = as.data.frame(sub_cols, stringsAsFactors = FALSE, check.names = FALSE)
        )
      }
    }
  }

  list(tables = tables_out, scales = scales)
}
