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
      original_svg = cap$svg$original,
      scene_svg = cap$svg$scene,
      leaves = cap$scene$leaves,
      elements = cap$scene$elements,
      dense_leaves = cap$scene$dense_leaves,
      rasters = cap$scene$rasters,
      panels = cap$ir$panels,
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
    hit_leaf_ids <- unique(c(
      elements$leaf_id[!is.na(elements$leaf_id)],
      leaves$leaf_id[leaf_box_hit & leaves$n_elements == 0L]
    ))
    leaves <- leaves[leaves$leaf_id %in% hit_leaf_ids, , drop = FALSE]
    lineage <- lineage[lineage$leaf_id %in% hit_leaf_ids, , drop = FALSE]
  }

  rownames(leaves) <- NULL
  rownames(elements) <- NULL
  rownames(lineage) <- NULL

  # 4. Table selection and optional row slicing
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

  out_tables <- stats::setNames(list(), character())
  for (tid in target_tables) {
    df <- cap$tables[[tid]]$data
    if (!("_row_id" %in% names(df))) {
      df <- cbind(
        data.frame(`_row_id` = seq_len(nrow(df)), check.names = FALSE, stringsAsFactors = FALSE),
        df
      )
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
    out_tables[[tid]] <- df
  }

  structure(
    list(
      leaves = leaves,
      elements = elements,
      lineage = lineage,
      tables = out_tables,
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
