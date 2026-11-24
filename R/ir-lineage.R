# Engine-agnostic Engine IR builders and neutral structural lineage helpers.
#
# Shared across ggplot2, patchwork, ComplexHeatmap, base, and third-party
# engines so all engines emit a uniform IR schema for Asset Map & Asset Bundle.

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
    y_trans = NULL) {

  if (length(facet_vars) == 0L) {
    facet_vars <- stats::setNames(list(), character())
  }

  out <- list(
    panel_id = as.character(panel_id)[[1L]],
    facet_vars = facet_vars,
    bbox_pt = if (is.null(bbox_pt) || any(!is.finite(bbox_pt))) NULL else json_array(round_pt(bbox_pt)),
    x_domain = if (is.null(x_domain)) NULL else json_array(as.numeric(x_domain)),
    y_domain = if (is.null(y_domain)) NULL else json_array(as.numeric(y_domain)),
    coord = as.character(coord)[[1L]],
    flipped = isTRUE(flipped)
  )

  if (!is.null(row) && !is.na(row)) out$row <- as.integer(row)
  if (!is.null(col) && !is.na(col)) out$col <- as.integer(col)
  if (!is.null(x_trans) && !is.na(x_trans) && nzchar(x_trans)) out$x_trans <- as.character(x_trans)[[1L]]
  if (!is.null(y_trans) && !is.na(y_trans) && nzchar(y_trans)) out$y_trans <- as.character(y_trans)[[1L]]

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
    params = NULL) {

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

  if (!is.null(params) && length(params) > 0L) {
    out$params <- params
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
    panel_ids = NULL) {

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
    out$trans <- as.character(trans)[[1L]]
  }
  if (!is.null(domain) && length(domain) > 0L) {
    out$domain <- json_array(domain)
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

  out
}

#' Neutrally classify row-to-element cardinality for a linked leaf
#'
#' Records structural correspondence as a factual property without acting as a
#' verification gate.
#' @noRd
infer_lineage_cardinality <- function(geom = NA_character_, stat = NA_character_, n_rows = NA_integer_, n_elements = NA_integer_) {
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

make_lineage_df <- function(
    leaves,
    panel_id = NULL,
    layer_id = NULL,
    table_id = NULL,
    cardinality = NULL,
    n_rows = NULL) {

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
    stringsAsFactors = FALSE
  )
}
