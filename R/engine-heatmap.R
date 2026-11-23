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
  tables <- stats::setNames(list(), character())
  orders <- stats::setNames(list(), character())
  scales <- list()
  layers <- list()

  ht_layer_map <- stats::setNames(integer(), character())
  ht_table_map <- stats::setNames(character(), character())
  ht_orders_raw <- list()
  layer_counter <- 0L

  for (nm in ht_names) {
    h <- drawn@ht_list[[nm]]
    if (!methods::is(h, "Heatmap")) next

    layer_counter <- layer_counter + 1L
    safe_nm <- sanitize_heatmap_id(nm, fallback = paste0("ht", layer_counter))
    tbl_id <- paste0("matrix_", safe_nm)

    ht_layer_map[[nm]] <- layer_counter
    ht_table_map[[nm]] <- tbl_id

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
    tables[[tbl_id]] <- list(
      table_id = tbl_id,
      role = "raw",
      key = key_col,
      layer_id = layer_counter,
      data = df
    )

    # 2. Draw-time row & column clustering permutations
    ro <- heatmap_extract_order(drawn, nm, dim = "row")
    co <- heatmap_extract_order(drawn, nm, dim = "column")
    ht_orders_raw[[nm]] <- list(row = ro, col = co)

    orders[[safe_nm]] <- list(
      heatmap = nm,
      nrow = as.integer(nrow(m)),
      ncol = as.integer(ncol(m)),
      row_order = heatmap_format_order_slices(ro, rownames(m)),
      column_order = heatmap_format_order_slices(co, colnames(m))
    )

    # 3. Matrix color mapping dictionary
    cm <- tryCatch(h@matrix_color_mapping, error = function(e) NULL)
    if (!is.null(cm)) {
      scales[[length(scales) + 1L]] <- heatmap_color_mapping_to_scale(cm, field = nm)
    }

    # 4. Annotations (tables + color mapping scales)
    anno_sides <- list(
      top = tryCatch(h@top_annotation, error = function(e) NULL),
      bottom = tryCatch(h@bottom_annotation, error = function(e) NULL),
      left = tryCatch(h@left_annotation, error = function(e) NULL),
      right = tryCatch(h@right_annotation, error = function(e) NULL)
    )
    for (side in names(anno_sides)) {
      ha <- anno_sides[[side]]
      if (is.null(ha) || !methods::is(ha, "HeatmapAnnotation")) next
      anno_res <- heatmap_extract_annotations(ha, side = side, safe_nm = safe_nm)
      if (!is.null(anno_res$table)) {
        tables[[anno_res$table$table_id]] <- anno_res$table
      }
      if (length(anno_res$scales) > 0L) {
        scales <- c(scales, anno_res$scales)
      }
    }

    # 5. Layer recipe
    layers[[length(layers) + 1L]] <- make_layer_ir(
      layer_id = layer_counter,
      geom = "HeatmapBody",
      stat = "StatCluster",
      position = "PositionIdentity",
      aes = list(fill = nm),
      raw_table = tbl_id,
      built_table = tbl_id
    )
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

    if (ht_nm %in% names(ht_layer_map)) {
      li <- ht_layer_map[[ht_nm]]
      layer_ids[[r]] <- li
      table_ids[[r]] <- ht_table_map[[ht_nm]]

      ord_info <- ht_orders_raw[[ht_nm]]
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
      layers = layers,
      scales = scales,
      orders = orders
    ),
    tables = tables,
    lineage = lineage
  )
}

sanitize_heatmap_id <- function(name, fallback = "ht") {
  clean <- gsub("[^A-Za-z0-9_]+", "_", as.character(name %||% "")[[1L]])
  clean <- gsub("^_+|_+$", "", clean)
  if (!nzchar(clean)) fallback else clean
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
    return(list(table = NULL, scales = list()))
  }

  cols <- list()
  scales <- list()
  for (an in names(anno_list)) {
    a <- anno_list[[an]]
    if (!methods::is(a, "SingleAnnotation")) next
    cm <- tryCatch(a@color_mapping, error = function(e) NULL)
    if (!is.null(cm)) {
      scales[[length(scales) + 1L]] <- heatmap_color_mapping_to_scale(cm, field = an)
    }
    vals <- tryCatch(a@fun@var_env$value, error = function(e) NULL)
    if (is.atomic(vals) && length(vals) > 0L) {
      cols[[an]] <- vals
    }
  }

  tbl <- NULL
  if (length(cols) > 0L) {
    lens <- lengths(cols)
    if (length(unique(lens)) == 1L) {
      tbl_id <- sprintf("anno_%s_%s", side, safe_nm)
      tbl <- list(
        table_id = tbl_id,
        role = "annotation",
        key = character(),
        layer_id = NULL,
        data = as.data.frame(cols, stringsAsFactors = FALSE, check.names = FALSE)
      )
    }
  }

  list(table = tbl, scales = scales)
}
