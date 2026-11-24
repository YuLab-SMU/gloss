# Built-in ggplot2 plotting engine (Suggests: ggplot2).
#
# Performs a single ggplot_build() -> ggplot_gtable() -> grid.draw() pass so
# stochastic layers (position_jitter, stat_smooth, etc.) match original.svg,
# scene.svg, and built_layer* tables identically. Subclasses that define a
# custom print method (e.g. ggbreak) fall back to print(x) while still pinning
# stochastic jitter seeds and recovering layer lineage heuristically.

register_engine_ggplot <- function() {
  gl_register_engine(
    name = "ggplot",
    classes = c("ggplot2::ggplot", "ggplot"),
    capture_fn = engine_ggplot_capture,
    packages = "ggplot2",
    description = "ggplot2 plots: raw/built tables, row bridges, scale/guide dictionaries, layer params, facet panels, and structural lineage",
    priority = 0L,
    page_kind = "grid",
    overwrite = TRUE
  )
}

# --- Version-isolated ggplot2 compatibility accessors (ISS-GG-02) ------------

gg_compat_field <- function(obj, name, default = NULL) {
  if (is.null(obj)) return(default)
  val <- tryCatch(obj[[name]], error = function(e) NULL)
  if (!is.null(val)) return(val)
  val <- tryCatch(attr(obj, name, exact = TRUE), error = function(e) NULL)
  if (!is.null(val)) return(val)
  default
}

gg_compat_layout_df <- function(built) {
  lay_obj <- gg_compat_field(built, "layout")
  gg_compat_field(lay_obj, "layout")
}

gg_compat_panel_scales <- function(built, axis = c("x", "y")) {
  axis <- match.arg(axis)
  lay_obj <- gg_compat_field(built, "layout")
  gg_compat_field(lay_obj, paste0("panel_scales_", axis), default = list())
}

gg_compat_panel_params <- function(built, pnum) {
  lay_obj <- gg_compat_field(built, "layout")
  pps <- gg_compat_field(lay_obj, "panel_params", default = list())
  if (pnum <= length(pps)) pps[[pnum]] else list()
}

gg_compat_scales_list <- function(built) {
  plt <- gg_compat_field(built, "plot")
  sc_obj <- gg_compat_field(plt, "scales")
  gg_compat_field(sc_obj, "scales", default = list())
}

# Pin unseeded stochastic jitter positions on a shallow ggplot copy so
# print.* extensions or patchwork subplots keep identical drawn vs built coords.
pin_ggplot_stochastic_seeds <- function(plt) {
  if (!inherits(plt, c("ggplot2::ggplot", "ggplot"))) {
    return(plt)
  }
  lyrs <- plt$layers %||% list()
  if (length(lyrs) == 0L) {
    return(plt)
  }
  changed <- FALSE
  new_lyrs <- vector("list", length(lyrs))
  for (k in seq_along(lyrs)) {
    lyr <- lyrs[[k]]
    pos <- lyr$position
    if (inherits(pos, "PositionJitter") && (is.null(pos$seed) || isTRUE(is.na(pos$seed)))) {
      s <- sample.int(10000000L, 1L)
      new_pos <- ggplot2::position_jitter(width = pos$width, height = pos$height, seed = s)
      new_lyrs[[k]] <- ggplot2::ggproto(NULL, lyr, position = new_pos)
      changed <- TRUE
    } else if (inherits(pos, "PositionJitterdodge") && (is.null(pos$seed) || isTRUE(is.na(pos$seed)))) {
      s <- sample.int(10000000L, 1L)
      new_pos <- ggplot2::position_jitterdodge(
        jitter.width = pos$jitter.width,
        jitter.height = pos$jitter.height,
        dodge.width = pos$dodge.width,
        seed = s
      )
      new_lyrs[[k]] <- ggplot2::ggproto(NULL, lyr, position = new_pos)
      changed <- TRUE
    } else {
      new_lyrs[[k]] <- lyr
    }
  }
  if (changed) {
    plt$layers <- new_lyrs
  }
  plt
}

engine_ggplot_capture <- function(x, ctx) {
  owner <- ggplot_custom_print_owner(x)
  built <- NULL
  gtable <- NULL
  draw_method <- "ggplot_gtable"
  plot_use <- x

  if (is.null(owner)) {
    built <- tryCatch(ggplot2::ggplot_build(plot_use), error = function(e) NULL)
    if (!is.null(built) && inherits(built, c("ggplot2::ggplot_built", "ggplot_built"))) {
      grid::grid.newpage()
      gtable <- ggplot2::ggplot_gtable(built)
      grid::grid.draw(gtable)
      draw_method <- "ggplot_gtable"
    } else {
      print(plot_use)
      built <- NULL
      draw_method <- "print"
    }
  } else {
    plot_use <- pin_ggplot_stochastic_seeds(x)
    print(plot_use)
    draw_method <- paste0("print.", owner)
    built <- tryCatch({
      b <- ggplot2::ggplot_build(plot_use)
      if (inherits(b, c("ggplot2::ggplot_built", "ggplot_built"))) b else NULL
    }, error = function(e) NULL)
  }

  ctx$ensure_device()
  sc <- ctx$capture_grid(draw_method = draw_method)

  extracted <- extract_ggplot_ir(
    plot = plot_use,
    built = built,
    gtable = gtable,
    leaves = sc$leaves,
    elements = sc$elements,
    draw_method = draw_method
  )

  sc$elements <- extracted$elements

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
    elements = empty_elements_df(),
    panel_prefix = "",
    table_prefix = "",
    leaf_indices = NULL,
    draw_method = "ggplot_gtable",
    extract_guides = TRUE) {

  sub_leaves <- if (is.null(leaf_indices)) leaves else leaves[leaf_indices, , drop = FALSE]

  tbl_res <- ggplot_extract_tables_and_accounting(plot, built, table_prefix = table_prefix)
  tables <- tbl_res$tables
  row_acc_by_layer <- tbl_res$row_accounting
  group_indices <- tbl_res$group_indices

  layers_ir <- ggplot_extract_layers(
    plot = plot,
    built = built,
    table_prefix = table_prefix,
    row_accounting = row_acc_by_layer,
    group_indices = group_indices
  )

  panel_match <- if (!is.null(built)) {
    ggplot_match_panels(built, gtable, sub_leaves, panel_prefix = panel_prefix)
  } else {
    list(
      panels = list(),
      leaf_panel = rep(NA_character_, nrow(sub_leaves)),
      leaf_panel_num = rep(NA_integer_, nrow(sub_leaves)),
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
    table_prefix = table_prefix,
    draw_method = draw_method
  )

  # Bridge SVG elements -> built_row_id / group_id / part_role (ISS-ASSET-01)
  elements_out <- ggplot_bridge_elements(
    elements = elements,
    leaves = sub_leaves,
    lineage = lineage,
    panels = panel_match$panels,
    layers_ir = layers_ir,
    tables = tables
  )

  ir_out <- list(
    panels = panel_match$panels,
    layers = layers_ir,
    scales = scales_ir,
    orders = stats::setNames(list(), character())
  )
  if (length(group_indices) > 0L) {
    ir_out$group_indices <- group_indices
  }
  if (isTRUE(extract_guides)) {
    guides_ir <- ggplot_extract_guides(
      leaves = sub_leaves,
      elements = elements_out,
      scales_ir = scales_ir,
      collected = FALSE
    )
    if (!is.null(guides_ir)) {
      ir_out$guides <- guides_ir
    }
  }

  list(
    ir = ir_out,
    tables = tables,
    lineage = lineage,
    elements = elements_out
  )
}

# --- Tables, _raw_row_id, _group_key & row_accounting (ISS-ASSET-01 & 06) ----

ggplot_eval_aes_on_raw <- function(raw_df, quo) {
  if (is.null(raw_df) || !is.data.frame(raw_df) || is.null(quo)) return(NULL)
  tryCatch({
    val <- rlang::eval_tidy(quo, data = raw_df)
    if (length(val) == 1L && nrow(raw_df) > 1L) {
      val <- rep(val, nrow(raw_df))
    }
    if (length(val) == nrow(raw_df)) val else NULL
  }, error = function(e) NULL)
}

ggplot_effective_mapping <- function(plot, lyr) {
  plot_map <- plot$mapping %||% list()
  lyr_map <- lyr$mapping %||% list()
  if (isTRUE(lyr$inherit.aes)) {
    utils::modifyList(as.list(plot_map), as.list(lyr_map))
  } else {
    as.list(lyr_map)
  }
}

ggplot_required_pos_cols <- function(lyr, bdf) {
  req <- tryCatch(as.character(lyr$geom$required_aes), error = function(e) character())
  req <- unlist(strsplit(req, "|", fixed = TRUE))
  pos_pool <- c("x", "y", "xmin", "xmax", "ymin", "ymax", "xend", "yend")
  hits <- intersect(intersect(req, pos_pool), names(bdf))
  if (length(hits) == 0L) {
    hits <- intersect(c("x", "y"), names(bdf))
  }
  hits
}

ggplot_build_group_index <- function(raw_df, bdf, built, eff_map) {
  if (!is.data.frame(raw_df) || nrow(raw_df) == 0L ||
      !is.data.frame(bdf) || nrow(bdf) == 0L ||
      !("PANEL" %in% names(bdf)) || !("group" %in% names(bdf))) {
    return(NULL)
  }
  lay <- gg_compat_layout_df(built)
  if (is.null(lay) || nrow(lay) == 0L) return(NULL)

  facet_cols <- setdiff(names(lay), c("PANEL", "ROW", "COL", "SCALE_X", "SCALE_Y", "COORD"))
  n_raw <- nrow(raw_df)

  # Map each raw row to its PANEL integer(s) via facet columns
  raw_panel <- rep(1L, n_raw)
  if (length(facet_cols) > 0L) {
    raw_panel <- rep(NA_integer_, n_raw)
    for (p_i in seq_len(nrow(lay))) {
      mask <- rep(TRUE, n_raw)
      for (fc in facet_cols) {
        if (fc %in% names(raw_df)) {
          lv <- as.character(lay[[fc]][[p_i]])
          rv <- as.character(raw_df[[fc]])
          mask <- mask & !is.na(rv) & (rv == lv)
        }
      }
      raw_panel[mask] <- as.integer(as.character(lay$PANEL[[p_i]]))
    }
  }

  # Evaluate discrete grouping columns on raw_df
  disc_aes <- intersect(c("x", "y", "colour", "fill", "group", "shape", "linetype"), names(eff_map))
  raw_disc <- list()
  for (an in disc_aes) {
    v <- ggplot_eval_aes_on_raw(raw_df, eff_map[[an]])
    if (!is.null(v) && (is.factor(v) || is.character(v) || is.logical(v))) {
      raw_disc[[an]] <- as.character(v)
    }
  }

  # Match each unique (PANEL, group) in bdf to raw_row_ids
  gkeys <- unique(bdf[["_group_key"]])
  out <- stats::setNames(vector("list", length(gkeys)), gkeys)
  px_scales <- gg_compat_panel_scales(built, "x")
  py_scales <- gg_compat_panel_scales(built, "y")
  all_scales <- gg_compat_scales_list(built)

  for (gk in gkeys) {
    sub_b <- bdf[bdf[["_group_key"]] == gk, , drop = FALSE]
    pnum <- as.integer(as.character(sub_b$PANEL[[1L]]))
    mask <- !is.na(raw_panel) & (raw_panel == pnum)

    # Narrow by discrete x / y position if applicable
    if ("x" %in% names(raw_disc) && "x" %in% names(sub_b) && length(px_scales) > 0L) {
      sx_idx <- lay$SCALE_X[as.integer(as.character(lay$PANEL)) == pnum]
      sx <- if (length(sx_idx) > 0L && sx_idx[[1L]] <= length(px_scales)) px_scales[[sx_idx[[1L]]]] else NULL
      if (!is.null(sx) && isTRUE(tryCatch(sx$is_discrete(), error = function(e) FALSE))) {
        lims <- tryCatch(as.character(sx$get_limits()), error = function(e) character())
        bx_pos <- unique(round(as.numeric(sub_b$x)))
        bx_pos <- bx_pos[is.finite(bx_pos) & bx_pos >= 1L & bx_pos <= length(lims)]
        if (length(bx_pos) > 0L) {
          mask <- mask & !is.na(raw_disc$x) & (raw_disc$x %in% lims[bx_pos])
        }
      }
    }
    if ("y" %in% names(raw_disc) && "y" %in% names(sub_b) && length(py_scales) > 0L) {
      sy_idx <- lay$SCALE_Y[as.integer(as.character(lay$PANEL)) == pnum]
      sy <- if (length(sy_idx) > 0L && sy_idx[[1L]] <= length(py_scales)) py_scales[[sy_idx[[1L]]]] else NULL
      if (!is.null(sy) && isTRUE(tryCatch(sy$is_discrete(), error = function(e) FALSE))) {
        lims <- tryCatch(as.character(sy$get_limits()), error = function(e) character())
        by_pos <- unique(round(as.numeric(sub_b$y)))
        by_pos <- by_pos[is.finite(by_pos) & by_pos >= 1L & by_pos <= length(lims)]
        if (length(by_pos) > 0L) {
          mask <- mask & !is.na(raw_disc$y) & (raw_disc$y %in% lims[by_pos])
        }
      }
    }

    # Narrow by discrete non-position aesthetics (colour, fill, shape, linetype)
    for (sc in all_scales) {
      if (!isTRUE(tryCatch(sc$is_discrete(), error = function(e) FALSE))) next
      aes_nms <- tryCatch(as.character(sc$aesthetics), error = function(e) character())
      if (length(aes_nms) == 0L || aes_nms[[1L]] %in% c("x", "y")) next
      hit_aes <- intersect(aes_nms, intersect(names(raw_disc), names(sub_b)))
      if (length(hit_aes) == 0L) next
      an <- hit_aes[[1L]]
      lims <- tryCatch(as.character(sc$get_limits()), error = function(e) character())
      if (length(lims) == 0L) next
      mapped <- tryCatch(as.character(sc$map(lims)), error = function(e) character())
      bvals <- unique(as.character(sub_b[[an]]))
      dom_hits <- lims[mapped %in% bvals]
      if (length(dom_hits) > 0L) {
        mask <- mask & !is.na(raw_disc[[an]]) & (raw_disc[[an]] %in% dom_hits)
      }
    }

    out[[gk]] <- json_array(which(mask))
  }
  out
}

ggplot_extract_tables_and_accounting <- function(plot, built, table_prefix = "") {
  tables <- stats::setNames(list(), character())
  row_accounting <- list()
  group_indices <- stats::setNames(list(), character())
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
    built_layers <- if (length(built$plot$layers) > 0L) built$plot$layers else plot_layers
    for (i in seq_along(built$data)) {
      bdf <- built$data[[i]]
      if (!is.data.frame(bdf)) next

      tbl_id <- paste0(pfx, "built_layer", i)
      lyr <- if (i <= length(built_layers)) built_layers[[i]] else NULL
      raw_df <- if (!is.null(lyr) && is.data.frame(lyr$data)) {
        lyr$data
      } else if (is.data.frame(plot_data)) {
        plot_data
      } else {
        NULL
      }

      stat_cls <- if (!is.null(lyr)) class(lyr$stat)[[1L]] else "StatIdentity"
      is_ident_stat <- stat_cls %in% c("StatIdentity", "identity")
      eff_map <- if (!is.null(lyr)) ggplot_effective_mapping(plot, lyr) else list()

      # Add _group_key whenever PANEL & group exist
      if ("PANEL" %in% names(bdf) && "group" %in% names(bdf) && nrow(bdf) > 0L) {
        bdf[["_group_key"]] <- paste0("P", as.character(bdf$PANEL), "_G", as.character(bdf$group))
      }

      # Compute _raw_row_id and row_accounting
      req_cols <- if (!is.null(lyr)) ggplot_required_pos_cols(lyr, bdf) else intersect(c("x", "y"), names(bdf))
      if (is_ident_stat && is.data.frame(raw_df) && nrow(raw_df) > 0L && nrow(bdf) == nrow(raw_df)) {
        rn_int <- suppressWarnings(as.integer(rownames(bdf)))
        raw_ids <- if (!anyNA(rn_int) && length(unique(rn_int)) == nrow(bdf) &&
                       all(rn_int >= 1L & rn_int <= nrow(raw_df))) {
          rn_int
        } else {
          seq_len(nrow(raw_df))
        }
        bdf[["_raw_row_id"]] <- as.integer(raw_ids)

        # Determine rows dropped by NA vs OOB censoring in required position aesthetics
        built_bad <- rep(FALSE, nrow(bdf))
        for (rc in req_cols) {
          col_v <- bdf[[rc]]
          if (is.numeric(col_v)) {
            built_bad <- built_bad | !is.finite(col_v)
          } else {
            built_bad <- built_bad | is.na(col_v)
          }
        }
        raw_na <- rep(FALSE, nrow(raw_df))
        for (rc in intersect(req_cols, names(eff_map))) {
          rv <- ggplot_eval_aes_on_raw(raw_df, eff_map[[rc]])
          if (!is.null(rv)) {
            if (is.numeric(rv)) {
              raw_na <- raw_na | !is.finite(rv)
            } else {
              raw_na <- raw_na | is.na(rv)
            }
          }
        }
        dropped_mask <- built_bad
        dropped_na_mask <- dropped_mask & raw_na[raw_ids]
        dropped_oob_mask <- dropped_mask & !raw_na[raw_ids]
        dropped_ids <- raw_ids[dropped_mask]

        acc_ent <- list(
          n_raw = as.integer(nrow(raw_df)),
          n_built = as.integer(sum(!dropped_mask)),
          n_dropped_na = as.integer(sum(dropped_na_mask)),
          n_dropped_oob = as.integer(sum(dropped_oob_mask))
        )
        if (length(dropped_ids) > 0L) {
          acc_ent$dropped_raw_row_ids <- json_array(as.integer(utils::head(dropped_ids, 200L)))
        }
        row_accounting[[i]] <- acc_ent
      } else if (is.data.frame(raw_df) && nrow(raw_df) > 0L) {
        # Aggregated stat or filtered layer: build group_key -> raw_row_ids index + raw NA count
        raw_na <- rep(FALSE, nrow(raw_df))
        for (rc in intersect(c("x", "y"), names(eff_map))) {
          rv <- ggplot_eval_aes_on_raw(raw_df, eff_map[[rc]])
          if (!is.null(rv)) {
            raw_na <- raw_na | (if (is.numeric(rv)) !is.finite(rv) else is.na(rv))
          }
        }
        row_accounting[[i]] <- list(
          n_raw = as.integer(nrow(raw_df)),
          n_built = as.integer(nrow(bdf)),
          n_dropped_na = as.integer(sum(raw_na)),
          n_dropped_oob = 0L
        )
        if ("_group_key" %in% names(bdf)) {
          gidx <- ggplot_build_group_index(raw_df, bdf, built, eff_map)
          if (!is.null(gidx) && length(gidx) > 0L) {
            group_indices[[tbl_id]] <- gidx
          }
        }
      }

      # Also build group index for N:1 identity geoms (e.g. GeomLine / GeomRibbon)
      if (is_ident_stat && "_group_key" %in% names(bdf) && "_raw_row_id" %in% names(bdf) &&
          !(tbl_id %in% names(group_indices)) && nrow(bdf) > 0L) {
        geom_cls <- if (!is.null(lyr)) class(lyr$geom)[[1L]] else ""
        if (geom_cls %in% c("GeomLine", "GeomPath", "GeomArea", "GeomRibbon", "GeomPolygon", "GeomStep")) {
          split_ids <- split(bdf[["_raw_row_id"]], bdf[["_group_key"]])
          group_indices[[tbl_id]] <- lapply(split_ids, function(v) json_array(as.integer(v)))
        }
      }

      tables[[tbl_id]] <- list(
        table_id = tbl_id,
        role = "built",
        key = character(),
        layer_id = as.integer(i),
        data = bdf
      )
    }
  }

  list(
    tables = tables,
    row_accounting = row_accounting,
    group_indices = group_indices
  )
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

# --- Layers recipe & full params extraction (ISS-ASSET-06) -------------------

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

identify_known_stat_fn <- function(fn) {
  if (!is.function(fn)) return(NULL)
  candidates <- list(
    mean_se = tryCatch(ggplot2::mean_se, error = function(e) NULL),
    mean_sdl = tryCatch(ggplot2::mean_sdl, error = function(e) NULL),
    mean_cl_normal = tryCatch(ggplot2::mean_cl_normal, error = function(e) NULL),
    mean_cl_boot = tryCatch(ggplot2::mean_cl_boot, error = function(e) NULL),
    median_hilow = tryCatch(ggplot2::median_hilow, error = function(e) NULL),
    mean = base::mean,
    median = stats::median,
    sd = stats::sd,
    sum = base::sum,
    min = base::min,
    max = base::max
  )
  for (nm in names(candidates)) {
    if (!is.null(candidates[[nm]]) && identical(fn, candidates[[nm]])) {
      return(nm)
    }
  }
  hdr <- tryCatch(trimws(paste(deparse(args(fn))[[1L]], collapse = " ")), error = function(e) "function")
  sub("^function\\s*", "function", hdr)
}

sanitize_layer_params <- function(...) {
  sources <- list(...)
  keep <- list()
  for (params in sources) {
    if (!is.list(params) || length(params) == 0L) next
    for (nm in names(params)) {
      if (is.null(nm) || !nzchar(nm)) next
      val <- params[[nm]]
      if (is.null(val)) next
      if (inherits(val, "formula")) {
        keep[[nm]] <- trimws(paste(deparse(val), collapse = " "))
      } else if (is.function(val)) {
        keep[[nm]] <- identify_known_stat_fn(val)
      } else if (grid::is.unit(val)) {
        u_txt <- tryCatch(as.character(val), error = function(e) NULL)
        if (!is.null(u_txt) && length(u_txt) > 0L && length(u_txt) <= 10L) {
          keep[[nm]] <- if (length(u_txt) == 1L) u_txt else json_array(u_txt)
        }
      } else if (is.atomic(val) && length(val) > 0L && length(val) <= 10L) {
        if (length(val) == 1L && is.na(val)) next
        # Strip custom S3 atomic classes (e.g. rel, margin) so jsonlite never fails
        clean_v <- if (is.object(val) && !inherits(val, c("Date", "POSIXct", "POSIXlt"))) {
          if (is.factor(val)) as.character(val) else unclass(val)
        } else {
          val
        }
        if (is.numeric(clean_v)) clean_v <- as.numeric(clean_v)
        else if (is.logical(clean_v)) clean_v <- as.logical(clean_v)
        else if (is.character(clean_v)) clean_v <- as.character(clean_v)
        keep[[nm]] <- if (length(clean_v) == 1L) clean_v else json_array(clean_v)
      }
    }
  }
  if (length(keep) == 0L) NULL else keep
}

extract_position_params <- function(pos) {
  if (is.null(pos)) return(NULL)
  out <- list()
  for (nm in c("width", "height", "jitter.width", "jitter.height", "dodge.width", "vjust", "reverse")) {
    v <- tryCatch(pos[[nm]], error = function(e) NULL)
    if (!is.null(v) && is.atomic(v) && length(v) == 1L && !is.na(v)) {
      out[[paste0("position_", nm)]] <- v
    }
  }
  if (length(out) == 0L) NULL else out
}

ggplot_extract_layers <- function(
    plot,
    built,
    table_prefix = "",
    row_accounting = list(),
    group_indices = list()) {

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
    built_df <- if (!is.null(built) && i <= length(built$data) && is.data.frame(built$data[[i]])) {
      built$data[[i]]
    } else {
      NULL
    }
    built_tbl <- if (!is.null(built_df)) paste0(pfx, "built_layer", i) else NULL
    geom_cls <- class(lyr$geom)[[1L]]
    stat_cls <- class(lyr$stat)[[1L]]

    full_params <- sanitize_layer_params(
      lyr$stat_params,
      lyr$geom_params,
      lyr$aes_params,
      extract_position_params(lyr$position)
    )
    r_acc <- if (i <= length(row_accounting)) row_accounting[[i]] else NULL
    g_ref <- if (!is.null(built_tbl) && built_tbl %in% names(group_indices)) {
      paste0("tables/groups_", built_tbl, ".json")
    } else {
      NULL
    }

    make_layer_ir(
      layer_id = i,
      geom = geom_cls,
      stat = stat_cls,
      position = class(lyr$position)[[1L]],
      aes = eff_aes,
      raw_table = raw_tbl,
      built_table = built_tbl,
      params = full_params,
      stat_columns = infer_stat_columns(built_df, stat_name = stat_cls, geom_name = geom_cls),
      row_accounting = r_acc,
      group_index_ref = g_ref
    )
  })
}

# --- Scales & continuous color stops extraction (ISS-ASSET-02 & ISS-GG-04) ---

ggplot_scale_trans_name <- function(sc) {
  if (isTRUE(tryCatch(sc$is_discrete(), error = function(e) FALSE))) {
    return("discrete")
  }
  tr <- tryCatch(sc$get_transformation(), error = function(e) NULL)
  if (is.null(tr)) tr <- tryCatch(sc$trans, error = function(e) NULL)
  if (is.null(tr)) return("identity")
  normalize_trans_name(tr$name %||% "identity")
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
  # Check layer-specific renamed aesthetics first (e.g. ggnewscale colour_new)
  lyrs <- plot$layers %||% list()
  for (l in lyrs) {
    m <- l$mapping
    if (is.null(m) || length(m) == 0L) next
    hit <- intersect(aes_names, names(m))
    if (length(hit) > 0L) {
      return(quo_to_label(m[[hit[[1L]]]]))
    }
  }
  pm <- plot$mapping
  if (!is.null(pm) && length(pm) > 0L) {
    hit <- intersect(aes_names, names(pm))
    if (length(hit) > 0L) {
      return(quo_to_label(pm[[hit[[1L]]]]))
    }
  }
  NULL
}

ggplot_scale_oob_name <- function(sc) {
  oob_fn <- tryCatch(sc$oob, error = function(e) NULL)
  if (is.null(oob_fn)) return(NULL)
  body_txt <- tryCatch(paste(deparse(oob_fn), collapse = " "), error = function(e) "")
  if (grepl("squish", body_txt, ignore.case = TRUE)) return("squish")
  if (grepl("keep", body_txt, ignore.case = TRUE)) return("keep")
  if (grepl("censor", body_txt, ignore.case = TRUE)) return("censor")
  # Check closure environment for ggplot2 ggproto_method wrapping scales::oob_*
  env_fn <- tryCatch(environment(oob_fn)$f %||% environment(oob_fn)$oob, error = function(e) NULL)
  if (is.function(env_fn)) {
    et <- paste(deparse(env_fn), collapse = " ")
    if (grepl("squish|pmax|pmin", et, ignore.case = TRUE)) return("squish")
    if (grepl("censor|NA", et, ignore.case = TRUE)) return("censor")
    if (grepl("return\\(x\\)|^function\\s*\\(x", et)) return("keep")
  }
  "censor"
}

ggplot_scale_midpoint <- function(sc) {
  resc <- tryCatch(sc$rescaler, error = function(e) NULL)
  if (!is.function(resc)) return(NULL)
  env1 <- environment(resc)
  mid <- tryCatch(env1$mid, error = function(e) NULL)
  if (is.null(mid) && is.environment(env1)) {
    inner_f <- tryCatch(env1$f %||% env1$fun %||% env1$rescaler, error = function(e) NULL)
    if (is.function(inner_f)) {
      mid <- tryCatch(environment(inner_f)$mid %||% environment(inner_f)$trans_mid, error = function(e) NULL)
    }
  }
  if (is.numeric(mid) && length(mid) == 1L && is.finite(mid)) as.numeric(mid) else NULL
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
  stops_entries <- NULL
  na_val <- NULL
  oob_val <- NULL
  mid_val <- NULL

  if (!is_position) {
    na_raw <- tryCatch(sc$na.value, error = function(e) NULL)
    if (!is.null(na_raw) && length(na_raw) == 1L && !is.na(na_raw)) {
      na_val <- as.character(na_raw)
    }
    if (!is_disc) {
      oob_val <- ggplot_scale_oob_name(sc)
      mid_val <- ggplot_scale_midpoint(sc)
    }

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

      # Standardized 11-stop normalized continuous color/value ramp (ISS-ASSET-02)
      stop_pos <- seq(0.0, 1.0, length.out = 11L)
      stop_dom <- lims[[1L]] + stop_pos * (lims[[2L]] - lims[[1L]])
      stop_vals <- tryCatch(sc$map(stop_dom), error = function(e) rep(NA, length(stop_dom)))
      stops_entries <- lapply(seq_along(stop_pos), function(k) {
        val <- stop_vals[[k]]
        if (length(val) == 1L && is.na(val)) val <- NULL
        list(
          pos = round(stop_pos[[k]], 4L),
          domain = as.numeric(stop_dom[[k]]),
          value = val
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
    limits = if (!is_disc && is.numeric(lims) && length(lims) == 2L && all(is.finite(lims))) lims else NULL,
    breaks = clean_brks,
    labels = clean_lbls,
    trans = trans_name,
    name = scale_name,
    panel_ids = panel_ids,
    stops = stops_entries,
    na_value = na_val,
    oob = oob_val,
    midpoint = mid_val
  )
}

ggplot_extract_scales <- function(plot, built, panel_ids_by_num = NULL) {
  out <- list()
  lay <- gg_compat_layout_df(built)

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

  px <- gg_compat_panel_scales(built, "x")
  if (length(px) > 0L) {
    multi_x <- length(px) > 1L
    for (k in seq_along(px)) {
      if (is.null(px[[k]])) next
      pids <- if (multi_x) panels_for_scale("SCALE_X", k) else NULL
      out[[length(out) + 1L]] <- ggplot_serialize_scale(px[[k]], plot, primary_aes = "x", panel_ids = pids)
    }
  }
  py <- gg_compat_panel_scales(built, "y")
  if (length(py) > 0L) {
    multi_y <- length(py) > 1L
    for (k in seq_along(py)) {
      if (is.null(py[[k]])) next
      pids <- if (multi_y) panels_for_scale("SCALE_Y", k) else NULL
      out[[length(out) + 1L]] <- ggplot_serialize_scale(py[[k]], plot, primary_aes = "y", panel_ids = pids)
    }
  }

  all_scales <- gg_compat_scales_list(built)
  for (sc in all_scales) {
    aesthetics <- tryCatch(as.character(sc$aesthetics), error = function(e) character())
    if (length(aesthetics) == 0L || aesthetics[[1L]] %in% c("x", "y")) next
    out[[length(out) + 1L]] <- ggplot_serialize_scale(sc, plot, primary_aes = aesthetics[[1L]])
  }

  out
}

# --- Panels matching, coordinate domains & shared axes (ISS-ASSET-02 & 05) ---

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
      return(c(0.4, length(lims) + 0.6))
    }
  }
  NULL
}

ggplot_discrete_breaks_pos <- function(scale) {
  if (is.null(scale)) return(NULL)
  if (!isTRUE(tryCatch(scale$is_discrete(), error = function(e) FALSE))) return(NULL)
  lims <- tryCatch(as.character(scale$get_limits()), error = function(e) character())
  if (length(lims) == 0L) return(NULL)
  lapply(seq_along(lims), function(k) {
    list(domain = lims[[k]], pos = as.numeric(k))
  })
}

ggplot_match_panels <- function(built, gtable, leaves, panel_prefix = "") {
  lay <- gg_compat_layout_df(built)
  if (is.null(lay) || nrow(lay) == 0L) {
    return(list(
      panels = list(),
      leaf_panel = rep(NA_character_, nrow(leaves)),
      leaf_panel_num = rep(NA_integer_, nrow(leaves)),
      panel_grob_to_num = stats::setNames(integer(), character()),
      panel_ids_by_num = stats::setNames(character(), character())
    ))
  }

  lay_obj <- gg_compat_field(built, "layout")
  coord_obj <- gg_compat_field(lay_obj, "coord")
  coord_cls <- if (!is.null(coord_obj)) class(coord_obj)[[1L]] else "CoordCartesian"
  flipped <- inherits(coord_obj, "CoordFlip")
  facet_cols <- setdiff(names(lay), c("PANEL", "ROW", "COL", "SCALE_X", "SCALE_Y", "COORD"))

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
      pm <- grep("^panel-[0-9]+\\.", segs, value = TRUE)
      if (length(pm) > 0L) {
        leaf_panel_num[[r]] <- suppressWarnings(as.integer(sub("^panel-([0-9]+)\\..*$", "\\1", pm[[1L]])))
      }
    }
  }

  panels <- vector("list", nrow(lay))
  panel_ids_by_num <- stats::setNames(character(nrow(lay)), as.character(lay$PANEL))
  px_scales <- gg_compat_panel_scales(built, "x")
  py_scales <- gg_compat_panel_scales(built, "y")
  ag_pfx <- if (nzchar(panel_prefix)) paste0(panel_prefix, "_") else ""

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

    in_p <- which(!is.na(leaf_panel_num) & leaf_panel_num == pnum)
    bbox_pt <- NULL
    if (length(in_p) > 0L) {
      valid <- in_p[is.finite(leaves$bbox_x0[in_p]) & is.finite(leaves$bbox_y0[in_p]) &
                      is.finite(leaves$bbox_x1[in_p]) & is.finite(leaves$bbox_y1[in_p])]
      if (length(valid) > 0L) {
        bbox_pt <- c(
          min(leaves$bbox_x0[valid]),
          min(leaves$bbox_y0[valid]),
          max(leaves$bbox_x1[valid]),
          max(leaves$bbox_y1[valid])
        )
      }
    }

    pp <- gg_compat_panel_params(built, pnum)
    sx_idx <- as.integer(lay$SCALE_X[[i]])
    sy_idx <- as.integer(lay$SCALE_Y[[i]])
    sx <- if (!is.na(sx_idx) && sx_idx <= length(px_scales)) px_scales[[sx_idx]] else NULL
    sy <- if (!is.na(sy_idx) && sy_idx <= length(py_scales)) py_scales[[sy_idx]] else NULL

    panels[[i]] <- make_panel_ir(
      panel_id = pid,
      facet_vars = fvars,
      bbox_pt = bbox_pt,
      x_domain = ggplot_panel_domain(pp, "x", scale = if (flipped) sy else sx),
      y_domain = ggplot_panel_domain(pp, "y", scale = if (flipped) sx else sy),
      coord = coord_cls,
      flipped = flipped,
      row = as.integer(lay$ROW[[i]]),
      col = as.integer(lay$COL[[i]]),
      x_trans = if (!is.null(sx)) ggplot_scale_trans_name(sx) else "identity",
      y_trans = if (!is.null(sy)) ggplot_scale_trans_name(sy) else "identity",
      domain_space = "transformed",
      expansion_included = TRUE,
      x_breaks_pos = ggplot_discrete_breaks_pos(if (flipped) sy else sx),
      y_breaks_pos = ggplot_discrete_breaks_pos(if (flipped) sx else sy),
      x_axis_group = if (!is.na(sx_idx)) paste0(ag_pfx, "scale_x_", sx_idx) else NULL,
      y_axis_group = if (!is.na(sy_idx)) paste0(ag_pfx, "scale_y_", sy_idx) else NULL
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

# --- Structural lineage with empty-layer & custom print.* self-healing -------

geom_to_grob_hints <- function(geom_cls) {
  switch(
    as.character(geom_cls %||% "")[[1L]],
    GeomPoint = c("geom_point", "points"),
    GeomLine = c("geom_line", "polyline", "lines"),
    GeomPath = c("geom_path", "polyline", "lines"),
    GeomBar = c("geom_rect", "rect"),
    GeomCol = c("geom_rect", "rect"),
    GeomRect = c("geom_rect", "rect"),
    GeomTile = c("geom_rect", "geom_polygon", "rect", "raster"),
    GeomBoxplot = c("geom_boxplot", "geom_crossbar"),
    GeomViolin = c("geom_violin", "geom_polygon", "polygon"),
    GeomRibbon = c("geom_ribbon", "geom_polygon", "polygon"),
    GeomArea = c("geom_ribbon", "geom_polygon", "polygon"),
    GeomSmooth = c("geom_smooth", "geom_ribbon", "polyline"),
    GeomErrorbar = c("geom_errorbar", "polyline", "segments"),
    GeomPointrange = c("geom_pointrange", "segments", "points"),
    GeomCrossbar = c("geom_crossbar", "polygon", "segments"),
    GeomLinerange = c("geom_linerange", "segments"),
    GeomSegment = c("geom_segment", "segments"),
    GeomHline = c("geom_hline", "segments", "polyline"),
    GeomVline = c("geom_vline", "segments", "polyline"),
    GeomAbline = c("geom_abline", "segments", "polyline"),
    GeomText = c("geom_text", "text"),
    GeomLabel = c("geom_label", "labelgrob", "text"),
    GeomTextRepel = c("textrepel", "repel", "geom_text_repel"),
    GeomLabelRepel = c("labelrepel", "repel", "geom_label_repel"),
    GeomPolygon = c("geom_polygon", "polygon"),
    GeomSf = c("geom_sf", "pathgrob", "polygon", "points", "polyline"),
    c(tolower(gsub("([A-Z])", "_\\1", sub("^Geom", "", as.character(geom_cls %||% "")))))
  )
}

is_dynamic_make_content_leaf <- function(grob_name, grob_path, grob_class, geom_cls = "") {
  if (grepl("Repel$", as.character(geom_cls %||% ""))) return(TRUE)
  if (grepl("repel", paste(grob_name, grob_path, grob_class), ignore.case = TRUE)) return(TRUE)
  # Check non-core grid classes carrying a custom makeContent S3 method
  std_grid <- c("points", "lines", "polyline", "segments", "polygon", "pathgrob",
                "rect", "circle", "text", "rastergrob", "xspline", "beziergrob",
                "curve", "null", "zeroGrob", "gTree", "grob", "GridGroup")
  if (!is.na(grob_class) && nzchar(grob_class) && !(grob_class %in% std_grid)) {
    m <- tryCatch(utils::getS3method("makeContent", grob_class, optional = TRUE), error = function(e) NULL)
    if (!is.null(m)) return(TRUE)
  }
  FALSE
}

ggplot_match_children_to_layers <- function(kids, layers_ir, ontop = FALSE) {
  out <- stats::setNames(integer(), character())
  n_layers <- length(layers_ir)
  nk <- length(kids)
  if (nk == 0L || n_layers == 0L) return(out)

  if (nk == n_layers + 4L) {
    # Standard ggplot2 panel children:
    # [grill, underlay_null, layer_1..layer_L, overlay_null, border]
    offset <- if (ontop) 1L else 2L
    for (li in seq_len(n_layers)) {
      lg <- kids[[offset + li]]
      if (!is.null(lg$name) && nzchar(lg$name) && !inherits(lg, c("null", "zeroGrob"))) {
        out[[lg$name]] <- as.integer(li)
      }
    }
    return(out)
  }

  # ISS-GG-02: Non-standard child count or panel containing empty zeroGrob layers.
  # Strip only known panel chrome (grill, background, border) and outer underlay/overlay
  # sentinels, keeping inner layer zeroGrobs or matching remaining children by geom hints.
  kid_list <- as.list(kids)
  is_chrome <- vapply(kid_list, function(k) {
    nm <- k$name %||% ""
    grepl("^(grill\\.|panel\\.background|panel\\.border)", nm)
  }, logical(1L))
  non_chrome_all <- kid_list[!is_chrome]

  # Strip outer underlay/overlay zeroGrobs if exactly n_layers + 2 remain
  if (length(non_chrome_all) == n_layers + 2L &&
      inherits(non_chrome_all[[1L]], c("null", "zeroGrob")) &&
      inherits(non_chrome_all[[length(non_chrome_all)]], c("null", "zeroGrob"))) {
    inner <- non_chrome_all[2:(length(non_chrome_all) - 1L)]
    for (li in seq_len(n_layers)) {
      lg <- inner[[li]]
      if (!is.null(lg$name) && nzchar(lg$name) && !inherits(lg, c("null", "zeroGrob"))) {
        out[[lg$name]] <- as.integer(li)
      }
    }
    return(out)
  }

  # Match visible non-chrome children against layers_ir in order using geom hints
  vis <- Filter(function(k) !inherits(k, c("null", "zeroGrob")), non_chrome_all)
  if (length(vis) == n_layers) {
    for (li in seq_len(n_layers)) {
      nm <- vis[[li]]$name
      if (!is.null(nm) && nzchar(nm)) out[[nm]] <- as.integer(li)
    }
    return(out)
  }

  # Partial / greedy monotonic geom-signature match so empty layers never break sibling layers
  used_layers <- logical(n_layers)
  last_li <- 0L
  for (vg in vis) {
    nm <- vg$name %||% ""
    if (!nzchar(nm)) next
    low_nm <- tolower(nm)
    best_li <- NA_integer_
    for (li in seq_len(n_layers)) {
      if (used_layers[[li]]) next
      hints <- geom_to_grob_hints(layers_ir[[li]]$geom)
      if (any(vapply(hints, function(h) grepl(h, low_nm, fixed = TRUE), logical(1L)))) {
        best_li <- li
        if (li > last_li) break
      }
    }
    if (!is.na(best_li)) {
      out[[nm]] <- as.integer(best_li)
      used_layers[[best_li]] <- TRUE
      last_li <- best_li
    }
  }
  out
}

ggplot_build_lineage <- function(
    built,
    gtable,
    leaves,
    panel_match,
    layers_ir,
    table_prefix = "",
    draw_method = "ggplot_gtable") {

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
  deg_reasons <- rep(NA_character_, n)

  if (is.null(built) || length(layers_ir) == 0L) {
    return(make_lineage_df(leaves, panel_ids, layer_ids, table_ids, cardinalities, n_rows_vec,
                           degradation_reason = deg_reasons))
  }

  child_to_layer <- stats::setNames(integer(), character())
  panel_grob_names <- names(panel_match$panel_grob_to_num %||% list())

  if (!is.null(gtable)) {
    ontop <- isTRUE(tryCatch(
      built$plot$theme$panel.ontop %||% ggplot2::theme_get()$panel.ontop,
      error = function(e) FALSE
    ))
    pan_rows <- grep("^panel", gtable$layout$name)

    for (j in pan_rows) {
      pg <- gtable$grobs[[j]]
      if (is.null(pg) || !inherits(pg, "gTree")) next
      matched <- ggplot_match_children_to_layers(pg$children, layers_ir, ontop = ontop)
      if (length(matched) > 0L) {
        child_to_layer[names(matched)] <- matched
      }
    }
  }

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
  n_layers <- length(layers_ir)

  for (r in seq_len(n)) {
    segs <- gpaths[[r]]
    li <- NA_integer_
    via_heuristic <- FALSE

    if (length(panel_grob_names) > 0L) {
      at <- match(TRUE, segs %in% panel_grob_names)
      if (!is.na(at) && at < length(segs)) {
        child_name <- segs[[at + 1L]]
        if (child_name %in% names(child_to_layer)) {
          li <- child_to_layer[[child_name]]
        }
      }
    }

    # ISS-GG-01: Heuristic fallback when gtable is NULL (e.g. custom print.ggbreak / aplot)
    if (is.na(li) && is.null(gtable) && grepl("^panel", leaves$layout_slot[[r]])) {
      gn <- leaves$grob_name[[r]]
      gp <- leaves$grob_path[[r]]
      if (!grepl("^(grill\\.|panel\\.background|panel\\.border|panel\\.grid)", gn) &&
          !grepl("grill\\.", gp)) {
        low_sig <- tolower(paste(gn, gp))
        for (cand_li in seq_len(n_layers)) {
          hints <- geom_to_grob_hints(layers_ir[[cand_li]]$geom)
          if (any(vapply(hints, function(h) grepl(h, low_sig, fixed = TRUE), logical(1L)))) {
            li <- cand_li
            via_heuristic <- TRUE
            break
          }
        }
      }
    }

    if (is.na(li)) next

    layer_ids[[r]] <- li
    lyr <- layers_ir[[li]]
    table_ids[[r]] <- lyr$built_table %||% paste0(pfx, "built_layer", li)
    nr <- layer_panel_nrow(li, panel_nums[[r]])
    n_rows_vec[[r]] <- nr

    is_dyn <- is_dynamic_make_content_leaf(leaves$grob_name[[r]], leaves$grob_path[[r]], leaves$grob_class[[r]], lyr$geom)
    cardinalities[[r]] <- infer_lineage_cardinality(
      geom = lyr$geom,
      stat = lyr$stat,
      n_rows = nr,
      n_elements = leaves$n_elements[[r]],
      dynamic_draw = is_dyn
    )
    if (is_dyn) {
      deg_reasons[[r]] <- paste0("dynamic_makeContent:", lyr$geom)
    } else if (isTRUE(via_heuristic)) {
      deg_reasons[[r]] <- paste0("custom_print_heuristic:", draw_method)
    }
  }

  make_lineage_df(
    leaves = leaves,
    panel_id = panel_ids,
    layer_id = layer_ids,
    table_id = table_ids,
    cardinality = cardinalities,
    n_rows = n_rows_vec,
    degradation_reason = deg_reasons
  )
}

# --- Element-to-built-row & composite part_role bridging (ISS-ASSET-01) ------

ggplot_bridge_elements <- function(elements, leaves, lineage, panels, layers_ir, tables) {
  if (!is.data.frame(elements) || nrow(elements) == 0L ||
      !is.data.frame(lineage) || nrow(lineage) == 0L) {
    return(elements)
  }
  elements <- ensure_df_columns(elements, empty_elements_df())

  panel_by_id <- stats::setNames(panels, vapply(panels, `[[`, character(1L), "panel_id"))
  layer_by_id <- stats::setNames(layers_ir, vapply(layers_ir, function(l) as.character(l$layer_id), character(1L)))
  leaf_by_id <- stats::setNames(seq_len(nrow(leaves)), leaves$leaf_id)

  for (r in seq_len(nrow(lineage))) {
    li <- lineage$layer_id[[r]]
    tid <- lineage$table_id[[r]]
    pid <- lineage$panel_id[[r]]
    lid <- lineage$leaf_id[[r]]
    if (is.na(li) || is.na(tid) || !(tid %in% names(tables))) next

    el_idx <- which(!is.na(elements$leaf_id) & elements$leaf_id == lid)
    if (length(el_idx) == 0L) next

    bdf <- tables[[tid]]$data
    if (!is.data.frame(bdf) || nrow(bdf) == 0L) next

    lyr <- layer_by_id[[as.character(li)]]
    geom_cls <- if (!is.null(lyr)) lyr$geom else ""
    pan <- if (!is.na(pid) && pid %in% names(panel_by_id)) panel_by_id[[pid]] else NULL

    # Restrict built rows to matching PANEL when present
    row_pool <- seq_len(nrow(bdf))
    if (!is.na(pid) && "PANEL" %in% names(bdf)) {
      pnum <- suppressWarnings(as.integer(sub("^.*P([0-9]+)$", "\\1", pid)))
      if (!is.na(pnum)) {
        row_pool <- which(as.integer(as.character(bdf$PANEL)) == pnum)
      }
    }
    if (length(row_pool) == 0L) next

    has_gkey <- "_group_key" %in% names(bdf)
    l_pos <- leaf_by_id[[lid]]
    gpath <- if (!is.na(l_pos)) leaves$grob_path[[l_pos]] else ""
    gname <- if (!is.na(l_pos)) leaves$grob_name[[l_pos]] else ""

    el_cx <- 0.5 * (elements$bbox_x0[el_idx] + elements$bbox_x1[el_idx])
    el_cy <- 0.5 * (elements$bbox_y0[el_idx] + elements$bbox_y1[el_idx])
    el_tags <- elements$tag[el_idx]

    # Helper to compute theoretical built row center in rendered coords
    built_centers <- function(rows_idx) {
      bx <- if (all(c("xmin", "xmax") %in% names(bdf))) {
        0.5 * (as.numeric(bdf$xmin[rows_idx]) + as.numeric(bdf$xmax[rows_idx]))
      } else if (all(c("x", "xend") %in% names(bdf))) {
        0.5 * (as.numeric(bdf$x[rows_idx]) + as.numeric(bdf$xend[rows_idx]))
      } else if ("x" %in% names(bdf)) {
        as.numeric(bdf$x[rows_idx])
      } else {
        rep(NA_real_, length(rows_idx))
      }

      by <- if (all(c("ymin", "ymax") %in% names(bdf))) {
        0.5 * (as.numeric(bdf$ymin[rows_idx]) + as.numeric(bdf$ymax[rows_idx]))
      } else if (all(c("y", "yend") %in% names(bdf))) {
        0.5 * (as.numeric(bdf$y[rows_idx]) + as.numeric(bdf$yend[rows_idx]))
      } else if ("y" %in% names(bdf)) {
        as.numeric(bdf$y[rows_idx])
      } else if ("middle" %in% names(bdf)) {
        as.numeric(bdf$middle[rows_idx])
      } else {
        rep(NA_real_, length(rows_idx))
      }
      list(x = bx, y = by)
    }

    # Case 1: Composite GeomBoxplot (1:M with box / median / whisker / outlier parts)
    if (identical(geom_cls, "GeomBoxplot") && !is.null(pan)) {
      bc <- built_centers(row_pool)
      proj <- panel_rendered_to_px(pan, bc$x, bc$y)
      flipped <- isTRUE(pan$flipped)

      for (k in seq_along(el_idx)) {
        ei <- el_idx[[k]]
        tg <- el_tags[[k]]
        prole <- if (grepl("geom_crossbar", gpath, fixed = TRUE)) {
          if (tg %in% c("polygon", "rect")) "box" else "median"
        } else if (tg == "circle" || grepl("point|outlier", gname, ignore.case = TRUE)) {
          "outlier"
        } else {
          "whisker"
        }
        elements$part_role[[ei]] <- prole
        # Match along the grouping axis (x if vertical boxplot, y if flipped)
        dists <- if (flipped) abs(proj$py - el_cy[[k]]) else abs(proj$px - el_cx[[k]])
        if (any(is.finite(dists))) {
          best <- which.min(dists)
          br <- row_pool[[best]]
          elements$built_row_id[[ei]] <- as.integer(br)
          if (has_gkey) elements$group_id[[ei]] <- bdf[["_group_key"]][[br]]
        }
      }
      next
    }

    # Case 2: Interval geoms (GeomErrorbar / GeomPointrange / GeomCrossbar / GeomLinerange)
    if (geom_cls %in% c("GeomErrorbar", "GeomErrorbarh", "GeomPointrange", "GeomCrossbar", "GeomLinerange") && !is.null(pan)) {
      bc <- built_centers(row_pool)
      ok_r <- is.finite(bc$x) & is.finite(bc$y)
      valid_rows <- row_pool[ok_r]
      if (length(valid_rows) > 0L) {
        proj <- panel_rendered_to_px(pan, bc$x[ok_r], bc$y[ok_r])
        for (k in seq_along(el_idx)) {
          ei <- el_idx[[k]]
          elements$part_role[[ei]] <- switch(
            el_tags[[k]],
            circle = "point",
            rect = , polygon = "box",
            "interval"
          )
          dists <- sqrt((proj$px - el_cx[[k]])^2 + (proj$py - el_cy[[k]])^2)
          if (any(is.finite(dists))) {
            best <- which.min(dists)
            br <- valid_rows[[best]]
            elements$built_row_id[[ei]] <- as.integer(br)
            if (has_gkey) elements$group_id[[ei]] <- bdf[["_group_key"]][[br]]
          }
        }
      }
      next
    }

    # Case 3: N:1 path / line / ribbon / smooth / polygon geoms
    if (geom_cls %in% c("GeomLine", "GeomPath", "GeomArea", "GeomRibbon", "GeomPolygon", "GeomSmooth", "GeomDensity", "GeomStep")) {
      prole <- switch(
        geom_cls,
        GeomRibbon = , GeomArea = "ribbon",
        GeomSmooth = if (all(el_tags %in% c("polygon", "path"))) "ribbon" else "line",
        GeomPolygon = , GeomDensity = "polygon",
        "line"
      )
      elements$part_role[el_idx] <- prole
      if (has_gkey) {
        gkeys <- unique(bdf[["_group_key"]][row_pool])
        if (length(gkeys) == length(el_idx)) {
          elements$group_id[el_idx] <- gkeys
        } else if (!is.null(pan) && length(gkeys) > 0L) {
          # Match each SVG group primitive to nearest projected group centroid
          g_cx <- numeric(length(gkeys))
          g_cy <- numeric(length(gkeys))
          for (gi in seq_along(gkeys)) {
            gr <- row_pool[bdf[["_group_key"]][row_pool] == gkeys[[gi]]]
            bc <- built_centers(gr)
            proj <- panel_rendered_to_px(pan, bc$x, bc$y)
            g_cx[[gi]] <- mean(proj$px, na.rm = TRUE)
            g_cy[[gi]] <- mean(proj$py, na.rm = TRUE)
          }
          for (k in seq_along(el_idx)) {
            dists <- sqrt((g_cx - el_cx[[k]])^2 + (g_cy - el_cy[[k]])^2)
            if (any(is.finite(dists))) {
              elements$group_id[[el_idx[[k]]]] <- gkeys[[which.min(dists)]]
            }
          }
        }
      }
      next
    }

    # Case 4: Text & Repel labels (match by exact label text + nearest anchor)
    if (geom_cls %in% LABEL_GEOMS) {
      is_txt <- el_tags == "text"
      is_seg <- el_tags %in% c("line", "polyline", "path")
      elements$part_role[el_idx[is_txt]] <- "label"
      elements$part_role[el_idx[is_seg]] <- "leader"
      elements$part_role[el_idx[!is_txt & !is_seg]] <- "label_box"

      if ("label" %in% names(bdf) && any(is_txt)) {
        lbl_vals <- as.character(bdf$label[row_pool])
        proj <- if (!is.null(pan)) {
          bc <- built_centers(row_pool)
          panel_rendered_to_px(pan, bc$x, bc$y)
        } else {
          list(px = rep(NA_real_, length(row_pool)), py = rep(NA_real_, length(row_pool)))
        }
        used_r <- logical(length(row_pool))
        for (k in which(is_txt)) {
          ei <- el_idx[[k]]
          txt_s <- elements$text[[ei]]
          if (is.na(txt_s)) next
          cands <- which(!used_r & !is.na(lbl_vals) & lbl_vals == txt_s)
          if (length(cands) == 0L) next
          pick <- if (length(cands) == 1L || !all(is.finite(proj$px[cands]))) {
            cands[[1L]]
          } else {
            dists <- sqrt((proj$px[cands] - el_cx[[k]])^2 + (proj$py[cands] - el_cy[[k]])^2)
            cands[[which.min(dists)]]
          }
          used_r[[pick]] <- TRUE
          br <- row_pool[[pick]]
          elements$built_row_id[[ei]] <- as.integer(br)
          if (has_gkey) elements$group_id[[ei]] <- bdf[["_group_key"]][[br]]
        }
      }
      next
    }

    # Case 5: Standard 1:1 marks (points, bars, cols, tiles, rects, segments)
    prole <- switch(
      geom_cls,
      GeomPoint = "point",
      GeomBar = , GeomCol = "bar",
      GeomTile = "tile",
      GeomRect = "rect",
      GeomSegment = "segment",
      GeomHline = , GeomVline = , GeomAbline = "reference",
      "mark"
    )
    elements$part_role[el_idx] <- prole

    bc <- built_centers(row_pool)
    ok_r <- is.finite(bc$x) & is.finite(bc$y)
    valid_rows <- row_pool[ok_r]
    n_el <- length(el_idx)
    n_vr <- length(valid_rows)
    if (n_vr == 0L || is.null(pan)) next

    proj <- panel_rendered_to_px(pan, bc$x[ok_r], bc$y[ok_r])
    if (all(!is.finite(proj$px))) next

    # Fast O(N) path: verify positional order matches within 2.0 pt
    if (n_el == n_vr) {
      pos_err <- sqrt((proj$px - el_cx)^2 + (proj$py - el_cy)^2)
      if (all(is.finite(pos_err)) && max(pos_err) <= 2.0) {
        elements$built_row_id[el_idx] <- as.integer(valid_rows)
        if (has_gkey) elements$group_id[el_idx] <- bdf[["_group_key"]][valid_rows]
        next
      }
    }

    # General coordinate-matched 1:1 alignment (handles group reordering & OOB/NA drops)
    if (n_el <= 2000L && n_vr <= 2000L) {
      used_r <- logical(n_vr)
      for (k in seq_len(n_el)) {
        avail <- which(!used_r)
        if (length(avail) == 0L) break
        dists <- sqrt((proj$px[avail] - el_cx[[k]])^2 + (proj$py[avail] - el_cy[[k]])^2)
        bi <- which.min(dists)
        if (length(bi) > 0L && is.finite(dists[[bi]]) && dists[[bi]] <= 15.0) {
          pick <- avail[[bi]]
          used_r[[pick]] <- TRUE
          br <- valid_rows[[pick]]
          elements$built_row_id[[el_idx[[k]]]] <- as.integer(br)
          if (has_gkey) elements$group_id[[el_idx[[k]]]] <- bdf[["_group_key"]][[br]]
        }
      }
    }
  }

  elements
}

# --- Item-level ir.guides extraction (ISS-ASSET-03) --------------------------

ggplot_extract_guides <- function(leaves, elements, scales_ir, collected = FALSE) {
  if (!is.data.frame(leaves) || nrow(leaves) == 0L) return(NULL)

  gb_idx <- which(grepl("^guide-box", leaves$layout_slot))
  if (length(gb_idx) == 0L && !isTRUE(collected)) return(NULL)

  target_idx <- gb_idx
  if (isTRUE(collected) && length(gb_idx) > 0L) {
    outer_gb <- gb_idx[grepl("^layout::guide-box", leaves$vp_path[gb_idx])]
    if (length(outer_gb) > 0L) target_idx <- outer_gb
  }

  bbox_of_idx <- function(idx_vec) {
    valid <- idx_vec[
      is.finite(leaves$bbox_x0[idx_vec]) & is.finite(leaves$bbox_y0[idx_vec]) &
        is.finite(leaves$bbox_x1[idx_vec]) & is.finite(leaves$bbox_y1[idx_vec])
    ]
    if (length(valid) == 0L) return(NULL)
    json_array(round_pt(c(
      min(leaves$bbox_x0[valid]),
      min(leaves$bbox_y0[valid]),
      max(leaves$bbox_x1[valid]),
      max(leaves$bbox_y1[valid])
    )))
  }

  non_pos_scales <- Filter(function(s) {
    a <- s$aesthetic %||% ""
    nzchar(a) && !(a %in% c("x", "y"))
  }, scales_ir)
  non_pos_aes <- unique(vapply(non_pos_scales, function(s) s$aesthetic, character(1L)))

  # Partition guide leaves by individual guide container viewport prefix
  guide_containers <- character(length(target_idx))
  for (k in seq_along(target_idx)) {
    vp <- leaves$vp_path[[target_idx[[k]]]] %||% ""
    segs <- strsplit(vp, "::", fixed = TRUE)[[1L]]
    g_at <- which(grepl("^guides\\.", segs))
    if (length(g_at) > 0L) {
      guide_containers[[k]] <- paste(segs[seq_len(g_at[[length(g_at)]])], collapse = "::")
    } else {
      guide_containers[[k]] <- leaves$layout_slot[[target_idx[[k]]]]
    }
  }

  entries <- list()
  unique_containers <- unique(guide_containers)
  for (ci in seq_along(unique_containers)) {
    ck <- unique_containers[[ci]]
    g_idx <- target_idx[guide_containers == ck]
    g_lids <- leaves$leaf_id[g_idx]
    g_els <- elements[!is.na(elements$leaf_id) & elements$leaf_id %in% g_lids, , drop = FALSE]

    # Detect colorbar vs discrete legend
    vps <- leaves$vp_path[g_idx]
    is_cbar <- any(grepl("::bar\\.|::ticks\\.", vps))

    # Extract title text
    title_lids <- g_lids[grepl("::title\\.", vps)]
    title_txt <- NULL
    if (length(title_lids) > 0L && nrow(g_els) > 0L) {
      t_rows <- g_els[g_els$leaf_id %in% title_lids & g_els$tag == "text" & !is.na(g_els$text), , drop = FALSE]
      if (nrow(t_rows) > 0L) title_txt <- paste(t_rows$text, collapse = " ")
    }

    # Parse key-<row>-<col>-<layer> and label-<row>-<col> cells
    key_cells <- list()
    label_cells <- list()
    for (k in seq_along(g_idx)) {
      r_idx <- g_idx[[k]]
      lid <- leaves$leaf_id[[r_idx]]
      vp <- leaves$vp_path[[r_idx]] %||% ""
      e_ids <- g_els$element_id[g_els$leaf_id == lid]
      if (length(e_ids) == 0L) next

      km <- regmatches(vp, regexec("::key-([0-9]+)-([0-9]+)-([0-9]+|bg)\\.", vp))[[1L]]
      if (length(km) == 4L && !identical(km[[4L]], "bg")) {
        cell_key <- paste0(km[[2L]], "-", km[[3L]])
        key_cells[[cell_key]] <- list(
          row = as.integer(km[[2L]]),
          col = as.integer(km[[3L]]),
          elements = c(if (!is.null(key_cells[[cell_key]])) key_cells[[cell_key]]$elements else character(), e_ids)
        )
        next
      }
      lm <- regmatches(vp, regexec("::label-([0-9]+)-([0-9]+)\\.", vp))[[1L]]
      if (length(lm) == 3L) {
        txt_rows <- g_els[g_els$leaf_id == lid & g_els$tag == "text", , drop = FALSE]
        lbl_str <- if (nrow(txt_rows) > 0L) paste(txt_rows$text, collapse = " ") else NA_character_
        cell_key <- paste0(lm[[2L]], "-", lm[[3L]])
        label_cells[[cell_key]] <- list(
          row = as.integer(lm[[2L]]),
          col = as.integer(lm[[3L]]),
          label = lbl_str,
          elements = e_ids
        )
      }
    }

    # Match this guide against non_pos_scales by title or label overlap
    lbl_strs <- vapply(label_cells, function(x) x$label %||% "", character(1L))
    matched_scales <- list()
    for (sc in non_pos_scales) {
      sc_lbls <- unique(c(
        unlist(sc$labels),
        vapply(sc$map, function(m) as.character(m$label %||% ""), character(1L)),
        vapply(sc$map, function(m) as.character(m$domain %||% ""), character(1L))
      ))
      title_hit <- !is.null(title_txt) && (
        identical(sc$name, title_txt) || identical(sc$field, title_txt)
      )
      lbl_hit <- length(lbl_strs) > 0L && any(lbl_strs %in% sc_lbls)
      if (title_hit || lbl_hit) {
        matched_scales[[length(matched_scales) + 1L]] <- sc
      }
    }
    if (length(matched_scales) == 0L && length(non_pos_scales) == 1L) {
      matched_scales <- non_pos_scales
    }
    guide_aes <- unique(vapply(matched_scales, function(s) s$aesthetic, character(1L)))

    # Build domain lookup from matched scales
    lbl_to_domain <- stats::setNames(character(), character())
    for (sc in matched_scales) {
      for (m in sc$map) {
        dm <- as.character(m$domain %||% "")
        lb <- as.character(m$label %||% dm)
        if (nzchar(lb) && !(lb %in% names(lbl_to_domain))) {
          lbl_to_domain[[lb]] <- dm
        }
      }
    }

    # Pair each label cell with its adjacent key cell (same row or same col)
    items <- list()
    if (!is_cbar && length(label_cells) > 0L) {
      l_ord <- order(
        vapply(label_cells, `[[`, integer(1L), "row"),
        vapply(label_cells, `[[`, integer(1L), "col")
      )
      for (li in l_ord) {
        lc <- label_cells[[li]]
        swatch_els <- character()
        # Same row with nearest col < lc$col (standard vertical legend), else same col above
        best_d <- Inf
        for (kc in key_cells) {
          if (kc$row == lc$row && kc$col != lc$col) {
            d <- abs(kc$col - lc$col)
            if (d < best_d) {
              best_d <- d
              swatch_els <- kc$elements
            }
          }
        }
        if (length(swatch_els) == 0L) {
          for (kc in key_cells) {
            if (kc$col == lc$col && kc$row != lc$row) {
              d <- abs(kc$row - lc$row)
              if (d < best_d) {
                best_d <- d
                swatch_els <- kc$elements
              }
            }
          }
        }

        lbl_s <- lc$label %||% ""
        dom_s <- if (lbl_s %in% names(lbl_to_domain)) unname(lbl_to_domain[[lbl_s]]) else lbl_s
        items[[length(items) + 1L]] <- list(
          domain = dom_s,
          label = lbl_s,
          swatch_elements = json_array(swatch_els),
          label_elements = json_array(lc$elements)
        )
      }
    } else if (is_cbar) {
      bar_lids <- g_lids[grepl("::bar\\.", vps)]
      bar_els <- g_els$element_id[g_els$leaf_id %in% bar_lids]
      tick_lids <- g_lids[grepl("::ticks\\.", vps)]
      tick_els <- g_els$element_id[g_els$leaf_id %in% tick_lids]
      lbl_els <- unlist(lapply(label_cells, `[[`, "elements"), use.names = FALSE)
      items[[1L]] <- list(
        domain = if (length(matched_scales) > 0L && !is.null(matched_scales[[1L]]$limits)) matched_scales[[1L]]$limits else list(),
        bar_elements = json_array(bar_els),
        tick_elements = json_array(tick_els),
        label_elements = json_array(lbl_els)
      )
    }

    ent <- list(
      guide_id = sprintf("G%d", ci),
      kind = if (is_cbar) "colorbar" else "legend",
      aesthetics = json_array(guide_aes),
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
    collected = isTRUE(collected),
    bbox_pt = bbox_of_idx(target_idx),
    leaf_ids = json_array(leaves$leaf_id[target_idx]),
    aesthetics = json_array(non_pos_aes),
    entries = json_array(entries)
  )
}
