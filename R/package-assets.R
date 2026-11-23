# Layered open-format packaging: Asset Map (asset-map.json) and
# Asset Bundle (.gloss/ directory or .zip archive).
#
# Both functions serialize directly from an in-memory `gloss_capture` object
# and never redraw the figure.

#' Build or write the lightweight Asset Map for a captured figure
#'
#' Produces a compact, cross-language JSON-ready index (`gloss-asset-map`)
#' describing the figure's page geometry, SVG digests, engine intermediate
#' representation (`panels`, `layers`, `scales`, `orders`), table column
#' summaries, structural lineage, and source context inventory.
#'
#' @param cap A `gloss_capture` object returned by [gloss()].
#' @param path Optional file path at which to write `asset-map.json`. When
#'   `NULL` (default), returns the `gloss_asset_map` object in memory without
#'   writing to disk.
#'
#' @return A `gloss_asset_map` list (returned invisibly when `path` is written).
#' @export
#' @examples
#' cap <- gloss(grid::rectGrob(width = 0.5, height = 0.5, name = "box"))
#' map <- gl_asset_map(cap)
#' map$page$engine
gl_asset_map <- function(cap, path = NULL) {
  validate_gloss_capture(cap)

  table_entries <- lapply(names(cap$tables), function(tid) {
    entry <- cap$tables[[tid]]
    df <- entry$data
    list(
      table_id = tid,
      role = entry$role %||% "raw",
      nrow = as.integer(nrow(df)),
      ncol = as.integer(ncol(df)),
      key = json_array(entry$key),
      path = paste0("tables/", tid, ".csv"),
      columns = json_array(table_column_summaries(df))
    )
  })

  source_entries <- lapply(cap$sources, function(src) {
    list(
      source_id = src$source_id,
      kind = src$kind,
      provenance_mode = src$provenance_mode,
      found = isTRUE(src$found),
      readable = isTRUE(src$readable),
      path = src$path,
      bytes = if (is.null(src$bytes) || is.na(src$bytes)) NULL else as.integer(src$bytes),
      sha256 = if (is.null(src$sha256) || is.na(src$sha256)) NULL else as.character(src$sha256)
    )
  })

  map <- structure(
    list(
      format = "gloss-asset-map",
      schema_version = cap$schema_version,
      capture_id = cap$capture_id,
      created_at = cap$created_at,
      page = cap$page,
      scene = list(
        original_svg = list(
          path = "assets/original.svg",
          bytes = as.integer(cap$svg$original$bytes),
          sha256 = cap$svg$original$sha256
        ),
        scene_svg = list(
          path = "scene/scene.svg",
          bytes = as.integer(cap$svg$scene$bytes),
          sha256 = cap$svg$scene$sha256
        ),
        n_panels = as.integer(length(cap$ir$panels)),
        n_leaves = as.integer(nrow(cap$scene$leaves)),
        n_elements = as.integer(nrow(cap$scene$elements)),
        dense_leaves = json_array(cap$scene$dense_leaves)
      ),
      ir = list(
        panels = json_array(cap$ir$panels),
        layers = json_array(cap$ir$layers),
        scales = json_array(cap$ir$scales),
        orders = cap$ir$orders %||% stats::setNames(list(), character())
      ),
      tables = json_array(table_entries),
      lineage = json_array(df_to_records(cap$lineage)),
      sources = json_array(source_entries)
    ),
    class = "gloss_asset_map"
  )

  if (!is.null(path)) {
    if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
      cli::cli_abort("{.arg path} must be a single non-empty file path.")
    }
    write_gloss_json(unclass(map), path)
    return(invisible(map))
  }

  map
}

#' @export
print.gloss_asset_map <- function(x, ...) {
  cat(sprintf("<gloss_asset_map %s>\n", x$capture_id))
  cat(sprintf(
    "  engine : %s | %d panel(s), %d leaf/leaves, %d element(s)\n",
    x$page$engine,
    x$scene$n_panels,
    x$scene$n_leaves,
    x$scene$n_elements
  ))
  cat(sprintf(
    "  index  : %d table(s), %d scale(s), %d source(s)\n",
    length(x$tables),
    length(x$ir$scales),
    length(x$sources)
  ))
  invisible(x)
}

#' Package a captured figure into a portable open-format Asset Bundle
#'
#' Serializes a `gloss_capture` into a self-contained `.gloss/` directory or
#' `.zip` archive containing standard UTF-8 SVG (`assets/original.svg`,
#' `scene/scene.svg`), JSON (`manifest.json`, `asset-map.json`, `omitted.json`,
#' `scene/leaves.json`, `scene/elements.json`, `tables/schema.json`,
#' `sources/session.json`), CSV data tables (`tables/*.csv` with explicit
#' 1-based `_row_id`), optional raster slices (`scene/rasters/*.png`), and
#' snapshot source files (`sources/`).
#'
#' @param cap A `gloss_capture` object returned by [gloss()].
#' @param path Output directory or `.zip` archive path. Defaults to a path
#'   inside [tempdir()].
#' @param select Optional selection filter controlling which tables, columns,
#'   sources, or scene element details are included. `NULL` (default) packages
#'   the complete standard set. May be a character vector of table/source IDs
#'   or a named list with optional entries `tables` (character vector of table
#'   IDs, or a named list mapping table IDs to selected column names),
#'   `sources` (character vector of source IDs), and `elements` (logical).
#' @param rows Optional named list keyed by table ID specifying row filtering
#'   for each table. Each value may be an integer vector of 1-based row indices,
#'   a logical vector of length `nrow(df)`, or a predicate function taking the
#'   data frame and returning a logical or integer index vector. Original
#'   1-based `_row_id` values are preserved.
#' @param format Output format: `"dir"` (default) writes a directory bundle;
#'   `"zip"` writes a portable ZIP archive.
#' @param overwrite Logical; whether to replace an existing directory or archive
#'   at `path`. Defaults to `TRUE`.
#'
#' @return Invisibly returns the normalized output path.
#' @export
#' @examples
#' cap <- gloss(grid::rectGrob(width = 0.5, height = 0.5, name = "box"))
#' bundle_dir <- gl_asset_bundle(cap, path = file.path(tempdir(), "demo.gloss"))
#' list.files(bundle_dir)
gl_asset_bundle <- function(
    cap,
    path = NULL,
    select = NULL,
    rows = NULL,
    format = c("dir", "zip"),
    overwrite = TRUE) {

  validate_gloss_capture(cap)
  format <- match.arg(format)

  if (is.null(path)) {
    default_name <- if (identical(format, "zip")) "figure.gloss.zip" else "figure.gloss"
    path <- file.path(tempdir(), default_name)
  }
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    cli::cli_abort("{.arg path} must be a single non-empty path.")
  }

  target_exists <- file.exists(path) || dir.exists(path)
  if (target_exists && !isTRUE(overwrite)) {
    cli::cli_abort(
      "Target {.path {path}} already exists. Pass {.code overwrite = TRUE} to replace it."
    )
  }

  # Stage all files inside a fresh temp directory so failed writes never corrupt target
  stage_dir <- tempfile("gloss_bundle_")
  dir.create(stage_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(stage_dir, recursive = TRUE, force = TRUE), add = TRUE)

  omitted <- list()
  add_omitted <- function(kind, id, reason, ...) {
    entry <- c(list(kind = kind, id = id, reason = reason), list(...))
    omitted[[length(omitted) + 1L]] <- entry
    omitted
  }

  sel <- parse_bundle_select(select, cap)

  # 1. Dual SVG assets
  write_utf8_file(cap$svg$original$text, file.path(stage_dir, "assets", "original.svg"))
  write_utf8_file(cap$svg$scene$text, file.path(stage_dir, "scene", "scene.svg"))

  # 2. Scene metadata & optional rasters
  write_gloss_json(
    json_array(df_to_records(cap$scene$leaves)),
    file.path(stage_dir, "scene", "leaves.json")
  )

  if (isTRUE(sel$elements)) {
    write_gloss_json(
      json_array(df_to_records(cap$scene$elements)),
      file.path(stage_dir, "scene", "elements.json")
    )
  } else {
    omitted <- add_omitted(
      kind = "scene",
      id = "elements",
      reason = "excluded_by_select",
      n_elements = as.integer(nrow(cap$scene$elements))
    )
  }

  if (length(cap$scene$rasters) > 0L) {
    raster_dir <- file.path(stage_dir, "scene", "rasters")
    dir.create(raster_dir, recursive = TRUE, showWarnings = FALSE)
    for (lid in names(cap$scene$rasters)) {
      write_raw_file(cap$scene$rasters[[lid]], file.path(raster_dir, paste0(lid, ".png")))
    }
  }

  # 3. Tables (CSV + schema.json), applying `select` and `rows` with preserved _row_id
  if (!is.null(rows) && !is.list(rows)) {
    cli::cli_abort("{.arg rows} must be NULL or a named list keyed by table ID.")
  }

  table_schemas <- stats::setNames(list(), character())
  for (tid in names(cap$tables)) {
    entry <- cap$tables[[tid]]
    full_df <- entry$data
    orig_nrow <- as.integer(nrow(full_df))

    if (!is.null(sel$tables) && !(tid %in% names(sel$tables))) {
      omitted <- add_omitted(
        kind = "table",
        id = tid,
        reason = "excluded_by_select",
        original_nrow = orig_nrow,
        original_ncol = as.integer(ncol(full_df))
      )
      next
    }

    # Preserve original 1-based _row_id before any row slicing
    df_with_id <- full_df
    if (!("_row_id" %in% names(df_with_id))) {
      df_with_id <- cbind(
        data.frame(`_row_id` = seq_len(orig_nrow), check.names = FALSE, stringsAsFactors = FALSE),
        df_with_id
      )
    }

    # Optional row filtering
    if (!is.null(rows) && tid %in% names(rows)) {
      keep_idx <- resolve_row_filter(df_with_id, rows[[tid]], tid)
      df_with_id <- df_with_id[keep_idx, , drop = FALSE]
      rownames(df_with_id) <- NULL
      if (nrow(df_with_id) < orig_nrow) {
        omitted <- add_omitted(
          kind = "table_rows",
          id = tid,
          reason = "filtered_by_rows",
          original_nrow = orig_nrow,
          included_nrow = as.integer(nrow(df_with_id)),
          omitted_nrow = as.integer(orig_nrow - nrow(df_with_id))
        )
      }
    }

    # Optional column projection
    col_spec <- if (!is.null(sel$tables)) sel$tables[[tid]] else NULL
    if (!is.null(col_spec)) {
      data_cols <- setdiff(names(df_with_id), "_row_id")
      keep_cols <- intersect(col_spec, data_cols)
      dropped_cols <- setdiff(data_cols, keep_cols)
      df_with_id <- df_with_id[, c("_row_id", keep_cols), drop = FALSE]
      if (length(dropped_cols) > 0L) {
        omitted <- add_omitted(
          kind = "table_columns",
          id = tid,
          reason = "excluded_by_select",
          omitted_columns = json_array(dropped_cols)
        )
      }
    }

    csv_path <- file.path(stage_dir, "tables", paste0(tid, ".csv"))
    write_gloss_csv(df_with_id, csv_path, add_row_id = FALSE)

    table_schemas[[tid]] <- list(
      table_id = tid,
      role = entry$role %||% "raw",
      key = json_array(entry$key),
      nrow = as.integer(nrow(df_with_id)),
      columns = json_array(table_schema_spec(df_with_id, add_row_id = FALSE))
    )
  }

  if (length(table_schemas) > 0L) {
    write_gloss_json(
      list(
        format = "gloss-table-schema",
        schema_version = cap$schema_version,
        tables = table_schemas
      ),
      file.path(stage_dir, "tables", "schema.json")
    )
  }

  # 4. Sources & session.json
  wrote_session <- FALSE
  for (src in cap$sources) {
    sid <- src$source_id
    is_session <- identical(sid, "session") && identical(src$path, "sources/session.json")

    if (!is.null(sel$sources) && !(sid %in% sel$sources)) {
      omitted <- add_omitted(
        kind = "source",
        id = sid,
        reason = "excluded_by_select",
        path = src$path
      )
      next
    }

    if (!isTRUE(src$found)) {
      omitted <- add_omitted(
        kind = "source",
        id = sid,
        reason = "not_found",
        path = src$origin_path %||% src$path
      )
      next
    }
    if (!isTRUE(src$readable)) {
      omitted <- add_omitted(
        kind = "source",
        id = sid,
        reason = "not_readable",
        path = src$origin_path %||% src$path
      )
      next
    }

    dest <- file.path(stage_dir, src$path)
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    if (!is.null(src$inline_text)) {
      write_utf8_file(src$inline_text, dest)
    } else if (!is.null(src$origin_path) && !is.na(src$origin_path) && file.exists(src$origin_path)) {
      ok <- file.copy(src$origin_path, dest, overwrite = TRUE)
      if (!isTRUE(ok)) {
        omitted <- add_omitted(
          kind = "source",
          id = sid,
          reason = "copy_failed",
          path = src$origin_path
        )
        next
      }
    }
    if (is_session) wrote_session <- TRUE
  }

  if (!wrote_session && (is.null(sel$sources) || "session" %in% sel$sources)) {
    write_gloss_json(cap$session, file.path(stage_dir, "sources", "session.json"))
  }

  # 5. Asset Map & omitted.json
  map <- gl_asset_map(cap)
  write_gloss_json(unclass(map), file.path(stage_dir, "asset-map.json"))

  write_gloss_json(
    list(
      format = "gloss-omitted",
      schema_version = cap$schema_version,
      capture_id = cap$capture_id,
      omitted = json_array(omitted)
    ),
    file.path(stage_dir, "omitted.json")
  )

  # 6. manifest.json enumerating all staged files with exact bytes & sha256
  rel_files <- sort(list.files(stage_dir, recursive = TRUE, all.files = FALSE, no.. = TRUE))
  manifest_files <- lapply(rel_files, function(rf) {
    full <- file.path(stage_dir, rf)
    list(
      path = rf,
      bytes = as.integer(file.info(full)$size),
      sha256 = sha256_file(full)
    )
  })

  write_gloss_json(
    list(
      format = "gloss-asset-bundle",
      schema_version = cap$schema_version,
      capture_id = cap$capture_id,
      created_at = cap$created_at,
      parent_manifest_sha256 = NULL,
      files = json_array(manifest_files)
    ),
    file.path(stage_dir, "manifest.json")
  )

  # 7. Finalize to target directory or zip archive
  if (identical(format, "dir")) {
    if (target_exists) {
      unlink(path, recursive = TRUE, force = TRUE)
    }
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
    top_items <- list.files(stage_dir, full.names = TRUE, all.files = FALSE, no.. = TRUE)
    for (item in top_items) {
      file.copy(item, path, recursive = TRUE, overwrite = TRUE)
    }
    return(invisible(normalizePath(path, winslash = "/", mustWork = FALSE)))
  }

  # format == "zip"
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (target_exists) {
    unlink(path, recursive = TRUE, force = TRUE)
  }
  abs_zip <- normalizePath(path, winslash = "/", mustWork = FALSE)
  zip_stage_dir(stage_dir, abs_zip)
  invisible(abs_zip)
}

# --- Bundle serialization helpers --------------------------------------------

write_utf8_file <- function(text, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(enc2utf8(as.character(text)[[1L]])), con)
  invisible(path)
}

write_raw_file <- function(raw_bytes, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeBin(raw_bytes, con)
  invisible(path)
}

zip_stage_dir <- function(stage_dir, zip_path) {
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(stage_dir)
  all_files <- sort(list.files(".", recursive = TRUE, all.files = FALSE, no.. = TRUE))
  status <- suppressWarnings(utils::zip(zipfile = zip_path, files = all_files, flags = "-r9Xq"))
  if (!identical(status, 0L) || !file.exists(zip_path)) {
    cli::cli_abort("Failed to create ZIP asset bundle at {.path {zip_path}}.")
  }
  invisible(zip_path)
}

parse_bundle_select <- function(select, cap) {
  out <- list(tables = NULL, sources = NULL, elements = TRUE)
  if (is.null(select)) {
    return(out)
  }

  table_ids <- names(cap$tables)
  source_ids <- vapply(cap$sources, function(s) s$source_id, character(1L))

  if (is.character(select)) {
    tbl_hits <- intersect(select, table_ids)
    src_hits <- intersect(select, source_ids)
    out$tables <- stats::setNames(vector("list", length(tbl_hits)), tbl_hits)
    out$sources <- src_hits
    if ("elements" %in% select) {
      out$elements <- TRUE
    }
    return(out)
  }

  if (!is.list(select)) {
    cli::cli_abort("{.arg select} must be NULL, a character vector, or a named list.")
  }

  if ("elements" %in% names(select)) {
    out$elements <- isTRUE(select$elements)
  }

  if ("tables" %in% names(select)) {
    ts <- select$tables
    if (is.character(ts)) {
      out$tables <- stats::setNames(vector("list", length(ts)), ts)
    } else if (is.list(ts)) {
      out$tables <- ts
    } else if (isFALSE(ts)) {
      out$tables <- stats::setNames(list(), character())
    } else if (!is.null(ts)) {
      cli::cli_abort("{.code select$tables} must be a character vector, a named list of column names, or FALSE.")
    }
  }

  if ("sources" %in% names(select)) {
    ss <- select$sources
    if (is.character(ss)) {
      out$sources <- ss
    } else if (isFALSE(ss)) {
      out$sources <- character()
    } else if (!is.null(ss)) {
      cli::cli_abort("{.code select$sources} must be a character vector or FALSE.")
    }
  }

  out
}

resolve_row_filter <- function(df, spec, table_id) {
  n <- nrow(df)
  if (is.null(spec)) {
    return(seq_len(n))
  }
  if (is.function(spec)) {
    spec <- spec(df)
  }
  if (is.logical(spec)) {
    if (length(spec) != n) {
      cli::cli_abort(
        "Logical row filter for table {.val {table_id}} must have length {n}, not {length(spec)}."
      )
    }
    return(which(!is.na(spec) & spec))
  }
  if (is.numeric(spec)) {
    idx <- as.integer(spec)
    idx <- idx[!is.na(idx) & idx >= 1L & idx <= n]
    return(idx)
  }
  cli::cli_abort(
    "Row filter for table {.val {table_id}} must be an integer vector, logical vector, or predicate function."
  )
}
