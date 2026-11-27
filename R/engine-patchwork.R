# Built-in patchwork plotting engine (Suggests: patchwork, ggplot2).
#
# Draws the composition once via patchwork::patchworkGrob() -> grid.draw(),
# then extracts per-subplot ggplot2 IR (panels, layers, scales, tables) and
# neutral structural lineage using public patchwork APIs only.

register_engine_patchwork <- function() {
  gl_register_engine(
    name = "patchwork",
    classes = c("patchwork", "patchwork::patchwork"),
    capture_fn = engine_patchwork_capture,
    packages = c("patchwork", "ggplot2"),
    description = "patchwork compositions: multi-subplot ggplot2 IR, namespaced tables, panels, and lineage",
    priority = 10L,
    page_kind = "grid",
    overwrite = TRUE
  )
}

engine_patchwork_capture <- function(x, ctx) {
  # Pin unseeded stochastic jitter positions on a shallow-cloned patchwork copy
  # BEFORE patchworkGrob() builds subplots internally, so subplot built tables
  # match drawn SVG coordinates 1-to-1 without mutating caller objects.
  x_seeded <- patchwork_pin_stochastic_seeds(x)

  grid::grid.newpage()
  gt <- patchwork::patchworkGrob(x_seeded)
  grid::grid.draw(gt)
  ctx$ensure_device()

  sc <- ctx$capture_grid(draw_method = "patchworkGrob")
  leaves <- sc$leaves

  subplots <- patchwork_collect_subplots(x_seeded)
  pw_walk <- patchwork_walk_gtable(gt)
  panel_grobs_by_path <- pw_walk$panel_grobs
  subplot_cells_by_path <- pw_walk$cell_paths

  all_panels <- list()
  all_layers <- list()
  all_scales <- list()
  all_tables <- stats::setNames(list(), character())
  all_group_indices <- stats::setNames(list(), character())

  n_leaves <- nrow(leaves)
  merged_panel_id <- rep(NA_character_, n_leaves)
  merged_layer_id <- rep(NA_integer_, n_leaves)
  merged_table_id <- rep(NA_character_, n_leaves)
  merged_card <- rep("unlinked", n_leaves)
  merged_n_rows <- rep(NA_integer_, n_leaves)
  merged_deg <- rep(NA_character_, n_leaves)
  merged_subplot <- rep(NA_integer_, n_leaves)
  merged_attached <- vector("list", n_leaves)
  merged_elements <- sc$elements

  # Pre-split stripped vp_path & grob_path segments for fast subplot container matching (K2)
  strip_coords <- function(s) sub("\\.[0-9]+-[0-9]+-[0-9]+-[0-9]+$", "", s)
  leaf_vp_segs <- if (n_leaves > 0L) {
    lapply(strsplit(leaves$vp_path %||% character(), "::", fixed = TRUE), strip_coords)
  } else {
    list()
  }
  leaf_grob_segs <- if (n_leaves > 0L) {
    lapply(strsplit(leaves$grob_path %||% character(), "/", fixed = TRUE), strip_coords)
  } else {
    list()
  }

  match_subplot_leaves <- function(cell_specs, pgrob_names) {
    if (n_leaves == 0L) return(integer())
    hit <- logical(n_leaves)
    # 1. Panel interior leaves (guaranteed match via panel grob names)
    if (length(pgrob_names) > 0L) {
      hit <- hit | vapply(leaf_grob_segs, function(segs) any(segs %in% pgrob_names), logical(1L))
    }
    # 2. Peripheral subplot leaves (axes, strips, xlab/ylab, titles, captions, guides)
    if (length(cell_specs) > 0L) {
      for (cs in cell_specs) {
        req_chain <- cs$chain
        cell_nm <- cs$name
        # Skip collected top-level guide-boxes unless directly owned by this subplot
        for (r in which(!hit)) {
          vsegs <- leaf_vp_segs[[r]]
          gsegs <- leaf_grob_segs[[r]]
          # Verify every ancestor patchwork-table-* in req_chain appears, plus cell_nm itself
          has_v <- (cell_nm %in% vsegs) && all(req_chain %in% vsegs)
          has_g <- !has_v && (cell_nm %in% gsegs) && all(req_chain %in% gsegs)
          if (has_v || has_g) {
            hit[[r]] <- TRUE
          }
        }
      }
    }
    which(hit)
  }

  next_layer_id <- 0L
  sp_idx <- 0L
  wrap_idx <- 0L

  for (i in seq_along(subplots)) {
    sp <- subplots[[i]]
    plt <- sp$plot
    # Skip spacers; optionally attach wrapped_patch panel without shifting p<i> subplot ids
    if (inherits(plt, "spacer")) next
    if (inherits(plt, "wrapped_patch")) {
      wp_lids <- which(grepl(sprintf("patchwork-table-%s|wrapped", utils::tail(sp$path, 1L)), leaves$grob_path))
      if (length(wp_lids) > 0L) {
        valid <- wp_lids[is.finite(leaves$bbox_x0[wp_lids]) & is.finite(leaves$bbox_y0[wp_lids]) &
                           is.finite(leaves$bbox_x1[wp_lids]) & is.finite(leaves$bbox_y1[wp_lids])]
        if (length(valid) > 0L) {
          wrap_idx <- wrap_idx + 1L
          wp_pid <- sprintf("wrap_P%d", wrap_idx)
          all_panels[[length(all_panels) + 1L]] <- make_panel_ir(
            panel_id = wp_pid,
            facet_vars = list(wrapped = TRUE),
            bbox_pt = c(min(leaves$bbox_x0[valid]), min(leaves$bbox_y0[valid]),
                        max(leaves$bbox_x1[valid]), max(leaves$bbox_y1[valid])),
            coord = "WrappedGrid",
            panel_role = "wrapped"
          )
          merged_panel_id[wp_lids] <- wp_pid
        }
      }
      next
    }

    path_key <- paste(sp$path, collapse = "/")
    pgrobs <- panel_grobs_by_path[[path_key]] %||% list()
    if (length(plt$layers %||% list()) == 0L && length(pgrobs) == 0L) next

    sp_idx <- sp_idx + 1L

    built_i <- tryCatch({
      b <- ggplot2::ggplot_build(plt)
      if (inherits(b, c("ggplot2::ggplot_built", "ggplot_built"))) b else NULL
    }, error = function(e) NULL)

    pgrob_names <- vapply(pgrobs, function(g) g$name %||% "", character(1L))
    pgrob_names <- pgrob_names[nzchar(pgrob_names)]
    cell_specs <- subplot_cells_by_path[[path_key]] %||% list()

    leaf_idx <- match_subplot_leaves(cell_specs, pgrob_names)

    sub_gt <- if (length(pgrobs) > 0L) {
      list(
        layout = data.frame(
          name = paste0("panel-", seq_along(pgrobs)),
          stringsAsFactors = FALSE
        ),
        grobs = pgrobs
      )
    } else {
      NULL
    }

    pfx <- sprintf("p%d", sp_idx)
    ext <- extract_ggplot_ir(
      plot = plt,
      built = built_i,
      gtable = sub_gt,
      leaves = leaves,
      elements = merged_elements,
      panel_prefix = pfx,
      table_prefix = pfx,
      leaf_indices = leaf_idx,
      draw_method = "patchworkGrob",
      extract_guides = FALSE
    )
    merged_elements <- ext$elements

    # Merge panels (annotate with subplot index)
    for (pan in ext$ir$panels) {
      pan$subplot <- as.integer(sp_idx)
      all_panels[[length(all_panels) + 1L]] <- pan
    }

    # Remap subplot-local layer_ids to globally unique layer_ids
    layer_offset <- next_layer_id
    for (lyr in ext$ir$layers) {
      lyr$subplot <- as.integer(sp_idx)
      lyr$subplot_layer_id <- lyr$layer_id
      lyr$layer_id <- as.integer(layer_offset + lyr$layer_id)
      all_layers[[length(all_layers) + 1L]] <- lyr
      next_layer_id <- max(next_layer_id, lyr$layer_id)
    }

    # Merge scales (annotate with subplot index)
    for (scl in ext$ir$scales) {
      scl$subplot <- as.integer(sp_idx)
      all_scales[[length(all_scales) + 1L]] <- scl
    }

    # Merge tables & group indices
    for (tid in names(ext$tables)) {
      ent <- ext$tables[[tid]]
      if (!is.null(ent$layer_id)) {
        ent$layer_id <- as.integer(layer_offset + ent$layer_id)
      }
      all_tables[[tid]] <- ent
    }
    if (!is.null(ext$ir$group_indices) && length(ext$ir$group_indices) > 0L) {
      for (gid in names(ext$ir$group_indices)) {
        all_group_indices[[gid]] <- ext$ir$group_indices[[gid]]
      }
    }

    # Merge lineage, subplot ownership, and attached_to back to global leaf positions
    if (length(leaf_idx) > 0L && nrow(ext$lineage) == length(leaf_idx)) {
      lin <- ext$lineage
      merged_subplot[leaf_idx] <- as.integer(sp_idx)
      has_pan <- !is.na(lin$panel_id)
      if (any(has_pan)) {
        merged_panel_id[leaf_idx[has_pan]] <- lin$panel_id[has_pan]
      }
      has_lyr <- !is.na(lin$layer_id)
      if (any(has_lyr)) {
        merged_layer_id[leaf_idx[has_lyr]] <- as.integer(layer_offset + lin$layer_id[has_lyr])
        merged_table_id[leaf_idx[has_lyr]] <- lin$table_id[has_lyr]
        merged_card[leaf_idx[has_lyr]] <- lin$cardinality[has_lyr]
        merged_n_rows[leaf_idx[has_lyr]] <- lin$n_rows[has_lyr]
      }
      if ("degradation_reason" %in% names(lin)) {
        has_deg <- !is.na(lin$degradation_reason)
        if (any(has_deg)) merged_deg[leaf_idx[has_deg]] <- lin$degradation_reason[has_deg]
      }
      if ("attached_to" %in% names(lin) && is.list(lin$attached_to)) {
        for (k in seq_along(leaf_idx)) {
          if (!is.null(lin$attached_to[[k]])) {
            merged_attached[[leaf_idx[[k]]]] <- lin$attached_to[[k]]
          }
        }
      }
    }
  }

  sc$elements <- merged_elements
  sc$layout_tracks <- extract_gtable_layout_tracks(gt)

  lineage <- make_lineage_df(
    leaves = leaves,
    panel_id = merged_panel_id,
    layer_id = merged_layer_id,
    table_id = merged_table_id,
    cardinality = merged_card,
    n_rows = merged_n_rows,
    degradation_reason = merged_deg,
    subplot = merged_subplot,
    attached_to = merged_attached
  )

  guides_ir <- patchwork_extract_guides_ir(x_seeded, leaves, sc$elements, all_scales)
  if (!is.null(guides_ir)) {
    sc$elements <- tag_guide_element_tokens(sc$elements, guides_ir, all_scales)
  }
  ir_out <- list(
    panels = all_panels,
    layers = all_layers,
    scales = all_scales,
    orders = stats::setNames(list(), character())
  )
  if (length(all_group_indices) > 0L) {
    ir_out$group_indices <- all_group_indices
  }
  if (!is.null(guides_ir)) {
    ir_out$guides <- guides_ir
  }

  list(
    scene = sc,
    ir = ir_out,
    tables = all_tables,
    lineage = lineage
  )
}

patchwork_pin_ggplot_seeds <- function(plt) {
  pin_ggplot_stochastic_seeds(plt)
}

patchwork_pin_stochastic_seeds <- function(x) {
  if (inherits(x, "patchwork")) {
    plots <- x$patches$plots %||% list()
    if (length(plots) > 0L) {
      x$patches$plots <- lapply(plots, patchwork_pin_stochastic_seeds)
    }
  }
  patchwork_pin_ggplot_seeds(x)
}

patchwork_has_collected_guides <- function(x) {
  if (!inherits(x, "patchwork")) {
    return(FALSE)
  }
  if (identical(x$patches$layout$guides, "collect")) {
    return(TRUE)
  }
  plots <- x$patches$plots %||% list()
  for (p in plots) {
    if (patchwork_has_collected_guides(p)) {
      return(TRUE)
    }
  }
  FALSE
}

patchwork_extract_guides_ir <- function(x, leaves, elements, all_scales) {
  collected <- patchwork_has_collected_guides(x)
  ggplot_extract_guides(
    leaves = leaves,
    elements = elements,
    scales_ir = all_scales,
    collected = collected
  )
}

# Traverse a patchwork composition using public `[[` indexing to return each
# constituent ggplot along with its integer patch path.
patchwork_collect_subplots <- function(x, prefix = integer()) {
  if (!inherits(x, "patchwork")) {
    if (inherits(x, c("ggplot2::ggplot", "ggplot"))) {
      return(list(list(plot = x, path = prefix)))
    }
    return(list())
  }

  n_inner <- length(x$patches$plots %||% list())
  children <- list()
  for (j in seq_len(n_inner)) {
    child <- tryCatch(x[[j]], error = function(e) NULL)
    if (!is.null(child)) {
      children[[length(children) + 1L]] <- list(obj = child, idx = j)
    }
  }
  # Rightmost plot attached directly on the patchwork object itself (when present)
  tail_obj <- tryCatch(x[[n_inner + 1L]], error = function(e) NULL)
  if (!is.null(tail_obj)) {
    children[[length(children) + 1L]] <- list(obj = tail_obj, idx = n_inner + 1L)
  }

  out <- list()
  for (ch in children) {
    out <- c(out, patchwork_collect_subplots(ch$obj, prefix = c(prefix, ch$idx)))
  }
  out
}

is_ggplot_panel_grob <- function(g) {
  inherits(g, "gTree") && grepl("^panel-[0-9]+\\.", g$name %||% "")
}

# Walk patchwork's drawn gtable and map each patch path ("1/2", "2", ...) to:
#   - panel_grobs: its list of ggplot panel gTree grobs
#   - cell_paths:  ALL gtable layout cells owned by that subplot (axes, strips, xlab/ylab, titles, etc.)
patchwork_walk_gtable <- function(gt) {
  found <- new.env(parent = emptyenv())
  found$panel_grobs <- list()
  found$cell_paths <- list()

  add_cell <- function(key, chain, nm) {
    cur <- found$cell_paths[[key]] %||% list()
    cur[[length(cur) + 1L]] <- list(chain = chain, name = nm)
    found$cell_paths[[key]] <- cur
  }

  walk_gt <- function(tbl, prefix, chain) {
    if (!inherits(tbl, "gtable") || is.null(tbl$layout) || nrow(tbl$layout) == 0L) {
      return(invisible(NULL))
    }
    for (j in seq_len(nrow(tbl$layout))) {
      nm <- tbl$layout$name[[j]]
      g <- tbl$grobs[[j]]
      if (grepl("^patchwork-table-[0-9]+$", nm)) {
        idx <- as.integer(sub("^patchwork-table-", "", nm))
        walk_gt(g, c(prefix, idx), c(chain, nm))
      } else if (grepl("^panel-[0-9]+$", nm) && is_ggplot_panel_grob(g)) {
        idx <- as.integer(sub("^panel-", "", nm))
        key <- paste(c(prefix, idx), collapse = "/")
        found$panel_grobs[[key]] <- list(g)
        add_cell(key, chain, nm)
      } else if (grepl("^panel; .*-[0-9]+$", nm) && inherits(g, "gtable")) {
        idx <- as.integer(sub("^.*-([0-9]+)$", "\\1", nm))
        key <- paste(c(prefix, idx), collapse = "/")
        found$panel_grobs[[key]] <- Filter(is_ggplot_panel_grob, g$grobs)
        add_cell(key, chain, nm)
      } else if (grepl("-[0-9]+$", nm) && !grepl("^guide-box-collected", nm)) {
        # Peripheral subplot cell (axis-*-<idx>, strip-*-<idx>, xlab-*-<idx>, ylab-*-<idx>, title-<idx>, etc.)
        idx <- suppressWarnings(as.integer(sub("^.*-([0-9]+)$", "\\1", nm)))
        if (!is.na(idx) && idx >= 1L) {
          key <- paste(c(prefix, idx), collapse = "/")
          add_cell(key, chain, nm)
        }
      }
    }
    invisible(NULL)
  }

  walk_gt(gt, integer(), character())
  list(panel_grobs = found$panel_grobs, cell_paths = found$cell_paths)
}

patchwork_find_panel_grobs <- function(gt) {
  patchwork_walk_gtable(gt)$panel_grobs
}
