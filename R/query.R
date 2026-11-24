# In-memory inspection and spatial/tabular slicing for gloss_capture objects.

#' Inspect the captured SVG scene structure in memory
#'
#' Returns the device page metadata, dual SVG descriptors (`original_svg`,
#' `scene_svg`), leaf groups, SVG elements, dense raster slices, panel IR, and
#' structural lineage from a `gloss_capture` object.
#'
#' @param cap A `gloss_capture` object returned by [gloss()].
#'
#' @return A `gloss_scene` list.
#' @export
#' @examples
#' cap <- gloss(grid::rectGrob(width = 0.5, height = 0.5, name = "box"))
#' sc <- gl_scene(cap)
#' sc$leaves
gl_scene <- function(cap) {
  validate_gloss_capture(cap)

  structure(
    list(
      page = cap$page,
      coord = cap$scene$coord,
      original_svg = cap$svg$original,
      scene_svg = cap$svg$scene,
      leaves = cap$scene$leaves,
      elements = cap$scene$elements,
      dense_leaves = cap$scene$dense_leaves,
      rasters = cap$scene$rasters,
      preview_png = cap$scene$preview_png,
      label_links = cap$scene$label_links,
      panels = cap$ir$panels,
      guides = cap$ir$guides,
      lineage = cap$lineage
    ),
    class = "gloss_scene"
  )
}

#' @export
print.gloss_scene <- function(x, ...) {
  cat(sprintf(
    "<gloss_scene %s | %.1f x %.1f pt>\n",
    x$page$engine,
    x$page$width_pt,
    x$page$height_pt
  ))
  cat(sprintf(
    "  %d panel(s), %d leaf/leaves, %d element(s), %d dense raster(s)\n",
    length(x$panels),
    nrow(x$leaves),
    nrow(x$elements),
    length(x$rasters)
  ))
  invisible(x)
}

#' Access captured raw and engine-built data tables in memory
#'
#' @param cap A `gloss_capture` object returned by [gloss()].
#' @param name Optional character vector of table names to retrieve. When
#'   `NULL` (default), returns a named list of all captured data frames. When a
#'   single string is given, returns that data frame directly.
#'
#' @return A named list of data frames (or a single data frame when `length(name) == 1L`).
#' @export
#' @examples
#' cap <- gloss(grid::rectGrob(width = 0.5, height = 0.5))
#' gl_tables(cap)
gl_tables <- function(cap, name = NULL) {
  validate_gloss_capture(cap)

  avail <- names(cap$tables)
  if (is.null(name)) {
    return(stats::setNames(
      lapply(avail, function(nm) cap$tables[[nm]]$data),
      avail
    ))
  }

  if (!is.character(name) || length(name) == 0L || anyNA(name)) {
    cli::cli_abort("{.arg name} must be NULL or a non-empty character vector.")
  }

  missing_tbls <- setdiff(name, avail)
  if (length(missing_tbls) > 0L) {
    cli::cli_abort(c(
      "Unknown table(s): {.val {missing_tbls}}.",
      i = if (length(avail) > 0L) "Available tables: {.val {avail}}." else "This capture contains no tables."
    ))
  }

  if (length(name) == 1L) {
    return(cap$tables[[name]]$data)
  }

  stats::setNames(
    lapply(name, function(nm) cap$tables[[nm]]$data),
    name
  )
}

#' Inspect the runtime and explicit source inventory of a captured figure
#'
#' @param cap A `gloss_capture` object returned by [gloss()].
#'
#' @return A data frame describing all recorded sources (`source_id`, `kind`,
#'   `provenance_mode`, `found`, `readable`, `path`, `bytes`, `sha256`).
#' @export
#' @examples
#' cap <- gloss(grid::rectGrob(width = 0.5, height = 0.5))
#' gl_sources(cap)
gl_sources <- function(cap) {
  validate_gloss_capture(cap)

  srcs <- cap$sources
  if (length(srcs) == 0L) {
    return(data.frame(
      source_id = character(),
      kind = character(),
      provenance_mode = character(),
      found = logical(),
      readable = logical(),
      path = character(),
      bytes = integer(),
      sha256 = character(),
      stringsAsFactors = FALSE
    ))
  }

  data.frame(
    source_id = vapply(srcs, function(s) as.character(s$source_id %||% NA_character_)[[1L]], character(1L)),
    kind = vapply(srcs, function(s) as.character(s$kind %||% NA_character_)[[1L]], character(1L)),
    provenance_mode = vapply(srcs, function(s) as.character(s$provenance_mode %||% NA_character_)[[1L]], character(1L)),
    found = vapply(srcs, function(s) isTRUE(s$found), logical(1L)),
    readable = vapply(srcs, function(s) isTRUE(s$readable), logical(1L)),
    path = vapply(srcs, function(s) as.character(s$path %||% NA_character_)[[1L]], character(1L)),
    bytes = vapply(srcs, function(s) {
      b <- s$bytes
      if (is.null(b) || is.na(b)) NA_integer_ else as.integer(b)
    }, integer(1L)),
    sha256 = vapply(srcs, function(s) {
      h <- s$sha256
      if (is.null(h) || is.na(h)) NA_character_ else as.character(h)
    }, character(1L)),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

#' Query leaves, elements, lineage, and table slices from a captured figure
#'
#' Performs composable structural, spatial, and tabular slicing over an
#' in-memory `gloss_capture` object without redrawing or writing to disk.
#'
#' @param cap A `gloss_capture` object returned by [gloss()].
#' @param panel Optional character vector of `panel_id` values to match.
#' @param leaf Optional character vector of `leaf_id` values to match.
#' @param box Optional numeric bounding box `c(x0, y0, x1, y1)` in SVG point
#'   coordinates (top-left origin). Matches leaves and elements intersecting
#'   this box.
#' @param table Optional character vector of table IDs to include. When `NULL`,
#'   tables linked to matched lineage rows are returned (or all tables if no
#'   panel/leaf/box filter was supplied).
#' @param rows Optional row filter applied to each returned table: an integer
#'   vector of 1-based row indices, a logical vector, a predicate function
#'   `function(df) ...`, or a named list keyed by table ID. Returned table
#'   slices always include an explicit 1-based `_row_id` column.
#'
#' @return A `gloss_query_result` list containing `leaves`, `elements`,
#'   `lineage`, `tables`, and `filters`.
#' @export
#' @examples
#' g <- grid::grobTree(
#'   grid::rectGrob(x = 0.25, y = 0.5, width = 0.2, height = 0.2, name = "left"),
#'   grid::rectGrob(x = 0.75, y = 0.5, width = 0.2, height = 0.2, name = "right")
#' )
#' cap <- gloss(g)
#' gl_query(cap, leaf = "L001")
gl_query <- function(
    cap,
    panel = NULL,
    leaf = NULL,
    box = NULL,
    table = NULL,
    rows = NULL) {

  validate_gloss_capture(cap)

  if (!is.null(panel) && (!is.character(panel) || anyNA(panel))) {
    cli::cli_abort("{.arg panel} must be NULL or a character vector.")
  }
  if (!is.null(leaf) && (!is.character(leaf) || anyNA(leaf))) {
    cli::cli_abort("{.arg leaf} must be NULL or a character vector.")
  }
  if (!is.null(box)) {
    if (!is.numeric(box) || length(box) != 4L || any(!is.finite(box))) {
      cli::cli_abort("{.arg box} must be a finite numeric vector of length 4: {.code c(x0, y0, x1, y1)}.")
    }
    box <- c(min(box[c(1L, 3L)]), min(box[c(2L, 4L)]), max(box[c(1L, 3L)]), max(box[c(2L, 4L)]))
  }
  if (!is.null(table) && (!is.character(table) || anyNA(table))) {
    cli::cli_abort("{.arg table} must be NULL or a character vector.")
  }

  leaves <- cap$scene$leaves
  elements <- cap$scene$elements
  lineage <- cap$lineage

  has_scene_filter <- !is.null(panel) || !is.null(leaf) || !is.null(box)

  # 1. Structural filter by panel_id
  if (!is.null(panel)) {
    lineage <- lineage[!is.na(lineage$panel_id) & lineage$panel_id %in% panel, , drop = FALSE]
    panel_leaves <- unique(lineage$leaf_id)
    leaves <- leaves[leaves$leaf_id %in% panel_leaves, , drop = FALSE]
    elements <- elements[!is.na(elements$leaf_id) & elements$leaf_id %in% panel_leaves, , drop = FALSE]
  }

  # 2. Structural filter by leaf_id
  if (!is.null(leaf)) {
    leaves <- leaves[leaves$leaf_id %in% leaf, , drop = FALSE]
    elements <- elements[!is.na(elements$leaf_id) & elements$leaf_id %in% leaf, , drop = FALSE]
    lineage <- lineage[lineage$leaf_id %in% leaf, , drop = FALSE]
  }

  # 3. Spatial filter by SVG point box c(x0, y0, x1, y1)
  if (!is.null(box)) {
    el_hit <- box_intersects(
      elements$bbox_x0, elements$bbox_y0, elements$bbox_x1, elements$bbox_y1,
      box
    )
    if (any(!is.na(elements$leaf_id))) {
      el_hit <- el_hit & !is.na(elements$leaf_id)
    }
    elements <- elements[el_hit, , drop = FALSE]

    leaf_box_hit <- box_intersects(
      leaves$bbox_x0, leaves$bbox_y0, leaves$bbox_x1, leaves$bbox_y1,
      box
    )
    # Include dense rasterized leaves whose panel bbox intersects `box`
    hit_leaf_ids <- unique(c(
      elements$leaf_id[!is.na(elements$leaf_id)],
      leaves$leaf_id[leaf_box_hit & (leaves$n_elements == 0L | isTRUE_vec(leaves$dense))]
    ))
    leaves <- leaves[leaves$leaf_id %in% hit_leaf_ids, , drop = FALSE]
    lineage <- lineage[lineage$leaf_id %in% hit_leaf_ids, , drop = FALSE]
  }

  rownames(leaves) <- NULL
  rownames(elements) <- NULL
  rownames(lineage) <- NULL

  # 4. Table selection, box-to-row spatial convergence, and optional row slicing
  avail_tables <- names(cap$tables)
  target_tables <- if (!is.null(table)) {
    missing_tbls <- setdiff(table, avail_tables)
    if (length(missing_tbls) > 0L) {
      cli::cli_abort("Unknown table(s): {.val {missing_tbls}}.")
    }
    table
  } else if (has_scene_filter) {
    linked <- unique(lineage$table_id[!is.na(lineage$table_id)])
    intersect(linked, avail_tables)
  } else {
    avail_tables
  }

  panel_by_id <- if (length(cap$ir$panels %||% list()) > 0L) {
    stats::setNames(cap$ir$panels, vapply(cap$ir$panels, function(p) as.character(p$panel_id %||% ""), character(1L)))
  } else {
    list()
  }
  layer_by_built <- list()
  for (lyr in (cap$ir$layers %||% list())) {
    if (!is.null(lyr$built_table)) layer_by_built[[lyr$built_table]] <- lyr
  }

  out_tables <- stats::setNames(list(), character())
  matched_raw_rows <- stats::setNames(list(), character())

  for (tid in target_tables) {
    df <- cap$tables[[tid]]$data
    if (!("_row_id" %in% names(df))) {
      df <- cbind(
        data.frame(`_row_id` = seq_len(nrow(df)), check.names = FALSE, stringsAsFactors = FALSE),
        df
      )
    }

    # When querying by panel, slice built tables carrying a PANEL column to the
    # matched panel number(s) while preserving original 1-based _row_id values.
    if (!is.null(panel) && "PANEL" %in% names(df)) {
      linked_pids <- unique(lineage$panel_id[
        !is.na(lineage$panel_id) & !is.na(lineage$table_id) & lineage$table_id == tid
      ])
      pids_to_match <- if (length(linked_pids) > 0L) linked_pids else panel
      pnums <- suppressWarnings(as.integer(sub("^.*P([0-9]+)$", "\\1", pids_to_match)))
      pnums <- unique(pnums[!is.na(pnums)])
      if (length(pnums) > 0L) {
        df_panel <- suppressWarnings(as.integer(as.character(df$PANEL)))
        df <- df[!is.na(df_panel) & df_panel %in% pnums, , drop = FALSE]
        rownames(df) <- NULL
      }
    }

    # ISS-PROTO-01 / ISS-AGENT-01: When querying by spatial `box`, converge built
    # tables to the exact rows inside `box` via element bridges OR coordinate
    # inverse projection (which also works on rasterized dense leaves!).
    if (!is.null(box) && nrow(df) > 0L) {
      t_lin <- lineage[!is.na(lineage$table_id) & lineage$table_id == tid, , drop = FALSE]
      if (nrow(t_lin) > 0L) {
        t_lids <- t_lin$leaf_id
        has_dense <- any(leaves$dense[leaves$leaf_id %in% t_lids], na.rm = TRUE)
        sub_el <- elements[!is.na(elements$leaf_id) & elements$leaf_id %in% t_lids, , drop = FALSE]

        keep_rids <- integer()
        if (!has_dense && nrow(sub_el) > 0L) {
          if ("built_row_id" %in% names(sub_el) && any(!is.na(sub_el$built_row_id))) {
            keep_rids <- unique(as.integer(sub_el$built_row_id[!is.na(sub_el$built_row_id)]))
          } else if ("group_id" %in% names(sub_el) && any(!is.na(sub_el$group_id)) && "_group_key" %in% names(df)) {
            g_hits <- unique(sub_el$group_id[!is.na(sub_el$group_id)])
            keep_rids <- df[["_row_id"]][df[["_group_key"]] %in% g_hits]
          }
        }

        # Coordinate inverse-projection fallback (dense raster leaves or unbridged built tables)
        if (length(keep_rids) == 0L) {
          keep_rids <- query_box_inverse_rows(df, box, t_lin, panel_by_id)
        }

        if (length(keep_rids) > 0L) {
          df <- df[df[["_row_id"]] %in% keep_rids, , drop = FALSE]
          rownames(df) <- NULL
        }
      }
    }

    row_spec <- if (is.list(rows) && !is.data.frame(rows)) {
      if (tid %in% names(rows)) rows[[tid]] else NULL
    } else {
      rows
    }
    if (!is.null(row_spec)) {
      keep_idx <- resolve_row_filter(df, row_spec, tid)
      df <- df[keep_idx, , drop = FALSE]
      rownames(df) <- NULL
    }

    # Bridge matched built rows back to raw_row_ids (via _raw_row_id or group_indices)
    lyr_ent <- layer_by_built[[tid]]
    if (!is.null(lyr_ent) && !is.null(lyr_ent$raw_table) && nrow(df) > 0L) {
      rtid <- lyr_ent$raw_table
      r_ids <- integer()
      if ("_raw_row_id" %in% names(df)) {
        r_ids <- unique(as.integer(df[["_raw_row_id"]][!is.na(df[["_raw_row_id"]])]))
      } else if ("_group_key" %in% names(df) && !is.null(cap$ir$group_indices[[tid]])) {
        gmap <- cap$ir$group_indices[[tid]]
        gkeys <- unique(df[["_group_key"]])
        r_ids <- unique(as.integer(unlist(gmap[intersect(gkeys, names(gmap))], use.names = FALSE)))
      }
      if (length(r_ids) > 0L) {
        matched_raw_rows[[rtid]] <- sort(unique(c(matched_raw_rows[[rtid]] %||% integer(), r_ids)))
      }
    }

    out_tables[[tid]] <- df
  }

  # 5. Forward row -> element lookup when filtering by `rows` without `box` (ISS-AGENT-01)
  if (!is.null(rows) && is.null(box) && nrow(elements) > 0L && length(out_tables) > 0L) {
    target_brows_by_tid <- list()
    target_gkeys_by_tid <- list()

    for (tid in names(out_tables)) {
      df_s <- out_tables[[tid]]
      if (nrow(df_s) == 0L) next
      ent <- cap$tables[[tid]]
      if (identical(ent$role, "built")) {
        target_brows_by_tid[[tid]] <- df_s[["_row_id"]]
        if ("_group_key" %in% names(df_s)) {
          target_gkeys_by_tid[[tid]] <- unique(df_s[["_group_key"]])
        }
      } else if (identical(ent$role, "raw")) {
        raw_rids <- df_s[["_row_id"]]
        for (btid in names(layer_by_built)) {
          if (!identical(layer_by_built[[btid]]$raw_table, tid)) next
          bdf <- cap$tables[[btid]]$data
          if (!is.data.frame(bdf) || nrow(bdf) == 0L) next
          if ("_raw_row_id" %in% names(bdf)) {
            hits <- which(bdf[["_raw_row_id"]] %in% raw_rids)
            if (length(hits) > 0L) target_brows_by_tid[[btid]] <- unique(c(target_brows_by_tid[[btid]] %||% integer(), hits))
          } else if (!is.null(cap$ir$group_indices[[btid]])) {
            gmap <- cap$ir$group_indices[[btid]]
            g_hits <- names(Filter(function(v) any(unlist(v) %in% raw_rids), gmap))
            if (length(g_hits) > 0L) {
              target_gkeys_by_tid[[btid]] <- unique(c(target_gkeys_by_tid[[btid]] %||% character(), g_hits))
            }
          }
        }
      }
    }

    if (length(target_brows_by_tid) > 0L || length(target_gkeys_by_tid) > 0L) {
      el_keep <- rep(FALSE, nrow(elements))
      for (btid in union(names(target_brows_by_tid), names(target_gkeys_by_tid))) {
        b_lids <- cap$lineage$leaf_id[!is.na(cap$lineage$table_id) & cap$lineage$table_id == btid]
        in_l <- !is.na(elements$leaf_id) & elements$leaf_id %in% b_lids
        if (!any(in_l)) next
        brs <- target_brows_by_tid[[btid]] %||% integer()
        gks <- target_gkeys_by_tid[[btid]] %||% character()
        hit_r <- if (length(brs) > 0L && "built_row_id" %in% names(elements)) {
          in_l & !is.na(elements$built_row_id) & (elements$built_row_id %in% brs)
        } else {
          rep(FALSE, nrow(elements))
        }
        hit_g <- if (length(gks) > 0L && "group_id" %in% names(elements)) {
          in_l & !is.na(elements$group_id) & (elements$group_id %in% gks)
        } else {
          rep(FALSE, nrow(elements))
        }
        el_keep <- el_keep | hit_r | hit_g
      }
      if (any(el_keep)) {
        elements <- elements[el_keep, , drop = FALSE]
        rownames(elements) <- NULL
        hit_lids <- unique(elements$leaf_id[!is.na(elements$leaf_id)])
        leaves <- leaves[leaves$leaf_id %in% hit_lids, , drop = FALSE]
        rownames(leaves) <- NULL
        lineage <- lineage[lineage$leaf_id %in% hit_lids, , drop = FALSE]
        rownames(lineage) <- NULL
      }
    }
  }

  # Compute union focus bounding box across matched elements (for bidirectional grounding)
  focus_bbox_pt <- NULL
  if (nrow(elements) > 0L) {
    valid_e <- is.finite(elements$bbox_x0) & is.finite(elements$bbox_y0) &
      is.finite(elements$bbox_x1) & is.finite(elements$bbox_y1)
    if (any(valid_e)) {
      focus_bbox_pt <- round_pt(c(
        min(elements$bbox_x0[valid_e]),
        min(elements$bbox_y0[valid_e]),
        max(elements$bbox_x1[valid_e]),
        max(elements$bbox_y1[valid_e])
      ))
    }
  }

  structure(
    list(
      leaves = leaves,
      elements = elements,
      lineage = lineage,
      tables = out_tables,
      matched_raw_rows = matched_raw_rows,
      focus_bbox_pt = focus_bbox_pt,
      filters = list(
        panel = panel,
        leaf = leaf,
        box = box,
        table = table,
        rows = !is.null(rows)
      )
    ),
    class = "gloss_query_result"
  )
}

isTRUE_vec <- function(x) {
  !is.na(x) & as.logical(x)
}

query_box_inverse_rows <- function(df, box, t_lin, panel_by_id) {
  pids <- unique(t_lin$panel_id[!is.na(t_lin$panel_id)])
  if (length(pids) == 0L) return(integer())

  has_xy <- all(c("x", "y") %in% names(df))
  has_rect <- all(c("xmin", "xmax", "ymin", "ymax") %in% names(df))
  has_base_rect <- all(c("xleft", "xright", "ybottom", "ytop") %in% names(df))
  if (!has_xy && !has_rect && !has_base_rect) return(integer())

  hit_ids <- integer()
  for (pid in pids) {
    pan <- panel_by_id[[pid]]
    if (is.null(pan) || is.null(pan$bbox_pt) || is.null(pan$x_domain) || is.null(pan$y_domain)) next
    pbb <- unlist(pan$bbox_pt)
    if (!box_intersects(pbb[[1L]], pbb[[2L]], pbb[[3L]], pbb[[4L]], box)) next

    # Clip query box to panel bbox before inverse projection
    qx0 <- max(box[[1L]], pbb[[1L]])
    qy0 <- max(box[[2L]], pbb[[2L]])
    qx1 <- min(box[[3L]], pbb[[3L]])
    qy1 <- min(box[[4L]], pbb[[4L]])
    inv <- panel_px_to_rendered(pan, c(qx0, qx1), c(qy0, qy1))
    if (any(!is.finite(inv$x)) || any(!is.finite(inv$y))) next
    rx_lo <- min(inv$x)
    rx_hi <- max(inv$x)
    ry_lo <- min(inv$y)
    ry_hi <- max(inv$y)

    sub_mask <- rep(TRUE, nrow(df))
    if ("PANEL" %in% names(df)) {
      pnum <- suppressWarnings(as.integer(sub("^.*P([0-9]+)$", "\\1", pid)))
      if (!is.na(pnum)) {
        sub_mask <- as.integer(as.character(df$PANEL)) == pnum
      }
    }

    if (has_rect) {
      x0 <- as.numeric(df$xmin)
      x1 <- as.numeric(df$xmax)
      y0 <- as.numeric(df$ymin)
      y1 <- as.numeric(df$ymax)
      ok <- sub_mask & is.finite(x0) & is.finite(x1) & is.finite(y0) & is.finite(y1) &
        (x1 >= rx_lo) & (x0 <= rx_hi) & (y1 >= ry_lo) & (y0 <= ry_hi)
      hit_ids <- c(hit_ids, df[["_row_id"]][ok])
    } else if (has_base_rect) {
      x0 <- as.numeric(df$xleft)
      x1 <- as.numeric(df$xright)
      y0 <- as.numeric(df$ybottom)
      y1 <- as.numeric(df$ytop)
      ok <- sub_mask & is.finite(x0) & is.finite(x1) & is.finite(y0) & is.finite(y1) &
        (x1 >= rx_lo) & (x0 <= rx_hi) & (y1 >= ry_lo) & (y0 <= ry_hi)
      hit_ids <- c(hit_ids, df[["_row_id"]][ok])
    } else if (has_xy) {
      xv <- as.numeric(df$x)
      yv <- as.numeric(df$y)
      # Base log plots store raw data x/y in built_layer; transform if needed
      if (identical(pan$coord, "BaseGraphics")) {
        if (!is.null(pan$x_trans) && !identical(pan$x_trans, "identity")) xv <- apply_axis_trans(xv, pan$x_trans)
        if (!is.null(pan$y_trans) && !identical(pan$y_trans, "identity")) yv <- apply_axis_trans(yv, pan$y_trans)
      }
      ok <- sub_mask & is.finite(xv) & is.finite(yv) &
        (xv >= rx_lo) & (xv <= rx_hi) & (yv >= ry_lo) & (yv <= ry_hi)
      hit_ids <- c(hit_ids, df[["_row_id"]][ok])
    }
  }
  unique(as.integer(hit_ids))
}

box_intersects <- function(x0, y0, x1, y1, box) {
  ok <- is.finite(x0) & is.finite(y0) & is.finite(x1) & is.finite(y1)
  ok & (x1 >= box[[1L]]) & (x0 <= box[[3L]]) & (y1 >= box[[2L]]) & (y0 <= box[[4L]])
}

#' @export
print.gloss_query_result <- function(x, ...) {
  cat("<gloss_query_result>\n")
  cat(sprintf(
    "  matched : %d leaf/leaves, %d element(s), %d lineage row(s), %d table(s)\n",
    nrow(x$leaves),
    nrow(x$elements),
    nrow(x$lineage),
    length(x$tables)
  ))
  invisible(x)
}
