# Engine-agnostic Engine IR builders, panel coordinate transforms, semantic
# role/edit-policy classifiers, and neutral structural lineage helpers.
#
# Shared across ggplot2, patchwork, ComplexHeatmap, base, and third-party
# engines so all engines emit a uniform Schema v1.1 IR for Asset Map & Bundle.

# --- Axis transformation math ------------------------------------------------

normalize_trans_name <- function(tr_name) {
  if (is.null(tr_name) || length(tr_name) == 0L || is.na(tr_name)) {
    return("identity")
  }
  nm <- trimws(as.character(tr_name)[[1L]])
  if (!nzchar(nm)) return("identity")
  low <- tolower(nm)
  if (low %in% c("identity", "linear")) return("identity")
  if (low %in% c("log-10", "log10")) return("log-10")
  if (low %in% c("log-2", "log2")) return("log-2")
  if (low %in% c("log", "ln", "log-e")) return("ln")
  if (low %in% c("sqrt", "square-root")) return("sqrt")
  if (low %in% c("reverse", "rev")) return("reverse")
  if (low %in% c("date")) return("date")
  if (low %in% c("time", "datetime", "posixct")) return("time")
  if (low %in% c("discrete")) return("discrete")
  nm
}

invert_axis_trans <- function(vals, trans = "identity") {
  if (is.null(vals) || length(vals) == 0L) return(NULL)
  v <- as.numeric(vals)
  tr <- normalize_trans_name(trans)
  out <- switch(
    tr,
    "identity" = v,
    "discrete" = v,
    "log-10" = 10^v,
    "log-2" = 2^v,
    "ln" = exp(v),
    "sqrt" = v^2,
    "reverse" = -v,
    "date" = v,
    "time" = v,
    v
  )
  if (length(out) == 2L && all(is.finite(out)) && out[[1L]] > out[[2L]]) {
    out <- rev(out)
  }
  out
}

apply_axis_trans <- function(vals, trans = "identity") {
  if (is.null(vals) || length(vals) == 0L) return(NULL)
  v <- as.numeric(vals)
  tr <- normalize_trans_name(trans)
  switch(
    tr,
    "identity" = v,
    "discrete" = v,
    "log-10" = suppressWarnings(log10(v)),
    "log-2" = suppressWarnings(log2(v)),
    "ln" = suppressWarnings(log(v)),
    "sqrt" = suppressWarnings(sqrt(v)),
    "reverse" = -v,
    "date" = v,
    "time" = v,
    v
  )
}

# Project rendered (post-transform) panel coordinates (x_ren, y_ren) into SVG
# top-left point coordinates (px, py). When `panel$flipped` is TRUE, `x_ren`
# is the data x-aesthetic (mapped vertically along `y_domain`) and `y_ren` is
# the data y-aesthetic (mapped horizontally along `x_domain`).
panel_rendered_to_px <- function(panel, x_ren, y_ren) {
  bb <- unlist(panel$bbox_pt)
  xd <- unlist(panel$x_domain)
  yd <- unlist(panel$y_domain)
  if (length(bb) != 4L || length(xd) != 2L || length(yd) != 2L ||
      any(!is.finite(bb)) || any(!is.finite(xd)) || any(!is.finite(yd)) ||
      xd[[2L]] == xd[[1L]] || yd[[2L]] == yd[[1L]]) {
    return(list(px = rep(NA_real_, length(x_ren)), py = rep(NA_real_, length(y_ren))))
  }
  flipped <- isTRUE(panel$flipped)
  vx <- if (flipped) as.numeric(y_ren) else as.numeric(x_ren)
  vy <- if (flipped) as.numeric(x_ren) else as.numeric(y_ren)

  px <- bb[[1L]] + (vx - xd[[1L]]) / (xd[[2L]] - xd[[1L]]) * (bb[[3L]] - bb[[1L]])
  py <- bb[[4L]] - (vy - yd[[1L]]) / (yd[[2L]] - yd[[1L]]) * (bb[[4L]] - bb[[2L]])
  list(px = px, py = py)
}

# Inverse-project SVG top-left point coordinates (px, py) into rendered
# (post-transform) panel data coordinates (x_ren, y_ren), respecting `flipped`.
panel_px_to_rendered <- function(panel, px, py) {
  bb <- unlist(panel$bbox_pt)
  xd <- unlist(panel$x_domain)
  yd <- unlist(panel$y_domain)
  if (length(bb) != 4L || length(xd) != 2L || length(yd) != 2L ||
      any(!is.finite(bb)) || any(!is.finite(xd)) || any(!is.finite(yd)) ||
      bb[[3L]] == bb[[1L]] || bb[[4L]] == bb[[2L]]) {
    return(list(x = rep(NA_real_, length(px)), y = rep(NA_real_, length(py))))
  }
  vx <- xd[[1L]] + (as.numeric(px) - bb[[1L]]) / (bb[[3L]] - bb[[1L]]) * (xd[[2L]] - xd[[1L]])
  vy <- yd[[1L]] + (bb[[4L]] - as.numeric(py)) / (bb[[4L]] - bb[[2L]]) * (yd[[2L]] - yd[[1L]])

  if (isTRUE(panel$flipped)) {
    list(x = vy, y = vx)
  } else {
    list(x = vx, y = vy)
  }
}

# --- Engine IR constructors --------------------------------------------------

make_panel_ir <- function(
    panel_id,
    facet_vars = list(),
    bbox_pt = NULL,
    x_domain = NULL,
    y_domain = NULL,
    coord = "CoordCartesian",
    flipped = FALSE,
    row = NULL,
    col = NULL,
    x_trans = NULL,
    y_trans = NULL,
    x_data_domain = NULL,
    y_data_domain = NULL,
    domain_space = "transformed",
    expansion_included = TRUE,
    x_breaks_pos = NULL,
    y_breaks_pos = NULL,
    x_axis_group = NULL,
    y_axis_group = NULL,
    row_axis_group = NULL,
    col_axis_group = NULL,
    row_order_ref = NULL,
    col_order_ref = NULL,
    row_slice_range = NULL,
    col_slice_range = NULL,
    panel_role = NULL) {

  if (length(facet_vars) == 0L) {
    facet_vars <- stats::setNames(list(), character())
  }

  xd_num <- if (is.null(x_domain)) NULL else as.numeric(x_domain)
  yd_num <- if (is.null(y_domain)) NULL else as.numeric(y_domain)
  xtr <- if (!is.null(x_trans) && !is.na(x_trans) && nzchar(x_trans)) normalize_trans_name(x_trans) else NULL
  ytr <- if (!is.null(y_trans) && !is.na(y_trans) && nzchar(y_trans)) normalize_trans_name(y_trans) else NULL

  x_data_dom <- if (!is.null(x_data_domain)) {
    as.numeric(x_data_domain)
  } else if (!is.null(xd_num) && identical(domain_space, "transformed")) {
    invert_axis_trans(xd_num, if (isTRUE(flipped)) ytr %||% "identity" else xtr %||% "identity")
  } else {
    xd_num
  }
  y_data_dom <- if (!is.null(y_data_domain)) {
    as.numeric(y_data_domain)
  } else if (!is.null(yd_num) && identical(domain_space, "transformed")) {
    invert_axis_trans(yd_num, if (isTRUE(flipped)) xtr %||% "identity" else ytr %||% "identity")
  } else {
    yd_num
  }

  out <- list(
    panel_id = as.character(panel_id)[[1L]],
    facet_vars = facet_vars,
    bbox_pt = if (is.null(bbox_pt) || any(!is.finite(bbox_pt))) NULL else json_array(round_pt(bbox_pt)),
    x_domain = if (is.null(xd_num)) NULL else json_array(xd_num),
    y_domain = if (is.null(yd_num)) NULL else json_array(yd_num),
    domain_space = as.character(domain_space)[[1L]],
    expansion_included = isTRUE(expansion_included),
    coord = as.character(coord)[[1L]],
    flipped = isTRUE(flipped)
  )

  if (!is.null(x_data_dom) && all(is.finite(x_data_dom))) {
    out$x_data_domain <- json_array(x_data_dom)
  }
  if (!is.null(y_data_dom) && all(is.finite(y_data_dom))) {
    out$y_data_domain <- json_array(y_data_dom)
  }
  if (!is.null(row) && !is.na(row)) out$row <- as.integer(row)
  if (!is.null(col) && !is.na(col)) out$col <- as.integer(col)
  if (!is.null(xtr)) out$x_trans <- xtr
  if (!is.null(ytr)) out$y_trans <- ytr
  if (!is.null(x_breaks_pos) && length(x_breaks_pos) > 0L) out$x_breaks_pos <- json_array(x_breaks_pos)
  if (!is.null(y_breaks_pos) && length(y_breaks_pos) > 0L) out$y_breaks_pos <- json_array(y_breaks_pos)
  if (!is.null(x_axis_group) && nzchar(x_axis_group)) out$x_axis_group <- as.character(x_axis_group)[[1L]]
  if (!is.null(y_axis_group) && nzchar(y_axis_group)) out$y_axis_group <- as.character(y_axis_group)[[1L]]
  if (!is.null(row_axis_group) && nzchar(row_axis_group)) out$row_axis_group <- as.character(row_axis_group)[[1L]]
  if (!is.null(col_axis_group) && nzchar(col_axis_group)) out$col_axis_group <- as.character(col_axis_group)[[1L]]
  if (!is.null(row_order_ref) && nzchar(row_order_ref)) out$row_order_ref <- as.character(row_order_ref)[[1L]]
  if (!is.null(col_order_ref) && nzchar(col_order_ref)) out$col_order_ref <- as.character(col_order_ref)[[1L]]
  if (!is.null(row_slice_range) && length(row_slice_range) == 2L) out$row_slice_range <- json_array(as.integer(row_slice_range))
  if (!is.null(col_slice_range) && length(col_slice_range) == 2L) out$col_slice_range <- json_array(as.integer(col_slice_range))
  if (!is.null(panel_role) && nzchar(panel_role)) out$panel_role <- as.character(panel_role)[[1L]]

  out
}

make_layer_ir <- function(
    layer_id,
    geom,
    stat = "StatIdentity",
    position = "PositionIdentity",
    aes = list(),
    raw_table = NULL,
    built_table = NULL,
    params = NULL,
    stat_columns = NULL,
    row_accounting = NULL,
    group_index_ref = NULL) {

  if (length(aes) == 0L) {
    aes <- stats::setNames(list(), character())
  }

  out <- list(
    layer_id = as.integer(layer_id)[[1L]],
    geom = as.character(geom)[[1L]],
    stat = as.character(stat)[[1L]],
    position = as.character(position)[[1L]],
    aes = aes,
    raw_table = if (is.null(raw_table) || is.na(raw_table)) NULL else as.character(raw_table)[[1L]],
    built_table = if (is.null(built_table) || is.na(built_table)) NULL else as.character(built_table)[[1L]]
  )

  if (!is.null(stat_columns) && length(stat_columns) > 0L) {
    out$stat_columns <- stat_columns
  }
  if (!is.null(params) && length(params) > 0L) {
    out$params <- params
  }
  if (!is.null(row_accounting) && length(row_accounting) > 0L) {
    out$row_accounting <- row_accounting
  }
  if (!is.null(group_index_ref) && nzchar(group_index_ref)) {
    out$group_index_ref <- as.character(group_index_ref)[[1L]]
  }

  out
}

make_scale_ir <- function(
    aesthetic,
    field = NULL,
    scale_type = c("discrete", "continuous", "binned", "identity", "unknown"),
    map = list(),
    domain = NULL,
    breaks = NULL,
    labels = NULL,
    trans = NULL,
    name = NULL,
    panel_ids = NULL,
    limits = NULL,
    stops = NULL,
    na_value = NULL,
    oob = NULL,
    midpoint = NULL) {

  scale_type <- match.arg(scale_type)

  out <- list(
    aesthetic = as.character(aesthetic)[[1L]],
    field = if (is.null(field) || is.na(field) || !nzchar(field)) NULL else as.character(field)[[1L]],
    scale_type = scale_type
  )

  if (!is.null(panel_ids) && length(panel_ids) > 0L) {
    out$panel_ids <- json_array(as.character(panel_ids))
  }
  if (!is.null(name) && !is.na(name) && nzchar(name)) {
    out$name <- as.character(name)[[1L]]
  }
  if (!is.null(trans) && !is.na(trans) && nzchar(trans)) {
    out$trans <- normalize_trans_name(trans)
  }
  if (!is.null(domain) && length(domain) > 0L) {
    out$domain <- json_array(domain)
  }
  if (!is.null(limits) && length(limits) > 0L) {
    out$limits <- json_array(limits)
  }
  if (!is.null(breaks) && length(breaks) > 0L) {
    out$breaks <- json_array(breaks)
  }
  if (!is.null(labels) && length(labels) > 0L) {
    out$labels <- json_array(as.character(labels))
  }
  if (length(map) > 0L) {
    out$map <- json_array(map)
  } else {
    out$map <- list()
  }
  if (!is.null(stops) && length(stops) > 0L) {
    out$stops <- json_array(stops)
  }
  if (!is.null(na_value) && length(na_value) == 1L && !is.na(na_value)) {
    out$na_value <- as.character(na_value)[[1L]]
  }
  if (!is.null(oob) && length(oob) == 1L && !is.na(oob) && nzchar(oob)) {
    out$oob <- as.character(oob)[[1L]]
  }
  if (!is.null(midpoint) && length(midpoint) == 1L && is.finite(midpoint)) {
    out$midpoint <- as.numeric(midpoint)[[1L]]
  }

  out
}

# --- Semantic roles, edit policies, cardinality, and lineage tier ------------

LABEL_GEOMS <- c(
  "GeomText", "GeomLabel", "GeomTextRepel", "GeomLabelRepel",
  "GeomTextSf", "GeomLabelSf", "GeomRichText", "BaseText"
)

REFERENCE_GEOMS <- c(
  "GeomHline", "GeomVline", "GeomAbline", "BaseAbline"
)

CHROME_ROLES <- c(
  "panel_grid", "panel_frame", "axis_tick", "axis_line", "axis_title",
  "strip_label", "guide_key", "guide_label", "guide_frame",
  "plot_title", "plot_caption", "background"
)

classify_single_leaf_semantics <- function(
    grob_name = "",
    grob_class = "",
    layout_slot = "",
    grob_path = "",
    geom = NA_character_,
    layer_id = NA_integer_,
    has_text = FALSE,
    only_lines = FALSE) {

  gn <- as.character(grob_name %||% "")[[1L]]
  gc <- as.character(grob_class %||% "")[[1L]]
  sl <- as.character(layout_slot %||% "")[[1L]]
  gp <- as.character(grob_path %||% "")[[1L]]
  gm <- if (is.null(geom) || is.na(geom)) "" else as.character(geom)[[1L]]

  # 1. Data-linked layer leaves
  if (!is.na(layer_id)) {
    if (gm %in% LABEL_GEOMS || identical(gc, "text") && !nzchar(gm)) {
      if (grepl("repel", paste(gm, gn, gp), ignore.case = TRUE) &&
          (gc %in% c("segments", "lines", "polyline", "curve") || isTRUE(only_lines))) {
        return(list(semantic_role = "leader_line", edit_policy = "movable"))
      }
      return(list(semantic_role = "data_label", edit_policy = "movable"))
    }
    if (gm %in% REFERENCE_GEOMS) {
      return(list(semantic_role = "reference_mark", edit_policy = "geometry_locked"))
    }
    return(list(semantic_role = "data_mark", edit_policy = "geometry_locked"))
  }

  # 2. Guides / legends
  if (grepl("^guide-box|^legend", sl) || grepl("guide-box|legend\\.box", gp)) {
    if (grepl("label", gn, ignore.case = TRUE) || identical(gc, "text") || isTRUE(has_text)) {
      return(list(semantic_role = "guide_label", edit_policy = "movable"))
    }
    if (grepl("background|frame|border", gn, ignore.case = TRUE)) {
      return(list(semantic_role = "guide_frame", edit_policy = "style_only"))
    }
    return(list(semantic_role = "guide_key", edit_policy = "style_only"))
  }

  # 3. Plot titles, subtitles, captions, tags
  if (sl %in% c("title", "subtitle") || grepl("plot\\.title|plot\\.subtitle", gn)) {
    return(list(semantic_role = "plot_title", edit_policy = "movable"))
  }
  if (sl %in% c("caption", "tag") || grepl("plot\\.caption|plot\\.tag", gn)) {
    return(list(semantic_role = "plot_caption", edit_policy = "movable"))
  }

  # 4. Axis titles & ticks / lines
  if (grepl("^[xy]lab", sl) || grepl("axis\\.title", gn) || identical(gn, "title")) {
    return(list(semantic_role = "axis_title", edit_policy = "movable"))
  }
  if (grepl("^axis", sl) || identical(gn, "axis")) {
    if (identical(gc, "text") || isTRUE(has_text)) {
      return(list(semantic_role = "axis_tick", edit_policy = "geometry_locked"))
    }
    return(list(semantic_role = "axis_line", edit_policy = "style_only"))
  }

  # 5. Facet strips
  if (grepl("^strip", sl)) {
    if (identical(gc, "text") || isTRUE(has_text)) {
      return(list(semantic_role = "strip_label", edit_policy = "movable"))
    }
    return(list(semantic_role = "background", edit_policy = "style_only"))
  }

  # 6. Panel chrome (gridlines, frame, background)
  if (grepl("panel\\.grid|grill\\.", gn) || grepl("grill\\.", gp)) {
    if (grepl("panel\\.background", gn)) {
      return(list(semantic_role = "panel_frame", edit_policy = "style_only"))
    }
    return(list(semantic_role = "panel_grid", edit_policy = "style_only"))
  }
  if (grepl("panel\\.border|panel\\.background", gn) || identical(gn, "box")) {
    return(list(semantic_role = "panel_frame", edit_policy = "style_only"))
  }
  if (identical(sl, "background") || grepl("plot\\.background|layout\\.background", gn)) {
    return(list(semantic_role = "background", edit_policy = "style_only"))
  }

  # 7. Unlinked annotations (text / mtext inside figure or panel)
  if (identical(gc, "text") || gn %in% c("text", "mtext") || isTRUE(has_text)) {
    return(list(semantic_role = "annotation", edit_policy = "movable"))
  }

  list(semantic_role = "other", edit_policy = "style_only")
}

#' Neutrally classify row-to-element cardinality for a linked leaf
#'
#' Records structural correspondence as a factual property without acting as a
#' verification gate.
#' @noRd
infer_lineage_cardinality <- function(
    geom = NA_character_,
    stat = NA_character_,
    n_rows = NA_integer_,
    n_elements = NA_integer_,
    dynamic_draw = FALSE) {

  if (!is.na(stat) && nzchar(stat) && !(stat %in% c("StatIdentity", "identity"))) {
    return("stat_aggregated")
  }
  if (is.na(n_rows) || is.na(n_elements)) {
    return("unknown")
  }
  if (n_rows == 0L || n_elements == 0L) {
    return("empty")
  }

  n_to_1_geoms <- c(
    "GeomLine", "GeomPath", "GeomArea", "GeomRibbon", "GeomPolygon",
    "GeomStep", "GeomDensity", "GeomSmooth", "GeomFreqpoly",
    "GeomContour", "GeomContourFilled", "GeomSf"
  )
  one_to_m_geoms <- c(
    "GeomBoxplot", "GeomPointrange", "GeomCrossbar", "GeomErrorbar",
    "GeomErrorbarh", "GeomLinerange", "GeomViolin"
  )

  if (isTRUE(dynamic_draw)) {
    if (n_elements > n_rows) return("1:M")
    if (n_elements < n_rows) return("N:1")
    return("1:M")
  }

  if (n_elements == n_rows) {
    return("1:1")
  }
  if (!is.na(geom) && geom %in% n_to_1_geoms && n_elements < n_rows) {
    return("N:1")
  }
  if (!is.na(geom) && geom %in% one_to_m_geoms && n_elements > n_rows) {
    return("1:M")
  }
  if (n_elements < n_rows) {
    return("N:1")
  }
  if (n_elements > n_rows) {
    return("1:M")
  }
  "unknown"
}

infer_lineage_tier <- function(
    cardinality,
    layer_id = NA_integer_,
    panel_id = NA_character_,
    semantic_role = "other",
    n_elements = 0L,
    n_matched_rows = 0L,
    n_matched_groups = 0L,
    dense = FALSE,
    dynamic_draw = FALSE) {

  if (is.na(layer_id)) {
    if (semantic_role %in% CHROME_ROLES) return("chrome")
    if (!is.na(panel_id) && nzchar(panel_id)) return("panel_coord_only")
    return("scene_only")
  }

  if (isTRUE(dense)) return("layer_linked")
  if (n_elements > 0L && n_matched_rows == n_elements && !isTRUE(dynamic_draw)) {
    return("row_exact")
  }
  if (n_elements > 0L && n_matched_rows > 0L && identical(semantic_role, "data_label")) {
    return("row_exact")
  }
  if (n_matched_rows > 0L || n_matched_groups > 0L) {
    return("group_linked")
  }
  "layer_linked"
}

make_lineage_df <- function(
    leaves,
    panel_id = NULL,
    layer_id = NULL,
    table_id = NULL,
    cardinality = NULL,
    n_rows = NULL,
    semantic_role = NULL,
    edit_policy = NULL,
    lineage_tier = NULL,
    degradation_reason = NULL) {

  n <- nrow(leaves)
  if (n == 0L) {
    return(empty_lineage_df())
  }

  data.frame(
    leaf_id = as.character(leaves$leaf_id),
    grob_name = as.character(leaves$grob_name),
    layout_slot = as.character(leaves$layout_slot),
    panel_id = if (is.null(panel_id)) rep(NA_character_, n) else as.character(panel_id),
    layer_id = if (is.null(layer_id)) rep(NA_integer_, n) else as.integer(layer_id),
    table_id = if (is.null(table_id)) rep(NA_character_, n) else as.character(table_id),
    cardinality = if (is.null(cardinality)) rep("unlinked", n) else as.character(cardinality),
    n_rows = if (is.null(n_rows)) rep(NA_integer_, n) else as.integer(n_rows),
    n_elements = as.integer(leaves$n_elements),
    semantic_role = if (is.null(semantic_role)) rep(NA_character_, n) else as.character(semantic_role),
    edit_policy = if (is.null(edit_policy)) rep(NA_character_, n) else as.character(edit_policy),
    lineage_tier = if (is.null(lineage_tier)) rep(NA_character_, n) else as.character(lineage_tier),
    degradation_reason = if (is.null(degradation_reason)) rep(NA_character_, n) else as.character(degradation_reason),
    stringsAsFactors = FALSE
  )
}

# Populate `z_index`, `semantic_role`, `edit_policy`, `lineage_tier`, and
# `degradation_reason` across both `leaves` and `lineage` consistently once an
# engine finishes extracting IR, elements, and lineage.
finalize_scene_semantics <- function(leaves, elements, lineage, layers = list(), draw_method = NULL) {
  n <- nrow(leaves)
  if (n == 0L) {
    return(list(leaves = leaves, lineage = lineage))
  }

  leaves <- ensure_df_columns(leaves, empty_leaves_df())
  lineage <- ensure_df_columns(lineage, empty_lineage_df())
  elements <- ensure_df_columns(elements, empty_elements_df())

  if (all(is.na(leaves$z_index))) {
    leaves$z_index <- seq_len(n)
  }

  layer_geom_map <- stats::setNames(character(), character())
  for (lyr in layers) {
    if (!is.null(lyr$layer_id) && !is.null(lyr$geom)) {
      layer_geom_map[[as.character(lyr$layer_id)]] <- as.character(lyr$geom)[[1L]]
    }
  }

  # Precompute per-leaf element stats
  el_by_leaf <- if (nrow(elements) > 0L) {
    split(seq_len(nrow(elements)), elements$leaf_id)
  } else {
    list()
  }

  lin_idx <- match(leaves$leaf_id, lineage$leaf_id)

  for (r in seq_len(n)) {
    lid <- leaves$leaf_id[[r]]
    li_pos <- lin_idx[[r]]
    layer_id <- if (!is.na(li_pos)) lineage$layer_id[[li_pos]] else NA_integer_
    panel_id <- if (!is.na(li_pos)) lineage$panel_id[[li_pos]] else NA_character_
    card <- if (!is.na(li_pos)) lineage$cardinality[[li_pos]] else "unlinked"
    geom_nm <- if (!is.na(layer_id) && as.character(layer_id) %in% names(layer_geom_map)) {
      layer_geom_map[[as.character(layer_id)]]
    } else {
      NA_character_
    }

    e_idx <- el_by_leaf[[lid]] %||% integer()
    tags <- if (length(e_idx) > 0L) elements$tag[e_idx] else character()
    has_text <- any(tags == "text")
    only_lines <- length(tags) > 0L && all(tags %in% c("line", "polyline", "path"))

    sem <- classify_single_leaf_semantics(
      grob_name = leaves$grob_name[[r]],
      grob_class = leaves$grob_class[[r]],
      layout_slot = leaves$layout_slot[[r]],
      grob_path = leaves$grob_path[[r]],
      geom = geom_nm,
      layer_id = layer_id,
      has_text = has_text,
      only_lines = only_lines
    )

    if (is.na(leaves$semantic_role[[r]]) || !nzchar(leaves$semantic_role[[r]])) {
      leaves$semantic_role[[r]] <- sem$semantic_role
    }
    if (is.na(leaves$edit_policy[[r]]) || !nzchar(leaves$edit_policy[[r]])) {
      leaves$edit_policy[[r]] <- sem$edit_policy
    }

    if (!is.na(li_pos)) {
      if (is.na(lineage$semantic_role[[li_pos]]) || !nzchar(lineage$semantic_role[[li_pos]])) {
        lineage$semantic_role[[li_pos]] <- leaves$semantic_role[[r]]
      }
      if (is.na(lineage$edit_policy[[li_pos]]) || !nzchar(lineage$edit_policy[[li_pos]])) {
        lineage$edit_policy[[li_pos]] <- leaves$edit_policy[[r]]
      }

      n_matched_rows <- if (length(e_idx) > 0L) sum(!is.na(elements$built_row_id[e_idx])) else 0L
      n_matched_groups <- if (length(e_idx) > 0L) sum(!is.na(elements$group_id[e_idx])) else 0L
      is_dense <- isTRUE(leaves$dense[[r]])
      deg_reason <- lineage$degradation_reason[[li_pos]]
      is_dyn <- !is.na(deg_reason) && grepl("dynamic_makeContent", deg_reason, fixed = TRUE)

      if (is_dense && (is.na(deg_reason) || !nzchar(deg_reason))) {
        deg_reason <- "rasterized_dense_leaf"
      } else if (is.na(layer_id) && !(leaves$semantic_role[[r]] %in% CHROME_ROLES) &&
                 !is.na(panel_id) && !is.null(draw_method) && startsWith(draw_method, "print.") &&
                 (is.na(deg_reason) || !nzchar(deg_reason))) {
        deg_reason <- paste0("custom_print:", draw_method)
      }
      lineage$degradation_reason[[li_pos]] <- deg_reason

      if (is.na(lineage$lineage_tier[[li_pos]]) || !nzchar(lineage$lineage_tier[[li_pos]])) {
        lineage$lineage_tier[[li_pos]] <- infer_lineage_tier(
          cardinality = card,
          layer_id = layer_id,
          panel_id = panel_id,
          semantic_role = leaves$semantic_role[[r]],
          n_elements = leaves$n_elements[[r]],
          n_matched_rows = n_matched_rows,
          n_matched_groups = n_matched_groups,
          dense = is_dense,
          dynamic_draw = is_dyn
        )
      }
    }
  }

  list(leaves = leaves, lineage = lineage)
}
