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
  panel_grobs_by_path <- patchwork_find_panel_grobs(gt)

  all_panels <- list()
  all_layers <- list()
  all_scales <- list()
  all_tables <- stats::setNames(list(), character())

  n_leaves <- nrow(leaves)
  merged_panel_id <- rep(NA_character_, n_leaves)
  merged_layer_id <- rep(NA_integer_, n_leaves)
  merged_table_id <- rep(NA_character_, n_leaves)
  merged_card <- rep("unlinked", n_leaves)
  merged_n_rows <- rep(NA_integer_, n_leaves)

  next_layer_id <- 0L
  sp_idx <- 0L

  for (i in seq_along(subplots)) {
    sp <- subplots[[i]]
    plt <- sp$plot
    # Skip non-data patchwork placeholders (plot_spacer(), wrap_elements())
    if (inherits(plt, c("spacer", "wrapped_patch"))) next

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

    leaf_idx <- if (length(pgrob_names) > 0L && n_leaves > 0L) {
      which(vapply(
        strsplit(leaves$grob_path, "/", fixed = TRUE),
        function(segs) any(segs %in% pgrob_names),
        logical(1L)
      ))
    } else {
      integer()
    }

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
      panel_prefix = pfx,
      table_prefix = pfx,
      leaf_indices = leaf_idx
    )

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

    # Merge tables
    for (tid in names(ext$tables)) {
      ent <- ext$tables[[tid]]
      if (!is.null(ent$layer_id)) {
        ent$layer_id <- as.integer(layer_offset + ent$layer_id)
      }
      all_tables[[tid]] <- ent
    }

    # Merge lineage rows back to global leaf positions
    if (length(leaf_idx) > 0L && nrow(ext$lineage) == length(leaf_idx)) {
      lin <- ext$lineage
      merged_panel_id[leaf_idx] <- lin$panel_id
      has_lyr <- !is.na(lin$layer_id)
      if (any(has_lyr)) {
        merged_layer_id[leaf_idx[has_lyr]] <- as.integer(layer_offset + lin$layer_id[has_lyr])
      }
      merged_table_id[leaf_idx] <- lin$table_id
      merged_card[leaf_idx] <- lin$cardinality
      merged_n_rows[leaf_idx] <- lin$n_rows
    }
  }

  lineage <- make_lineage_df(
    leaves = leaves,
    panel_id = merged_panel_id,
    layer_id = merged_layer_id,
    table_id = merged_table_id,
    cardinality = merged_card,
    n_rows = merged_n_rows
  )

  guides_ir <- patchwork_extract_guides_ir(x_seeded, leaves, all_scales)
  ir_out <- list(
    panels = all_panels,
    layers = all_layers,
    scales = all_scales,
    orders = stats::setNames(list(), character())
  )
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

patchwork_extract_guides_ir <- function(x, leaves, all_scales) {
  collected <- patchwork_has_collected_guides(x)
  gb_idx <- if (nrow(leaves) > 0L) which(grepl("^guide-box", leaves$layout_slot)) else integer()
  if (!collected && length(gb_idx) == 0L) {
    return(NULL)
  }

  # When guides = "collect" is active at top level, prefer outer guide-box leaves
  target_idx <- gb_idx
  if (collected && length(gb_idx) > 0L) {
    outer_gb <- gb_idx[grepl("^layout::guide-box", leaves$vp_path[gb_idx])]
    if (length(outer_gb) > 0L) {
      target_idx <- outer_gb
    }
  }

  bbox_pt <- NULL
  if (length(target_idx) > 0L) {
    valid <- target_idx[
      is.finite(leaves$bbox_x0[target_idx]) & is.finite(leaves$bbox_y0[target_idx]) &
        is.finite(leaves$bbox_x1[target_idx]) & is.finite(leaves$bbox_y1[target_idx])
    ]
    if (length(valid) > 0L) {
      bbox_pt <- json_array(round_pt(c(
        min(leaves$bbox_x0[valid]),
        min(leaves$bbox_y0[valid]),
        max(leaves$bbox_x1[valid]),
        max(leaves$bbox_y1[valid])
      )))
    }
  }

  non_pos_aes <- unique(unlist(lapply(all_scales, function(s) {
    a <- s$aesthetic %||% ""
    if (nzchar(a) && !(a %in% c("x", "y"))) a else character()
  })))

  list(
    collected = isTRUE(collected),
    bbox_pt = bbox_pt,
    leaf_ids = json_array(leaves$leaf_id[target_idx]),
    aesthetics = json_array(non_pos_aes)
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

# Walk patchwork's drawn gtable and map each patch path ("1/2", "2", ...) to
# its list of ggplot panel gTree grobs.
patchwork_find_panel_grobs <- function(gt) {
  found <- new.env(parent = emptyenv())
  found$map <- list()

  walk_gt <- function(tbl, prefix) {
    if (!inherits(tbl, "gtable") || is.null(tbl$layout) || nrow(tbl$layout) == 0L) {
      return(invisible(NULL))
    }
    for (j in seq_len(nrow(tbl$layout))) {
      nm <- tbl$layout$name[[j]]
      g <- tbl$grobs[[j]]
      if (grepl("^patchwork-table-[0-9]+$", nm)) {
        idx <- as.integer(sub("^patchwork-table-", "", nm))
        walk_gt(g, c(prefix, idx))
      } else if (grepl("^panel-[0-9]+$", nm) && is_ggplot_panel_grob(g)) {
        idx <- as.integer(sub("^panel-", "", nm))
        key <- paste(c(prefix, idx), collapse = "/")
        found$map[[key]] <- list(g)
      } else if (grepl("^panel; .*-[0-9]+$", nm) && inherits(g, "gtable")) {
        idx <- as.integer(sub("^.*-([0-9]+)$", "\\1", nm))
        key <- paste(c(prefix, idx), collapse = "/")
        found$map[[key]] <- Filter(is_ggplot_panel_grob, g$grobs)
      }
    }
    invisible(NULL)
  }

  walk_gt(gt, integer())
  found$map
}
