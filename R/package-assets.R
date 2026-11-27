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
    trole <- entry$role %||% "raw"
    eroles <- entity_column_roles_for_table(cap$entities %||% list(), tid)
    list(
      table_id = tid,
      role = trole,
      format = "csv",
      nrow = as.integer(nrow(df)),
      ncol = as.integer(ncol(df)),
      key = json_array(entry$key),
      path = paste0("tables/", tid, ".csv"),
      columns = json_array(table_column_summaries(df, table_role = trole, entity_roles = eroles))
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

  ir_entry <- list(
    panels = json_array(cap$ir$panels),
    layers = json_array(cap$ir$layers),
    scales = json_array(cap$ir$scales),
    orders = cap$ir$orders %||% stats::setNames(list(), character())
  )
  if (!is.null(cap$ir$guides)) {
    ir_entry$guides <- cap$ir$guides
  }
  if (!is.null(cap$ir$data_funnel) && length(cap$ir$data_funnel) > 0L) {
    ir_entry$data_funnel <- cap$ir$data_funnel
  }

  n_texts <- if (is.data.frame(cap$scene$elements) && nrow(cap$scene$elements) > 0L) {
    as.integer(sum(cap$scene$elements$tag == "text", na.rm = TRUE))
  } else {
    0L
  }

  scene_entry <- list(
    coord = cap$scene$coord %||% make_scene_coord(cap$page$width_pt, cap$page$height_pt),
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
    texts = list(
      path = "scene/texts.json",
      n_texts = n_texts
    ),
    n_panels = as.integer(length(cap$ir$panels)),
    n_leaves = as.integer(nrow(cap$scene$leaves)),
    n_elements = as.integer(nrow(cap$scene$elements)),
    dense_leaves = json_array(cap$scene$dense_leaves),
    role_contracts = default_role_contracts()
  )
  if (!is.null(cap$scene$preview_png) && is.raw(cap$scene$preview_png) && length(cap$scene$preview_png) > 0L) {
    dpi <- as.integer(cap$page$preview_dpi %||% 144L)
    scene_entry$preview_png <- list(
      path = "assets/preview.png",
      dpi = dpi,
      width_px = as.integer(round(cap$page$width_in * dpi)),
      height_px = as.integer(round(cap$page$height_in * dpi)),
      scale_from_pt = round(dpi / PT_PER_IN, 6L),
      bytes = as.integer(length(cap$scene$preview_png)),
      sha256 = sha256_raw(cap$scene$preview_png)
    )
  }
  if (!is.null(cap$scene$label_links) && length(cap$scene$label_links) > 0L) {
    scene_entry$label_links <- json_array(cap$scene$label_links)
  }
  if (!is.null(cap$scene$layout_tracks) && length(cap$scene$layout_tracks) > 0L) {
    scene_entry$layout_tracks <- cap$scene$layout_tracks
  }

  map_list <- list(
    format = "gloss-asset-map",
    package_version = cap$package_version %||% gloss_package_version(),
    schema_version = cap$schema_version,
    capture_id = cap$capture_id,
    created_at = cap$created_at,
    page = cap$page,
    scene = scene_entry,
    ir = ir_entry,
    entities = json_array(cap$entities %||% list()),
    tables = json_array(table_entries),
    lineage = json_array(df_to_records(cap$lineage)),
    sources = json_array(source_entries)
  )
  if (!is.null(cap$parent_capture_id)) {
    map_list$parent_capture_id <- cap$parent_capture_id
  }

  map <- structure(map_list, class = "gloss_asset_map")

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
#' @param table_format Serialization format for data tables under `tables/`:
#'   `"csv"` (default, zero extra dependencies) writes UTF-8 `.csv` files;
#'   `"parquet"` writes standard Apache Parquet `.parquet` files (requires the
#'   optional `nanoparquet` package in `Suggests`).
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
    table_format = c("csv", "parquet"),
    overwrite = TRUE) {

  validate_gloss_capture(cap)
  format <- match.arg(format)
  table_format <- match.arg(table_format)
  if (identical(table_format, "parquet") && !has_pkg("nanoparquet")) {
    cli::cli_abort(
      "Package {.pkg nanoparquet} is required for {.code table_format = \"parquet\"}. Install it or use {.code table_format = \"csv\"}."
    )
  }

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

  # 1. Dual SVG assets & optional preview.png
  write_utf8_file(cap$svg$original$text, file.path(stage_dir, "assets", "original.svg"))
  write_utf8_file(cap$svg$scene$text, file.path(stage_dir, "scene", "scene.svg"))

  preview_written <- FALSE
  if (!is.null(cap$scene$preview_png) && is.raw(cap$scene$preview_png) && length(cap$scene$preview_png) > 0L) {
    if (isTRUE(sel$preview)) {
      write_raw_file(cap$scene$preview_png, file.path(stage_dir, "assets", "preview.png"))
      preview_written <- TRUE
    } else {
      omitted <- add_omitted(
        kind = "asset",
        id = "preview_png",
        reason = "excluded_by_select",
        bytes = as.integer(length(cap$scene$preview_png))
      )
    }
  }

  # Record omitted pages when input drew multiple pages
  if (!is.null(cap$page$pages) && cap$page$pages > 1L) {
    sel_pg <- as.integer(cap$page$selected_page %||% cap$page$pages)
    skipped_pgs <- setdiff(seq_len(cap$page$pages), sel_pg)
    if (length(skipped_pgs) > 0L) {
      omitted <- add_omitted(
        kind = "pages",
        id = "multi_page_input",
        reason = "single_page_selected",
        total_pages = as.integer(cap$page$pages),
        selected_page = sel_pg,
        omitted_pages = json_array(skipped_pgs)
      )
    }
  }

  # 2. Scene metadata, lightweight texts.json, & optional rasters
  leaves_recs <- build_leaves_json_records(cap$scene$leaves)
  write_gloss_json(
    json_array(leaves_recs),
    file.path(stage_dir, "scene", "leaves.json")
  )

  texts_recs <- build_texts_json_records(cap$scene$elements, cap$scene$leaves, cap$lineage)
  texts_path <- file.path(stage_dir, "scene", "texts.json")
  write_gloss_json(json_array(texts_recs), texts_path)

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

  # Group-to-raw-row index files for stat_aggregated / N:1 layers
  if (!is.null(cap$ir$group_indices) && length(cap$ir$group_indices) > 0L) {
    for (gid in names(cap$ir$group_indices)) {
      if (!is.null(sel$tables) && !(gid %in% names(sel$tables))) next
      write_gloss_json(
        cap$ir$group_indices[[gid]],
        file.path(stage_dir, "tables", paste0("groups_", gid, ".json"))
      )
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

    tbl_ext <- if (identical(table_format, "parquet")) ".parquet" else ".csv"
    tbl_rel_path <- paste0("tables/", tid, tbl_ext)
    tbl_disk_path <- file.path(stage_dir, tbl_rel_path)
    if (identical(table_format, "parquet")) {
      write_gloss_parquet(df_with_id, tbl_disk_path, add_row_id = FALSE)
    } else {
      write_gloss_csv(df_with_id, tbl_disk_path, add_row_id = FALSE)
    }

    trole <- entry$role %||% "raw"
    eroles <- entity_column_roles_for_table(cap$entities %||% list(), tid)
    table_schemas[[tid]] <- list(
      table_id = tid,
      role = trole,
      format = table_format,
      path = tbl_rel_path,
      key = json_array(entry$key),
      nrow = as.integer(nrow(df_with_id)),
      columns = json_array(table_schema_spec(df_with_id, add_row_id = FALSE, table_role = trole, entity_roles = eroles))
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
  included_sources <- character()
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
    included_sources <- c(included_sources, sid)
    if (is_session) wrote_session <- TRUE
  }

  if (!wrote_session && (is.null(sel$sources) || "session" %in% sel$sources)) {
    write_gloss_json(cap$session, file.path(stage_dir, "sources", "session.json"))
    included_sources <- c(included_sources, "session")
  }

  # 5. Asset Map (annotated with exact bundle inclusion state) & omitted.json
  map <- gl_asset_map(cap)
  map$scene$elements_included <- isTRUE(sel$elements)
  map$scene$texts$bytes <- as.integer(file.info(texts_path)$size)
  map$scene$texts$sha256 <- sha256_file(texts_path)
  if (!is.null(map$scene$preview_png)) {
    map$scene$preview_png$included <- isTRUE(preview_written)
  }
  if (length(map$tables) > 0L) {
    tbl_ext <- if (identical(table_format, "parquet")) ".parquet" else ".csv"
    map$tables <- lapply(map$tables, function(tb) {
      inc <- tb$table_id %in% names(table_schemas)
      tb$format <- table_format
      tb$path <- paste0("tables/", tb$table_id, tbl_ext)
      tb$included <- isTRUE(inc)
      tb$bundle_nrow <- if (inc) as.integer(table_schemas[[tb$table_id]]$nrow) else 0L
      tb
    })
  }
  if (length(map$sources) > 0L) {
    map$sources <- lapply(map$sources, function(sr) {
      sr$included <- sr$source_id %in% included_sources
      sr
    })
  }
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

  manifest_payload <- list(
    format = "gloss-asset-bundle",
    package_version = cap$package_version %||% gloss_package_version(),
    schema_version = cap$schema_version,
    capture_id = cap$capture_id,
    created_at = cap$created_at,
    parent_manifest_sha256 = NULL,
    parent_capture_id = cap$parent_capture_id,
    files = json_array(manifest_files)
  )

  write_gloss_json(
    manifest_payload,
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

build_leaves_json_records <- function(leaves_df) {
  recs <- df_to_records(leaves_df)
  if (length(recs) == 0L) return(recs)
  lapply(recs, function(r) {
    cx <- c(r$clip_x0, r$clip_y0, r$clip_x1, r$clip_y1)
    r$clip_bbox_pt <- if (length(cx) == 4L && all(vapply(cx, function(v) is.numeric(v) && is.finite(v), logical(1L)))) {
      json_array(as.numeric(cx))
    } else {
      NULL
    }
    r
  })
}

build_texts_json_records <- function(elements_df, leaves_df, lineage_df) {
  if (!is.data.frame(elements_df) || nrow(elements_df) == 0L) {
    return(list())
  }
  idx <- which(elements_df$tag == "text")
  if (length(idx) == 0L) return(list())

  l_map <- if (is.data.frame(leaves_df) && nrow(leaves_df) > 0L) {
    stats::setNames(seq_len(nrow(leaves_df)), leaves_df$leaf_id)
  } else {
    integer()
  }
  lin_map <- if (is.data.frame(lineage_df) && nrow(lineage_df) > 0L) {
    stats::setNames(seq_len(nrow(lineage_df)), lineage_df$leaf_id)
  } else {
    integer()
  }

  n_txt <- length(idx)
  has_anc <- all(c("anchor_x", "anchor_y") %in% names(elements_df))
  has_mw <- "measured_width_pt" %in% names(elements_df)
  has_tanc <- all(c("target_anchor_x", "target_anchor_y") %in% names(elements_df))
  has_brid <- "built_row_id" %in% names(elements_df)

  # K5: Group consecutive multi-line <text> fragments within a leaf into logical text blocks
  block_ids <- character(n_txt)
  line_indices <- integer(n_txt)
  block_num <- 0L

  role_of <- vapply(seq_len(n_txt), function(k) {
    lid <- elements_df$leaf_id[[idx[[k]]]]
    li <- if (!is.na(lid) && lid %in% names(l_map)) l_map[[lid]] else NA_integer_
    if (!is.na(li) && !is.na(leaves_df$semantic_role[[li]])) leaves_df$semantic_role[[li]] else "annotation"
  }, character(1L))

  can_merge_with_prev <- function(k_prev, k_cur) {
    i1 <- idx[[k_prev]]
    i2 <- idx[[k_cur]]
    l1 <- elements_df$leaf_id[[i1]]
    l2 <- elements_df$leaf_id[[i2]]
    if (is.na(l1) || is.na(l2) || !identical(l1, l2)) return(FALSE)

    # Same bridged built_row_id on a data_label always merges multi-line fragments
    if (has_brid && !is.na(elements_df$built_row_id[[i1]]) && !is.na(elements_df$built_row_id[[i2]])) {
      if (identical(elements_df$built_row_id[[i1]], elements_df$built_row_id[[i2]])) return(TRUE)
      return(FALSE)
    }

    rot1 <- if (is.finite(elements_df$rotation[[i1]])) elements_df$rotation[[i1]] else 0.0
    rot2 <- if (is.finite(elements_df$rotation[[i2]])) elements_df$rotation[[i2]] else 0.0
    if (abs(rot1 - rot2) > 1.0) return(FALSE)

    fs <- if (is.finite(elements_df$font_size[[i1]])) elements_df$font_size[[i1]] else 12.0
    ax1 <- if (has_anc && is.finite(elements_df$anchor_x[[i1]])) elements_df$anchor_x[[i1]] else elements_df$bbox_x0[[i1]]
    ay1 <- if (has_anc && is.finite(elements_df$anchor_y[[i1]])) elements_df$anchor_y[[i1]] else elements_df$bbox_y1[[i1]]
    ax2 <- if (has_anc && is.finite(elements_df$anchor_x[[i2]])) elements_df$anchor_x[[i2]] else elements_df$bbox_x0[[i2]]
    ay2 <- if (has_anc && is.finite(elements_df$anchor_y[[i2]])) elements_df$anchor_y[[i2]] else elements_df$bbox_y1[[i2]]
    if (!all(is.finite(c(ax1, ay1, ax2, ay2)))) return(FALSE)

    dx <- abs(ax2 - ax1)
    dy <- abs(ay2 - ay1)
    max_step <- max(fs * 2.1, 18.0)

    # Rotated vertical text (e.g. rotated Y axis title at +-90 deg) stacks horizontally
    if (abs(abs(rot1) - 90.0) <= 5.0) {
      return(dy <= 2.0 && dx >= fs * 0.4 && dx <= max_step)
    }
    # Horizontal text stacks vertically along aligned anchor column
    dx <= 2.0 && dy >= fs * 0.4 && dy <= max_step
  }

  for (k in seq_len(n_txt)) {
    if (k > 1L && can_merge_with_prev(k - 1L, k)) {
      block_ids[[k]] <- block_ids[[k - 1L]]
      line_indices[[k]] <- line_indices[[k - 1L]] + 1L
    } else {
      block_num <- block_num + 1L
      block_ids[[k]] <- sprintf("TB%04d", block_num)
      line_indices[[k]] <- 1L
    }
  }

  txt_strs <- ifelse(is.na(elements_df$text[idx]), "", elements_df$text[idx])
  block_groups <- split(seq_len(n_txt), block_ids)
  block_full_text <- vapply(block_groups, function(ks) paste(txt_strs[ks], collapse = "\n"), character(1L))
  block_line_count <- vapply(block_groups, length, integer(1L))

  lapply(seq_len(n_txt), function(k) {
    i <- idx[[k]]
    lid <- elements_df$leaf_id[[i]]
    li <- if (!is.na(lid) && lid %in% names(l_map)) l_map[[lid]] else NA_integer_
    lni <- if (!is.na(lid) && lid %in% names(lin_map)) lin_map[[lid]] else NA_integer_
    bid <- block_ids[[k]]

    bb <- c(elements_df$bbox_x0[[i]], elements_df$bbox_y0[[i]], elements_df$bbox_x1[[i]], elements_df$bbox_y1[[i]])
    anc_pt <- if (has_anc && is.finite(elements_df$anchor_x[[i]]) && is.finite(elements_df$anchor_y[[i]])) {
      json_array(round_pt(c(elements_df$anchor_x[[i]], elements_df$anchor_y[[i]])))
    } else {
      NULL
    }
    mw_pt <- if (has_mw && is.finite(elements_df$measured_width_pt[[i]])) {
      round_pt(elements_df$measured_width_pt[[i]])
    } else if (all(is.finite(bb))) {
      round_pt(bb[[3L]] - bb[[1L]])
    } else {
      NULL
    }
    tanc_pt <- if (has_tanc && is.finite(elements_df$target_anchor_x[[i]]) && is.finite(elements_df$target_anchor_y[[i]])) {
      json_array(round_pt(c(elements_df$target_anchor_x[[i]], elements_df$target_anchor_y[[i]])))
    } else {
      NULL
    }

    list(
      element_id = elements_df$element_id[[i]],
      leaf_id = if (is.na(lid)) NULL else lid,
      text_block_id = bid,
      line_index = as.integer(line_indices[[k]]),
      line_count = as.integer(block_line_count[[bid]]),
      block_text = unname(block_full_text[[bid]]),
      panel_id = if (!is.na(lni) && !is.na(lineage_df$panel_id[[lni]])) lineage_df$panel_id[[lni]] else NULL,
      layer_id = if (!is.na(lni) && !is.na(lineage_df$layer_id[[lni]])) as.integer(lineage_df$layer_id[[lni]]) else NULL,
      subplot = if (!is.na(li) && "subplot" %in% names(leaves_df) && !is.na(leaves_df$subplot[[li]])) as.integer(leaves_df$subplot[[li]]) else NULL,
      layout_slot = if (!is.na(li) && !is.na(leaves_df$layout_slot[[li]])) leaves_df$layout_slot[[li]] else NULL,
      semantic_role = role_of[[k]],
      edit_policy = if (!is.na(li) && !is.na(leaves_df$edit_policy[[li]])) leaves_df$edit_policy[[li]] else "movable",
      text = txt_strs[[k]],
      bbox_pt = if (all(is.finite(bb))) json_array(round_pt(bb)) else NULL,
      anchor_pt = anc_pt,
      measured_width_pt = mw_pt,
      target_anchor_pt = tanc_pt,
      font_size = if (is.finite(elements_df$font_size[[i]])) elements_df$font_size[[i]] else NULL,
      font_family = if (!is.na(elements_df$font_family[[i]])) elements_df$font_family[[i]] else NULL,
      text_anchor = if (!is.na(elements_df$text_anchor[[i]])) elements_df$text_anchor[[i]] else NULL,
      rotation = if (is.finite(elements_df$rotation[[i]])) elements_df$rotation[[i]] else 0.0,
      fill = if (!is.na(elements_df$fill[[i]])) elements_df$fill[[i]] else NULL,
      built_row_id = if (has_brid && !is.na(elements_df$built_row_id[[i]])) as.integer(elements_df$built_row_id[[i]]) else NULL
    )
  })
}

parse_bundle_select <- function(select, cap) {
  out <- list(tables = NULL, sources = NULL, elements = TRUE, preview = TRUE)
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
    out$elements <- "elements" %in% select
    out$preview <- !("no_preview" %in% select)
    return(out)
  }

  if (!is.list(select)) {
    cli::cli_abort("{.arg select} must be NULL, a character vector, or a named list.")
  }

  if ("elements" %in% names(select)) {
    out$elements <- isTRUE(select$elements)
  }
  if ("preview" %in% names(select)) {
    out$preview <- isTRUE(select$preview)
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
