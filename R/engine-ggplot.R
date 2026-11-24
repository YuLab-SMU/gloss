# Built-in ggplot2 plotting engine (Suggests: ggplot2).
#
# Performs a single ggplot_build() -> ggplot_gtable() -> grid.draw() pass so
# stochastic layers (position_jitter, stat_smooth, etc.) match original.svg,
# scene.svg, and built_layer* tables identically. Subclasses that define a
# custom print method (e.g. ggbreak) fall back to print(x) while still
# recording raw data and observed scene facts neutrally.

register_engine_ggplot <- function() {
  gl_register_engine(
    name = "ggplot",
    classes = c("ggplot2::ggplot", "ggplot"),
    capture_fn = engine_ggplot_capture,
    packages = "ggplot2",
    description = "ggplot2 plots: raw/built tables, scale/palette dictionaries, layer specs, facet panels, and structural lineage",
    priority = 0L,
    page_kind = "grid",
    overwrite = TRUE
  )
}

engine_ggplot_capture <- function(x, ctx) {
  owner <- ggplot_custom_print_owner(x)
  built <- NULL
  gtable <- NULL
  draw_method <- "ggplot_gtable"

  if (is.null(owner)) {
    built <- tryCatch(ggplot2::ggplot_build(x), error = function(e) NULL)
    if (!is.null(built) && inherits(built, c("ggplot2::ggplot_built", "ggplot_built"))) {
      grid::grid.newpage()
      gtable <- ggplot2::ggplot_gtable(built)
      grid::grid.draw(gtable)
      draw_method <- "ggplot_gtable"
    } else {
      # Extension whose ggplot_build() returns a non-standard object: draw via print()
      print(x)
      built <- NULL
      draw_method <- "print"
    }
  } else {
    print(x)
    draw_method <- paste0("print.", owner)
    # Best-effort metadata build for neutral observation without failing capture
    built <- tryCatch({
      b <- ggplot2::ggplot_build(x)
      if (inherits(b, c("ggplot2::ggplot_built", "ggplot_built"))) b else NULL
    }, error = function(e) NULL)
  }

  ctx$ensure_device()
  sc <- ctx$capture_grid(draw_method = draw_method)

  extracted <- extract_ggplot_ir(
    plot = x,
    built = built,
    gtable = gtable,
    leaves = sc$leaves
  )

  list(
    scene = sc,
    ir = extracted$ir,
    tables = extracted$tables,
    lineage = extracted$lineage
  )
}

# Detect if a subclass of ggplot defines its own print.* method distinct from ggplot2's.
ggplot_custom_print_owner <- function(x) {
  std_methods <- lapply(c("ggplot2::ggplot", "ggplot"), function(cls) {
    tryCatch(utils::getS3method("print", cls, optional = TRUE), error = function(e) NULL)
  })
  std_methods <- Filter(Negate(is.null), std_methods)

  for (cls in class(x)) {
    if (cls %in% c("ggplot2::ggplot", "ggplot", "ggplot2::gg", "gg", "S7_object")) next
    m <- tryCatch(utils::getS3method("print", cls, optional = TRUE), error = function(e) NULL)
    if (is.null(m)) next
    is_std <- any(vapply(std_methods, function(f) identical(f, m), logical(1L)))
    if (!is_std) return(cls)
  }
  NULL
}

# --- Reusable ggplot2 IR & lineage extractor (also used by patchwork) --------

extract_ggplot_ir <- function(
    plot,
    built = NULL,
    gtable = NULL,
    leaves = empty_leaves_df(),
    panel_prefix = "",
    table_prefix = "",
    leaf_indices = NULL) {

  sub_leaves <- if (is.null(leaf_indices)) leaves else leaves[leaf_indices, , drop = FALSE]

  tables <- ggplot_extract_tables(plot, built, table_prefix = table_prefix)
  layers_ir <- ggplot_extract_layers(plot, built, table_prefix = table_prefix)

  panel_match <- if (!is.null(built)) {
    ggplot_match_panels(built, gtable, sub_leaves, panel_prefix = panel_prefix)
  } else {
    list(
      panels = list(),
      leaf_panel = rep(NA_character_, nrow(sub_leaves)),
      panel_grob_to_num = stats::setNames(integer(), character()),
      panel_ids_by_num = stats::setNames(character(), character())
    )
  }

  scales_ir <- if (!is.null(built)) {
    ggplot_extract_scales(plot, built, panel_ids_by_num = panel_match$panel_ids_by_num)
  } else {
    list()
  }

  lineage <- ggplot_build_lineage(
    built = built,
    gtable = gtable,
    leaves = sub_leaves,
    panel_match = panel_match,
    layers_ir = layers_ir,
    table_prefix = table_prefix
  )

  list(
    ir = list(
      panels = panel_match$panels,
      layers = layers_ir,
      scales = scales_ir,
      orders = stats::setNames(list(), character())
    ),
    tables = tables,
    lineage = lineage
  )
}

# --- Tables extraction -------------------------------------------------------

ggplot_extract_tables <- function(plot, built, table_prefix = "") {
  tables <- stats::setNames(list(), character())
  pfx <- if (nzchar(table_prefix)) paste0(table_prefix, "_") else ""

  plot_data <- plot$data
  if (is.data.frame(plot_data)) {
    tbl_id <- paste0(pfx, "raw")
    tables[[tbl_id]] <- list(
      table_id = tbl_id,
      role = "raw",
      key = ggplot_infer_table_key(plot_data, plot),
      layer_id = NULL,
      data = plot_data
    )
  }

  plot_layers <- plot$layers %||% list()
  for (i in seq_along(plot_layers)) {
    ldata <- plot_layers[[i]]$data
    if (is.data.frame(ldata)) {
      tbl_id <- paste0(pfx, "raw_layer", i)
      tables[[tbl_id]] <- list(
        table_id = tbl_id,
        role = "raw",
        key = ggplot_infer_table_key(ldata, plot),
        layer_id = as.integer(i),
        data = ldata
      )
    }
  }

  if (!is.null(built) && length(built$data) > 0L) {
    for (i in seq_along(built$data)) {
      bdf <- built$data[[i]]
      if (is.data.frame(bdf)) {
        tbl_id <- paste0(pfx, "built_layer", i)
        tables[[tbl_id]] <- list(
          table_id = tbl_id,
          role = "built",
          key = character(),
          layer_id = as.integer(i),
          data = bdf
        )
      }
    }
  }

  tables
}

ggplot_infer_table_key <- function(df, plot) {
  if (!is.data.frame(df) || nrow(df) == 0L) return(character())
  key_hints <- c("id", "sample_id", "patient_id", "label", "name")
  for (col in intersect(key_hints, names(df))) {
    vals <- df[[col]]
    if (!anyNA(vals) && length(unique(vals)) == nrow(df)) {
      return(col)
    }
  }
  character()
}

# --- Layers recipe extraction ------------------------------------------------

quo_to_label <- function(q) {
  if (is.null(q)) return(NA_character_)
  expr <- tryCatch(rlang::quo_get_expr(q), error = function(e) q)
  if (is.call(expr) && identical(expr[[1L]], as.symbol("$")) && identical(expr[[2L]], as.symbol(".data"))) {
    return(as.character(expr[[3L]]))
  }
  if (is.call(expr) && identical(expr[[1L]], as.symbol("[[")) && identical(expr[[2L]], as.symbol(".data"))) {
    return(as.character(expr[[3L]]))
  }
  txt <- tryCatch(rlang::expr_text(expr), error = function(e) paste(deparse(expr), collapse = " "))
  trimws(txt)
}

mapping_to_aes_list <- function(mapping) {
  if (is.null(mapping) || length(mapping) == 0L) {
    return(stats::setNames(list(), character()))
  }
  nms <- names(mapping)
  out <- stats::setNames(vector("list", length(nms)), nms)
  for (nm in nms) {
    out[[nm]] <- quo_to_label(mapping[[nm]])
  }
  out
}

sanitize_layer_params <- function(params) {
  if (!is.list(params) || length(params) == 0L) return(NULL)
  keep <- list()
  for (nm in names(params)) {
    val <- params[[nm]]
    if (is.atomic(val) && length(val) <= 10L && !is.null(val)) {
      keep[[nm]] <- if (length(val) == 1L) val else json_array(val)
    }
  }
  if (length(keep) == 0L) NULL else keep
}

ggplot_extract_layers <- function(plot, built, table_prefix = "") {
  pfx <- if (nzchar(table_prefix)) paste0(table_prefix, "_") else ""
  layers <- if (!is.null(built) && length(built$plot$layers) > 0L) {
    built$plot$layers
  } else {
    plot$layers %||% list()
  }
  if (length(layers) == 0L) return(list())

  plot_aes <- mapping_to_aes_list(plot$mapping)
  has_plot_raw <- is.data.frame(plot$data)

  lapply(seq_along(layers), function(i) {
    lyr <- layers[[i]]
    lyr_aes <- mapping_to_aes_list(lyr$mapping)
    eff_aes <- if (isTRUE(lyr$inherit.aes)) {
      utils::modifyList(plot_aes, lyr_aes)
    } else {
      lyr_aes
    }

    raw_tbl <- if (is.data.frame(lyr$data)) {
      paste0(pfx, "raw_layer", i)
    } else if (has_plot_raw) {
      paste0(pfx, "raw")
    } else {
      NULL
    }
    built_tbl <- if (!is.null(built) && i <= length(built$data) && is.data.frame(built$data[[i]])) {
      paste0(pfx, "built_layer", i)
    } else {
      NULL
    }

    make_layer_ir(
      layer_id = i,
      geom = class(lyr$geom)[[1L]],
      stat = class(lyr$stat)[[1L]],
      position = class(lyr$position)[[1L]],
      aes = eff_aes,
      raw_table = raw_tbl,
      built_table = built_tbl,
      params = sanitize_layer_params(lyr$aes_params)
    )
  })
}

# --- Scales & palette dictionaries extraction --------------------------------

ggplot_scale_trans_name <- function(sc) {
  tr <- tryCatch(sc$get_transformation(), error = function(e) NULL)
  if (is.null(tr)) tr <- tryCatch(sc$trans, error = function(e) NULL)
  if (is.null(tr)) return(NULL)
  tr$name %||% NULL
}

ggplot_scale_label_name <- function(sc, plot, primary_aes) {
  nm <- tryCatch(sc$name, error = function(e) NULL)
  if (is.character(nm) && length(nm) == 1L && !is.na(nm) && nzchar(nm)) {
    return(nm)
  }
  lbl <- tryCatch(plot$labels[[primary_aes]], error = function(e) NULL)
  if (is.character(lbl) && length(lbl) == 1L && !is.na(lbl) && nzchar(lbl)) {
    return(lbl)
  }
  NULL
}

ggplot_aesthetic_field <- function(plot, aes_names) {
  maps <- c(list(plot$mapping), lapply(plot$layers %||% list(), function(l) l$mapping))
  for (m in maps) {
    if (is.null(m) || length(m) == 0L) next
    hit <- intersect(aes_names, names(m))
    if (length(hit) > 0L) {
      return(quo_to_label(m[[hit[[1L]]]]))
    }
  }
  NULL
}

ggplot_serialize_scale <- function(sc, plot, primary_aes = NULL, panel_ids = NULL) {
  aesthetics <- tryCatch(as.character(sc$aesthetics), error = function(e) character())
  primary <- primary_aes %||% if (length(aesthetics) > 0L) aesthetics[[1L]] else "unknown"
  field <- ggplot_aesthetic_field(plot, unique(c(primary, aesthetics)))
  scale_name <- ggplot_scale_label_name(sc, plot, primary)
  is_disc <- isTRUE(tryCatch(sc$is_discrete(), error = function(e) FALSE))
  is_binned <- inherits(sc, "ScaleBinned")
  is_ident <- inherits(sc, "ScaleIdentity")

  scale_type <- if (is_ident) {
    "identity"
  } else if (is_binned) {
    "binned"
  } else if (is_disc) {
    "discrete"
  } else {
    "continuous"
  }

  lims <- tryCatch(sc$get_limits(), error = function(e) NULL)
  brks <- tryCatch(sc$get_breaks(), error = function(e) NULL)
  if (is.logical(brks) && length(brks) == 0L) brks <- NULL
  lbls <- tryCatch({
    if (!is.null(brks) && length(brks) > 0L) sc$get_labels(brks) else sc$get_labels()
  }, error = function(e) NULL)
  if (is.expression(lbls)) lbls <- as.character(lbls)

  trans_name <- if (!is_disc) ggplot_scale_trans_name(sc) else NULL
  is_position <- primary %in% c("x", "y")

  map_entries <- list()
  if (!is_position) {
    if (is_disc && !is.null(lims) && length(lims) > 0L) {
      mapped_vals <- tryCatch(sc$map(lims), error = function(e) rep(NA, length(lims)))
      brk_lbls <- stats::setNames(as.character(lbls %||% as.character(brks)), as.character(brks %||% character()))
      map_entries <- lapply(seq_along(lims), function(k) {
        dom <- as.character(lims[[k]])
        val <- mapped_vals[[k]]
        if (length(val) == 1L && is.na(val)) val <- NULL
        lbl <- if (dom %in% names(brk_lbls)) unname(brk_lbls[[dom]]) else dom
        list(domain = dom, value = val, label = lbl)
      })
    } else if (!is_disc && is.numeric(lims) && length(lims) == 2L && all(is.finite(lims))) {
      # Map in-domain breaks (plus endpoints if breaks fall outside limits)
      sample_pts <- if (is.numeric(brks) && length(brks) > 0L) {
        brks[is.finite(brks) & brks >= lims[[1L]] & brks <= lims[[2L]]]
      } else {
        numeric()
      }
      if (length(sample_pts) == 0L) {
        sample_pts <- seq(lims[[1L]], lims[[2L]], length.out = 5L)
      }
      mapped_vals <- tryCatch(sc$map(sample_pts), error = function(e) rep(NA, length(sample_pts)))
      sample_lbls <- tryCatch(as.character(sc$get_labels(sample_pts)), error = function(e) as.character(sample_pts))
      map_entries <- lapply(seq_along(sample_pts), function(k) {
        val <- mapped_vals[[k]]
        if (length(val) == 1L && is.na(val)) val <- NULL
        list(
          domain = as.numeric(sample_pts[[k]]),
          value = val,
          label = if (k <= length(sample_lbls)) sample_lbls[[k]] else as.character(sample_pts[[k]])
        )
      })
    }
  } else if (is_disc && !is.null(lims) && length(lims) > 0L) {
    brk_lbls <- stats::setNames(as.character(lbls %||% as.character(brks)), as.character(brks %||% character()))
    map_entries <- lapply(seq_along(lims), function(k) {
      dom <- as.character(lims[[k]])
      lbl <- if (dom %in% names(brk_lbls)) unname(brk_lbls[[dom]]) else dom
      list(domain = dom, value = as.integer(k), label = lbl)
    })
  }

  clean_brks <- if (!is.null(brks) && length(brks) > 0L) {
    if (is.numeric(brks)) brks[is.finite(brks)] else as.character(brks[!is.na(brks)])
  } else {
    NULL
  }
  clean_lbls <- if (!is.null(lbls) && length(lbls) > 0L) {
    as.character(lbls[!is.na(lbls)])
  } else {
    NULL
  }

  make_scale_ir(
    aesthetic = primary,
    field = field,
    scale_type = scale_type,
    map = map_entries,
    domain = if (!is.null(lims) && length(lims) > 0L) lims else NULL,
    breaks = clean_brks,
    labels = clean_lbls,
    trans = trans_name,
    name = scale_name,
    panel_ids = panel_ids
  )
}

ggplot_extract_scales <- function(plot, built, panel_ids_by_num = NULL) {
  out <- list()
  lay <- built$layout$layout

  panels_for_scale <- function(scale_col, scale_idx) {
    if (is.null(lay) || !(scale_col %in% names(lay))) return(NULL)
    pnums <- as.character(lay$PANEL[as.integer(lay[[scale_col]]) == scale_idx])
    if (length(pnums) == 0L) return(NULL)
    if (!is.null(panel_ids_by_num) && length(panel_ids_by_num) > 0L) {
      pids <- unname(panel_ids_by_num[pnums])
      pids <- pids[!is.na(pids)]
      if (length(pids) > 0L) return(pids)
    }
    paste0("P", pnums)
  }

  # 1. Trained position scales (x and y) from layout — preserve all free facet scales
  px <- built$layout$panel_scales_x
  if (length(px) > 0L) {
    multi_x <- length(px) > 1L
    for (k in seq_along(px)) {
      if (is.null(px[[k]])) next
      pids <- if (multi_x) panels_for_scale("SCALE_X", k) else NULL
      out[[length(out) + 1L]] <- ggplot_serialize_scale(px[[k]], plot, primary_aes = "x", panel_ids = pids)
    }
  }
  py <- built$layout$panel_scales_y
  if (length(py) > 0L) {
    multi_y <- length(py) > 1L
    for (k in seq_along(py)) {
      if (is.null(py[[k]])) next
      pids <- if (multi_y) panels_for_scale("SCALE_Y", k) else NULL
      out[[length(out) + 1L]] <- ggplot_serialize_scale(py[[k]], plot, primary_aes = "y", panel_ids = pids)
    }
  }

  # 2. Non-position aesthetic scales (colour, fill, shape, size, linetype, alpha, etc.)
  all_scales <- built$plot$scales$scales %||% list()
  for (sc in all_scales) {
    aesthetics <- tryCatch(as.character(sc$aesthetics), error = function(e) character())
    if (length(aesthetics) == 0L || aesthetics[[1L]] %in% c("x", "y")) next
    out[[length(out) + 1L]] <- ggplot_serialize_scale(sc, plot, primary_aes = aesthetics[[1L]])
  }

  out
}

# --- Panels matching & coordinate domains ------------------------------------

ggplot_panel_domain <- function(pp, axis = c("x", "y"), scale = NULL) {
  axis <- match.arg(axis)
  candidates <- if (identical(axis, "x")) {
    list(pp$x.range, pp$x$continuous_range, pp$theta.range)
  } else {
    list(pp$y.range, pp$y$continuous_range, pp$r.range)
  }
  for (cand in candidates) {
    if (is.numeric(cand) && length(cand) == 2L && all(is.finite(cand))) {
      return(as.numeric(cand))
    }
  }
  if (!is.null(scale)) {
    lims <- tryCatch(scale$get_limits(), error = function(e) NULL)
    if (is.numeric(lims) && length(lims) == 2L && all(is.finite(lims))) {
      return(as.numeric(lims))
    }
    if (is.character(lims) && length(lims) > 0L) {
      return(c(1, length(lims)))
    }
  }
  NULL
}

ggplot_match_panels <- function(built, gtable, leaves, panel_prefix = "") {
  lay <- built$layout$layout
  if (is.null(lay) || nrow(lay) == 0L) {
    return(list(
      panels = list(),
      leaf_panel = rep(NA_character_, nrow(leaves)),
      panel_grob_map = list()
    ))
  }

  coord_cls <- class(built$layout$coord)[[1L]]
  flipped <- inherits(built$layout$coord, "CoordFlip")
  facet_cols <- setdiff(names(lay), c("PANEL", "ROW", "COL", "SCALE_X", "SCALE_Y", "COORD"))

  # Build panel grob name -> PANEL integer map from gtable
  panel_grob_to_num <- stats::setNames(integer(), character())
  if (!is.null(gtable)) {
    pan_rows <- grep("^panel", gtable$layout$name)
    for (j in pan_rows) {
      pg <- gtable$grobs[[j]]
      if (is.null(pg) || is.null(pg$name)) next
      pnum <- suppressWarnings(as.integer(sub("^panel-([0-9]+)\\..*$", "\\1", pg$name)))
      if (!is.na(pnum)) {
        panel_grob_to_num[[pg$name]] <- pnum
      }
    }
  }

  # Attribute every leaf to its PANEL integer via grob_path
  n_leaves <- nrow(leaves)
  leaf_panel_num <- rep(NA_integer_, n_leaves)
  if (n_leaves > 0L) {
    gpaths <- strsplit(leaves$grob_path, "/", fixed = TRUE)
    for (r in seq_len(n_leaves)) {
      segs <- gpaths[[r]]
      if (length(panel_grob_to_num) > 0L) {
        hit <- segs[segs %in% names(panel_grob_to_num)]
        if (length(hit) > 0L) {
          leaf_panel_num[[r]] <- panel_grob_to_num[[hit[[1L]]]]
          next
        }
      }
      # Fallback regex on grob_path when gtable wasn't kept (custom print.*)
      pm <- grep("^panel-[0-9]+\\.", segs, value = TRUE)
      if (length(pm) > 0L) {
        leaf_panel_num[[r]] <- suppressWarnings(as.integer(sub("^panel-([0-9]+)\\..*$", "\\1", pm[[1L]])))
      }
    }
  }

  panels <- vector("list", nrow(lay))
  panel_ids_by_num <- stats::setNames(character(nrow(lay)), as.character(lay$PANEL))

  for (i in seq_len(nrow(lay))) {
    pnum <- as.integer(as.character(lay$PANEL[[i]]))
    pid <- if (nzchar(panel_prefix)) {
      sprintf("%s_P%d", panel_prefix, pnum)
    } else {
      sprintf("P%d", pnum)
    }
    panel_ids_by_num[[as.character(pnum)]] <- pid

    fvars <- stats::setNames(list(), character())
    for (fc in facet_cols) {
      val <- lay[[fc]][[i]]
      fvars[[fc]] <- if (is.factor(val)) as.character(val) else val
    }

    # Aggregate device bbox from leaves drawn inside this panel
    in_p <- which(!is.na(leaf_panel_num) & leaf_panel_num == pnum)
    bbox_pt <- NULL
    if (length(in_p) > 0L) {
      valid <- in_p[is.finite(leaves$bbox_x0[in_p]) & is.finite(leaves$bbox_y0[in_p]) &
                      is.finite(leaves$bbox_x1[in_p]) & is.finite(leaves$bbox_y1[in_p])]
      if (length(valid) > 0L) {
        # All leaves inside the panel share the panel viewport box; take median/first
        bbox_pt <- c(
          min(leaves$bbox_x0[valid]),
          min(leaves$bbox_y0[valid]),
          max(leaves$bbox_x1[valid]),
          max(leaves$bbox_y1[valid])
        )
      }
    }

    pp <- if (pnum <= length(built$layout$panel_params)) built$layout$panel_params[[pnum]] else list()
    sx_idx <- as.integer(lay$SCALE_X[[i]])
    sy_idx <- as.integer(lay$SCALE_Y[[i]])
    sx <- if (!is.na(sx_idx) && sx_idx <= length(built$layout$panel_scales_x)) built$layout$panel_scales_x[[sx_idx]] else NULL
    sy <- if (!is.na(sy_idx) && sy_idx <= length(built$layout$panel_scales_y)) built$layout$panel_scales_y[[sy_idx]] else NULL

    panels[[i]] <- make_panel_ir(
      panel_id = pid,
      facet_vars = fvars,
      bbox_pt = bbox_pt,
      x_domain = ggplot_panel_domain(pp, "x", scale = sx),
      y_domain = ggplot_panel_domain(pp, "y", scale = sy),
      coord = coord_cls,
      flipped = flipped,
      row = as.integer(lay$ROW[[i]]),
      col = as.integer(lay$COL[[i]]),
      x_trans = if (!is.null(sx)) ggplot_scale_trans_name(sx) else NULL,
      y_trans = if (!is.null(sy)) ggplot_scale_trans_name(sy) else NULL
    )
  }

  leaf_panel <- ifelse(
    is.na(leaf_panel_num),
    NA_character_,
    unname(panel_ids_by_num[as.character(leaf_panel_num)])
  )

  list(
    panels = panels,
    leaf_panel = leaf_panel,
    leaf_panel_num = leaf_panel_num,
    panel_grob_to_num = panel_grob_to_num,
    panel_ids_by_num = panel_ids_by_num
  )
}

# --- Structural lineage construction -----------------------------------------

ggplot_build_lineage <- function(built, gtable, leaves, panel_match, layers_ir, table_prefix = "") {
  n <- nrow(leaves)
  if (n == 0L) {
    return(empty_lineage_df())
  }

  pfx <- if (nzchar(table_prefix)) paste0(table_prefix, "_") else ""
  panel_ids <- panel_match$leaf_panel %||% rep(NA_character_, n)
  panel_nums <- panel_match$leaf_panel_num %||% rep(NA_integer_, n)
  layer_ids <- rep(NA_integer_, n)
  table_ids <- rep(NA_character_, n)
  cardinalities <- rep("unlinked", n)
  n_rows_vec <- rep(NA_integer_, n)

  if (is.null(built) || length(layers_ir) == 0L) {
    return(make_lineage_df(leaves, panel_ids, layer_ids, table_ids, cardinalities, n_rows_vec))
  }

  # Map each panel child grob name -> layer_id from the drawn gtable
  child_to_layer <- stats::setNames(integer(), character())
  panel_grob_names <- names(panel_match$panel_grob_to_num %||% list())

  if (!is.null(gtable)) {
    n_layers <- length(layers_ir)
    ontop <- isTRUE(tryCatch(
      built$plot$theme$panel.ontop %||% ggplot2::theme_get()$panel.ontop,
      error = function(e) FALSE
    ))
    pan_rows <- grep("^panel", gtable$layout$name)

    for (j in pan_rows) {
      pg <- gtable$grobs[[j]]
      if (is.null(pg) || !inherits(pg, "gTree")) next
      kids <- pg$children
      nk <- length(kids)
      if (nk == n_layers + 4L) {
        # Standard ggplot2 panel children:
        # [grill, underlay_null, layer_1..layer_L, overlay_null, border]
        # (or [underlay_null, layer_1..layer_L, overlay_null, grill, border] when panel.ontop = TRUE)
        offset <- if (ontop) 1L else 2L
        for (li in seq_len(n_layers)) {
          lg <- kids[[offset + li]]
          if (!is.null(lg$name) && nzchar(lg$name)) {
            child_to_layer[[lg$name]] <- as.integer(li)
          }
        }
      } else {
        # Non-standard child count (e.g. a layer emitting a gList): match non-chrome children in order
        non_chrome <- Filter(function(k) {
          !inherits(k, c("null", "zeroGrob")) &&
            !grepl("^(grill\\.|panel\\.background|panel\\.border)", k$name %||% "")
        }, as.list(kids))
        if (length(non_chrome) == n_layers) {
          for (li in seq_len(n_layers)) {
            nm <- non_chrome[[li]]$name
            if (!is.null(nm) && nzchar(nm)) {
              child_to_layer[[nm]] <- as.integer(li)
            }
          }
        }
      }
    }
  }

  # Precompute per-(layer, panel) row counts from built$data
  layer_panel_nrow <- function(li, pnum) {
    if (is.na(li) || li > length(built$data)) return(NA_integer_)
    bdf <- built$data[[li]]
    if (!is.data.frame(bdf)) return(NA_integer_)
    if (!is.na(pnum) && "PANEL" %in% names(bdf)) {
      return(as.integer(sum(as.integer(as.character(bdf$PANEL)) == pnum, na.rm = TRUE)))
    }
    as.integer(nrow(bdf))
  }

  gpaths <- strsplit(leaves$grob_path, "/", fixed = TRUE)
  for (r in seq_len(n)) {
    segs <- gpaths[[r]]
    at <- if (length(panel_grob_names) > 0L) match(TRUE, segs %in% panel_grob_names) else NA_integer_
    if (is.na(at) || at >= length(segs)) next

    child_name <- segs[[at + 1L]]
    li <- if (child_name %in% names(child_to_layer)) child_to_layer[[child_name]] else NA_integer_
    if (is.na(li)) next

    layer_ids[[r]] <- li
    lyr <- layers_ir[[li]]
    table_ids[[r]] <- lyr$built_table %||% paste0(pfx, "built_layer", li)
    nr <- layer_panel_nrow(li, panel_nums[[r]])
    n_rows_vec[[r]] <- nr
    cardinalities[[r]] <- infer_lineage_cardinality(
      geom = lyr$geom,
      stat = lyr$stat,
      n_rows = nr,
      n_elements = leaves$n_elements[[r]]
    )
  }

  make_lineage_df(
    leaves = leaves,
    panel_id = panel_ids,
    layer_id = layer_ids,
    table_id = table_ids,
    cardinality = cardinalities,
    n_rows = n_rows_vec
  )
}
