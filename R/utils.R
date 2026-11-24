# Internal utilities, serialization helpers, and the gloss_capture S3 contract.

GLOSS_SCHEMA_VERSION <- "1.1.0"

# --- Hashing & timestamps ----------------------------------------------------

sha256_raw <- function(x) {
  if (!is.raw(x)) {
    cli::cli_abort("{.arg x} must be a raw vector.")
  }
  digest::digest(x, algo = "sha256", serialize = FALSE)
}

sha256_text <- function(text) {
  if (!is.character(text) || length(text) != 1L || is.na(text)) {
    cli::cli_abort("{.arg text} must be a single non-NA character string.")
  }
  sha256_raw(charToRaw(enc2utf8(text)))
}

sha256_file <- function(path) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    cli::cli_abort("File does not exist: {.path {path}}.")
  }
  digest::digest(file = path, algo = "sha256")
}

prefixed_sha256 <- function(hash) {
  paste0("sha256:", hash)
}

utf8_nbytes <- function(text) {
  if (!is.character(text) || length(text) != 1L || is.na(text)) {
    return(0L)
  }
  length(charToRaw(enc2utf8(text)))
}

utc_timestamp <- function(time = Sys.time()) {
  format(as.POSIXct(time, tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

has_pkg <- function(pkg) {
  isTRUE(requireNamespace(pkg, quietly = TRUE))
}

#' Wrap a vector so `jsonlite::toJSON(..., auto_unbox = TRUE)` always emits a JSON array
#' @noRd
json_array <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(list())
  }
  if (is.list(x) && !is.data.frame(x)) {
    return(unname(x))
  }
  as.list(unname(x))
}

#' Convert a data.frame into a list of row lists for deterministic JSON arrays
#' @noRd
df_to_records <- function(df) {
  if (!is.data.frame(df) || nrow(df) == 0L) {
    return(list())
  }
  cols <- names(df)
  lapply(seq_len(nrow(df)), function(i) {
    rec <- lapply(cols, function(nm) {
      val <- df[[nm]][[i]]
      if (is.factor(val)) val <- as.character(val)
      if (length(val) == 1L && is.na(val)) NULL else val
    })
    stats::setNames(rec, cols)
  })
}

# --- JSON & CSV serialization helpers ----------------------------------------

to_gloss_json <- function(x, pretty = TRUE) {
  jsonlite::toJSON(
    x,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    digits = NA,
    pretty = pretty,
    POSIXt = "ISO8601",
    Date = "ISO8601"
  )
}

write_gloss_json <- function(x, path, pretty = TRUE) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  txt <- enc2utf8(as.character(to_gloss_json(x, pretty = pretty)))
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeBin(charToRaw(paste0(txt, "\n")), con)
  invisible(path)
}

#' Normalize a data frame for rectangular CSV or Parquet serialization
#' @noRd
prepare_tabular_df <- function(df, add_row_id = TRUE) {
  if (!is.data.frame(df)) {
    cli::cli_abort("{.arg df} must be a data.frame.")
  }
  out <- df
  if (isTRUE(add_row_id) && !("_row_id" %in% names(out))) {
    row_ids <- seq_len(nrow(out))
    out <- cbind(
      data.frame(`_row_id` = row_ids, check.names = FALSE, stringsAsFactors = FALSE),
      out
    )
  }
  # Coerce geometry (sfc -> WKT), list, matrix, and nested data.frame columns
  # cleanly to UTF-8 strings so CSV and Parquet stay strictly rectangular.
  for (nm in names(out)) {
    col <- out[[nm]]
    if (inherits(col, "sfc")) {
      out[[nm]] <- as.character(format(col))
    } else if (is.matrix(col)) {
      out[[nm]] <- vapply(
        seq_len(nrow(col)),
        function(i) as.character(to_gloss_json(unname(col[i, , drop = TRUE]), pretty = FALSE)),
        character(1L)
      )
    } else if (is.data.frame(col)) {
      out[[nm]] <- vapply(
        seq_len(nrow(col)),
        function(i) as.character(to_gloss_json(as.list(col[i, , drop = FALSE]), pretty = FALSE)),
        character(1L)
      )
    } else if (is.list(col)) {
      out[[nm]] <- vapply(
        col,
        function(el) {
          tryCatch(
            as.character(to_gloss_json(el, pretty = FALSE)),
            error = function(e) {
              tryCatch(
                as.character(to_gloss_json(unclass(el), pretty = FALSE)),
                error = function(e2) paste(format(el), collapse = " ")
              )
            }
          )
        },
        character(1L)
      )
    }
  }
  out
}

#' Write a data frame as standard UTF-8 CSV with an explicit 1-based `_row_id`
#' @noRd
write_gloss_csv <- function(df, path, add_row_id = TRUE) {
  out <- prepare_tabular_df(df, add_row_id = add_row_id)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(
    out,
    file = path,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
  invisible(path)
}

#' Write a data frame as standard Apache Parquet with an explicit 1-based `_row_id`
#' @noRd
write_gloss_parquet <- function(df, path, add_row_id = TRUE) {
  if (!has_pkg("nanoparquet")) {
    cli::cli_abort(
      "Package {.pkg nanoparquet} is required for {.code table_format = \"parquet\"}. Install it or use {.code table_format = \"csv\"}."
    )
  }
  out <- prepare_tabular_df(df, add_row_id = add_row_id)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  nanoparquet::write_parquet(out, file = path)
  invisible(path)
}

# --- Column typing & summaries -----------------------------------------------

gloss_column_type <- function(col) {
  if (inherits(col, "sfc")) {
    return("geometry_wkt")
  }
  if (is.factor(col)) {
    return(if (is.ordered(col)) "ordered_factor" else "factor")
  }
  if (inherits(col, "POSIXct") || inherits(col, "POSIXlt")) {
    return("datetime")
  }
  if (inherits(col, "Date")) {
    return("date")
  }
  if (is.logical(col)) {
    return("logical")
  }
  if (is.integer(col)) {
    return("integer")
  }
  if (is.double(col)) {
    return("double")
  }
  if (is.character(col)) {
    return("character")
  }
  if (is.list(col)) {
    return("list")
  }
  typeof(col)
}

STAT_COLUMN_ROLES <- c(
  ymin = "interval_low",
  ymax = "interval_high",
  xmin = "interval_x_low",
  xmax = "interval_x_high",
  lower = "quartile_low",
  ylower = "quartile_low",
  xlower = "quartile_low",
  middle = "median",
  ymiddle = "median",
  xmiddle = "median",
  upper = "quartile_high",
  yupper = "quartile_high",
  xupper = "quartile_high",
  ymin_final = "whisker_low",
  ymax_final = "whisker_high",
  xmin_final = "whisker_low",
  xmax_final = "whisker_high",
  notchlower = "notch_low",
  notchupper = "notch_high",
  outliers = "outliers",
  se = "std_error",
  count = "count",
  ncount = "scaled_count",
  density = "density",
  ndensity = "scaled_density",
  scaled = "scaled_density",
  violinwidth = "violin_width",
  level = "contour_level",
  nlevel = "scaled_contour_level"
)

infer_stat_columns <- function(df, stat_name = NA_character_, geom_name = NA_character_) {
  if (!is.data.frame(df) || ncol(df) == 0L) {
    return(NULL)
  }
  interval_geoms <- c(
    "GeomErrorbar", "GeomErrorbarh", "GeomRibbon", "GeomPointrange",
    "GeomCrossbar", "GeomLinerange", "GeomBoxplot", "GeomSmooth", "GeomViolin"
  )
  has_stat <- !is.na(stat_name) && nzchar(stat_name) && !(stat_name %in% c("StatIdentity", "identity"))
  has_interval_geom <- !is.na(geom_name) && geom_name %in% interval_geoms
  if (!has_stat && !has_interval_geom) {
    return(NULL)
  }
  hits <- intersect(names(df), names(STAT_COLUMN_ROLES))
  if (length(hits) == 0L) {
    return(NULL)
  }
  as.list(STAT_COLUMN_ROLES[hits])
}

table_column_summaries <- function(df, table_role = "raw") {
  if (!is.data.frame(df) || ncol(df) == 0L) {
    return(list())
  }
  is_built <- identical(table_role, "built")
  lapply(names(df), function(nm) {
    col <- df[[nm]]
    ctype <- gloss_column_type(col)
    entry <- list(name = nm, type = ctype)
    if (is_built && nm %in% names(STAT_COLUMN_ROLES)) {
      entry$stat_role <- unname(STAT_COLUMN_ROLES[[nm]])
    }

    if (ctype %in% c("integer", "double")) {
      finite <- col[is.finite(col)]
      if (length(finite) > 0L) {
        entry$min <- min(finite)
        entry$max <- max(finite)
      } else {
        entry$min <- NULL
        entry$max <- NULL
      }
      n_na <- sum(is.na(col))
      if (n_na > 0L) entry$n_na <- as.integer(n_na)
    } else if (ctype %in% c("character", "factor", "ordered_factor", "logical")) {
      vals <- if (is.factor(col)) as.character(col) else col
      entry$distinct <- as.integer(length(unique(vals[!is.na(vals)])))
      n_na <- sum(is.na(vals))
      if (n_na > 0L) entry$n_na <- as.integer(n_na)
    } else if (ctype %in% c("date", "datetime")) {
      non_na <- col[!is.na(col)]
      if (length(non_na) > 0L) {
        entry$min <- format(min(non_na))
        entry$max <- format(max(non_na))
      }
      n_na <- sum(is.na(col))
      if (n_na > 0L) entry$n_na <- as.integer(n_na)
    }
    entry
  })
}

table_schema_spec <- function(df, add_row_id = TRUE, table_role = "raw") {
  if (!is.data.frame(df)) {
    cli::cli_abort("{.arg df} must be a data.frame.")
  }
  is_built <- identical(table_role, "built")
  cols <- list()
  if (isTRUE(add_row_id) && !("_row_id" %in% names(df))) {
    cols <- c(cols, list(list(name = "_row_id", type = "integer", role = "row_id")))
  }
  for (nm in names(df)) {
    col <- df[[nm]]
    ctype <- gloss_column_type(col)
    spec <- list(name = nm, type = ctype)
    if (identical(nm, "_row_id")) {
      spec$role <- "row_id"
    } else if (identical(nm, "_raw_row_id")) {
      spec$role <- "raw_row_id"
    } else if (identical(nm, "_group_key")) {
      spec$role <- "group_key"
    }
    if (is_built && nm %in% names(STAT_COLUMN_ROLES)) {
      spec$stat_role <- unname(STAT_COLUMN_ROLES[[nm]])
    }
    if (inherits(col, "sfc")) {
      crs_obj <- attr(col, "crs")
      if (is.list(crs_obj) && !is.null(crs_obj$input) && nzchar(crs_obj$input[[1L]])) {
        spec$crs <- as.character(crs_obj$input)[[1L]]
      }
    }
    if (is.factor(col)) {
      spec$levels <- as.list(levels(col))
      spec$ordered <- is.ordered(col)
    }
    if (inherits(col, "POSIXct") || inherits(col, "POSIXlt")) {
      tz <- attr(col, "tzone")
      if (!is.null(tz) && nzchar(tz[[1L]])) {
        spec$timezone <- tz[[1L]]
      }
    }
    cols <- c(cols, list(spec))
  }
  cols
}

# --- gloss_capture S3 contract -----------------------------------------------

PT_PER_IN <- 72.0

round_pt <- function(x) {
  round(as.double(x), 3L)
}

empty_leaves_df <- function() {
  data.frame(
    leaf_id = character(),
    grob_name = character(),
    grob_path = character(),
    grob_class = character(),
    vp_path = character(),
    layout_slot = character(),
    bbox_x0 = double(),
    bbox_y0 = double(),
    bbox_x1 = double(),
    bbox_y1 = double(),
    xscale0 = double(),
    xscale1 = double(),
    yscale0 = double(),
    yscale1 = double(),
    n_elements = integer(),
    dense = logical(),
    clip_id = character(),
    clip_x0 = double(),
    clip_y0 = double(),
    clip_x1 = double(),
    clip_y1 = double(),
    z_index = integer(),
    semantic_role = character(),
    edit_policy = character(),
    stringsAsFactors = FALSE
  )
}

empty_elements_df <- function() {
  data.frame(
    element_id = character(),
    leaf_id = character(),
    ordinal = integer(),
    tag = character(),
    text = character(),
    bbox_x0 = double(),
    bbox_y0 = double(),
    bbox_x1 = double(),
    bbox_y1 = double(),
    fill = character(),
    stroke = character(),
    stroke_width = double(),
    opacity = double(),
    font_size = double(),
    font_family = character(),
    text_anchor = character(),
    rotation = double(),
    clip_id = character(),
    clip_x0 = double(),
    clip_y0 = double(),
    clip_x1 = double(),
    clip_y1 = double(),
    built_row_id = integer(),
    group_id = character(),
    part_role = character(),
    stringsAsFactors = FALSE
  )
}

empty_lineage_df <- function() {
  data.frame(
    leaf_id = character(),
    grob_name = character(),
    layout_slot = character(),
    panel_id = character(),
    layer_id = integer(),
    table_id = character(),
    cardinality = character(),
    n_rows = integer(),
    n_elements = integer(),
    semantic_role = character(),
    edit_policy = character(),
    lineage_tier = character(),
    degradation_reason = character(),
    stringsAsFactors = FALSE
  )
}

make_scene_coord <- function(width_pt, height_pt, viewbox = NULL) {
  vb <- if (!is.null(viewbox) && length(viewbox) == 4L && all(is.finite(viewbox))) {
    round_pt(viewbox)
  } else {
    c(0.0, 0.0, round_pt(width_pt), round_pt(height_pt))
  }
  list(
    unit = "pt",
    origin = "top-left",
    y_direction = "down",
    viewBox = json_array(vb)
  )
}

ensure_df_columns <- function(df, template_df) {
  if (!is.data.frame(df)) return(df)
  n <- nrow(df)
  for (col in names(template_df)) {
    if (!(col %in% names(df))) {
      proto <- template_df[[col]]
      if (is.integer(proto)) {
        df[[col]] <- rep(NA_integer_, n)
      } else if (is.double(proto)) {
        df[[col]] <- rep(NA_real_, n)
      } else if (is.logical(proto)) {
        df[[col]] <- rep(NA, n)
      } else {
        df[[col]] <- rep(NA_character_, n)
      }
    }
  }
  df
}

normalize_svg_slot <- function(svg_text) {
  if (is.null(svg_text)) {
    return(list(text = "", bytes = 0L, sha256 = sha256_text("")))
  }
  if (is.list(svg_text) && all(c("text", "bytes", "sha256") %in% names(svg_text))) {
    return(svg_text)
  }
  txt <- enc2utf8(as.character(svg_text)[[1L]])
  list(
    text = txt,
    bytes = utf8_nbytes(txt),
    sha256 = sha256_text(txt)
  )
}

normalize_table_entry <- function(entry, table_id) {
  if (is.data.frame(entry)) {
    return(list(
      table_id = table_id,
      role = "raw",
      key = character(),
      layer_id = NULL,
      data = entry
    ))
  }
  if (!is.list(entry) || !is.data.frame(entry$data)) {
    cli::cli_abort(
      "Table entry {.val {table_id}} must be a data.frame or a list with a {.field data} data.frame."
    )
  }
  list(
    table_id = entry$table_id %||% table_id,
    role = entry$role %||% "raw",
    key = as.character(entry$key %||% character()),
    layer_id = entry$layer_id %||% NULL,
    data = entry$data
  )
}

compute_capture_id <- function(page, svg_original, svg_scene, rasters = list()) {
  raster_sig <- if (length(rasters) > 0L) {
    rnames <- sort(names(rasters))
    paste(
      vapply(rnames, function(nm) paste0(nm, ":", sha256_raw(rasters[[nm]])), character(1L)),
      collapse = ","
    )
  } else {
    ""
  }
  payload <- paste(
    GLOSS_SCHEMA_VERSION,
    page$engine %||% "",
    page$width_pt %||% "",
    page$height_pt %||% "",
    svg_original$sha256 %||% "",
    svg_scene$sha256 %||% "",
    raster_sig,
    sep = "|"
  )
  prefixed_sha256(sha256_text(payload))
}

#' Construct a canonical in-memory `gloss_capture` object
#'
#' Both `gl_asset_map()` and `gl_asset_bundle()` serialize directly from this
#' object so figures are never redrawn during asset packaging.
#' @noRd
new_gloss_capture <- function(
    page,
    svg_original,
    svg_scene,
    leaves = empty_leaves_df(),
    elements = empty_elements_df(),
    dense_leaves = character(),
    rasters = list(),
    ir = list(),
    tables = list(),
    lineage = empty_lineage_df(),
    sources = list(),
    session = list(),
    preview_png = NULL,
    label_links = list(),
    parent_capture_id = NULL,
    capture_id = NULL,
    created_at = utc_timestamp(),
    schema_version = GLOSS_SCHEMA_VERSION) {

  orig <- normalize_svg_slot(svg_original)
  scn <- normalize_svg_slot(svg_scene)

  w_pt <- as.double(page$width_pt %||% ((page$width_in %||% 7.0) * 72.0))[[1L]]
  h_pt <- as.double(page$height_pt %||% ((page$height_in %||% 5.0) * 72.0))[[1L]]
  n_pages <- as.integer(page$pages %||% 1L)[[1L]]
  sel_page <- as.integer(page$selected_page %||% n_pages)[[1L]]

  norm_page <- list(
    engine = as.character(page$engine %||% "unknown")[[1L]],
    engine_version = as.character(page$engine_version %||% NA_character_)[[1L]],
    draw_method = as.character(page$draw_method %||% "unknown")[[1L]],
    device = as.character(page$device %||% "svglite")[[1L]],
    width_in = as.double(page$width_in %||% 7.0)[[1L]],
    height_in = as.double(page$height_in %||% 5.0)[[1L]],
    width_pt = w_pt,
    height_pt = h_pt,
    pages = n_pages,
    selected_page = sel_page
  )
  if (!is.null(page$preview_dpi) && is.finite(page$preview_dpi)) {
    norm_page$preview_dpi <- as.integer(page$preview_dpi)[[1L]]
  }
  if (!is.null(page$degraded) && nzchar(as.character(page$degraded)[[1L]])) {
    norm_page$degraded <- as.character(page$degraded)[[1L]]
  }

  norm_ir <- list(
    panels = ir$panels %||% list(),
    layers = ir$layers %||% list(),
    scales = ir$scales %||% list(),
    orders = ir$orders %||% stats::setNames(list(), character())
  )
  if (!is.null(ir$guides)) {
    norm_ir$guides <- ir$guides
  }
  if (!is.null(ir$group_indices) && length(ir$group_indices) > 0L) {
    norm_ir$group_indices <- ir$group_indices
  }

  if (is.data.frame(leaves)) {
    leaves <- ensure_df_columns(leaves, empty_leaves_df())
    if (nrow(leaves) > 0L && all(is.na(leaves$z_index))) {
      leaves$z_index <- seq_len(nrow(leaves))
    }
  }
  if (is.data.frame(elements)) {
    elements <- ensure_df_columns(elements, empty_elements_df())
  }
  if (is.data.frame(lineage)) {
    lineage <- ensure_df_columns(lineage, empty_lineage_df())
  }

  norm_tables <- stats::setNames(list(), character())
  if (length(tables) > 0L) {
    tbl_names <- names(tables)
    if (is.null(tbl_names) || any(!nzchar(tbl_names))) {
      cli::cli_abort("All entries in {.arg tables} must be named.")
    }
    for (nm in tbl_names) {
      norm_tables[[nm]] <- normalize_table_entry(tables[[nm]], nm)
    }
  }

  cap_id <- capture_id %||% compute_capture_id(norm_page, orig, scn, rasters = rasters)
  norm_parent <- if (is.null(parent_capture_id) || is.na(parent_capture_id) || !nzchar(parent_capture_id)) {
    NULL
  } else {
    as.character(parent_capture_id)[[1L]]
  }

  cap <- structure(
    list(
      schema_version = as.character(schema_version)[[1L]],
      capture_id = as.character(cap_id)[[1L]],
      parent_capture_id = norm_parent,
      created_at = as.character(created_at)[[1L]],
      page = norm_page,
      svg = list(
        original = orig,
        scene = scn
      ),
      scene = list(
        coord = make_scene_coord(w_pt, h_pt),
        leaves = leaves,
        elements = elements,
        dense_leaves = as.character(dense_leaves),
        rasters = rasters,
        preview_png = preview_png,
        label_links = label_links %||% list()
      ),
      ir = norm_ir,
      tables = norm_tables,
      lineage = lineage,
      sources = sources,
      session = session
    ),
    class = "gloss_capture"
  )

  validate_gloss_capture(cap)
}

is_gloss_capture <- function(x) {
  inherits(x, "gloss_capture")
}

validate_gloss_capture <- function(cap) {
  if (!is_gloss_capture(cap)) {
    cli::cli_abort("{.arg cap} must be a {.cls gloss_capture} object.")
  }
  required_top <- c(
    "schema_version", "capture_id", "created_at", "page",
    "svg", "scene", "ir", "tables", "lineage", "sources", "session"
  )
  missing_top <- setdiff(required_top, names(cap))
  if (length(missing_top) > 0L) {
    cli::cli_abort(
      "{.cls gloss_capture} is missing required field(s): {.field {missing_top}}."
    )
  }
  if (!is.data.frame(cap$scene$leaves)) {
    cli::cli_abort("{.field scene$leaves} must be a data.frame.")
  }
  if (!is.data.frame(cap$scene$elements)) {
    cli::cli_abort("{.field scene$elements} must be a data.frame.")
  }
  if (!is.data.frame(cap$lineage)) {
    cli::cli_abort("{.field lineage} must be a data.frame.")
  }
  cap
}

#' @export
print.gloss_capture <- function(x, ...) {
  n_panels <- length(x$ir$panels)
  n_leaves <- nrow(x$scene$leaves)
  n_elements <- nrow(x$scene$elements)
  n_tables <- length(x$tables)
  n_sources <- length(x$sources)

  cat(sprintf("<gloss_capture %s>\n", x$capture_id))
  cat(sprintf(
    "  engine : %s (%s) | %.2f x %.2f in (%.1f x %.1f pt)\n",
    x$page$engine,
    x$page$draw_method,
    x$page$width_in,
    x$page$height_in,
    x$page$width_pt,
    x$page$height_pt
  ))
  cat(sprintf(
    "  scene  : %d panel(s), %d leaf/leaves, %d element(s)\n",
    n_panels, n_leaves, n_elements
  ))
  cat(sprintf(
    "  assets : %d table(s), %d source(s), %d scale(s)\n",
    n_tables, n_sources, length(x$ir$scales)
  ))
  invisible(x)
}
