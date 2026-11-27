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
    panel_role = NULL,
    aspect_lock = NULL,
    resize_mode = "free_xy") {

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

  # K2: Aspect lock and resize mode contract
  out$aspect_lock <- if (!is.null(aspect_lock) && is.numeric(aspect_lock) &&
                         length(aspect_lock) == 1L && is.finite(aspect_lock) && aspect_lock > 0) {
    round(as.numeric(aspect_lock)[[1L]], 6L)
  } else {
    NULL
  }
  out$resize_mode <- as.character(resize_mode %||% "free_xy")[[1L]]

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
    group_index_ref = NULL,
    scale_refs = NULL) {

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
  if (!is.null(scale_refs) && length(scale_refs) > 0L) {
    out$scale_refs <- scale_refs
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
    midpoint = NULL,
    scale_id = NULL) {

  scale_type <- match.arg(scale_type)

  out <- list()
  if (!is.null(scale_id) && !is.na(scale_id) && nzchar(scale_id)) {
    out$scale_id <- as.character(scale_id)[[1L]]
  }
  out$aesthetic <- as.character(aesthetic)[[1L]]
  out$field <- if (is.null(field) || is.na(field) || !nzchar(field)) NULL else as.character(field)[[1L]]
  out$scale_type <- scale_type

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

# --- K4: Property-level three-tier safe edit contracts (Schema v1.2) ---------

default_role_contracts <- function() {
  mk <- function(locked = character(), editable = character(), gated = character()) {
    list(
      locked = json_array(locked),
      editable = json_array(editable),
      gated = json_array(gated)
    )
  }
  list(
    data_mark = mk(
      locked = c("data_position", "row_binding", "group_identity", "mark_count"),
      editable = c("color_token_palette", "point_size", "stroke_width", "opacity"),
      gated = c("subset_visibility", "axis_domain_clip", "stat_recompute")
    ),
    data_label = mk(
      locked = c("text_content", "target_row_binding"),
      editable = c("label_offset", "text_wrap", "leader_line_path", "font_family", "font_size", "color"),
      gated = c("label_text_override", "label_subset_filter")
    ),
    leader_line = mk(
      locked = c("target_anchor_coord"),
      editable = c("label_endpoint", "stroke_color", "stroke_width", "stroke_dasharray", "opacity"),
      gated = c("leader_visibility")
    ),
    reference_mark = mk(
      locked = c("data_position", "intercept_slope"),
      editable = c("stroke_color", "stroke_width", "stroke_dasharray", "opacity"),
      gated = c("threshold_value_override", "visibility")
    ),
    dendrogram = mk(
      locked = c("tree_topology", "branch_heights", "leaf_order"),
      editable = c("stroke_color", "stroke_width", "opacity"),
      gated = c("cluster_method", "leaf_reorder")
    ),
    axis_tick = mk(
      locked = c("text_content", "tick_anchor_coord"),
      editable = c("font_family", "font_size", "rotation", "color"),
      gated = c("breaks_selection", "scale_transform")
    ),
    axis_line = mk(
      locked = c("panel_edge_alignment"),
      editable = c("stroke_color", "stroke_width", "opacity", "visibility"),
      gated = c("axis_range_override")
    ),
    axis_title = mk(
      locked = c("semantic_variable_meaning"),
      editable = c("position_offset", "text_wrap", "font_family", "font_size", "font_weight", "color"),
      gated = c("unit_or_label_change")
    ),
    strip_label = mk(
      locked = c("facet_level_identity"),
      editable = c("position_offset", "text_wrap", "font_family", "font_size", "color", "background_fill"),
      gated = c("facet_label_rename")
    ),
    guide_key = mk(
      locked = c("scale_domain_binding"),
      editable = c("color_token_palette", "guide_position", "swatch_size", "stroke_width", "opacity"),
      gated = c("guide_item_drop")
    ),
    guide_label = mk(
      locked = c("scale_domain_binding"),
      editable = c("guide_position", "text_wrap", "font_family", "font_size", "color"),
      gated = c("legend_label_rename")
    ),
    guide_frame = mk(
      locked = character(),
      editable = c("guide_position", "fill", "stroke_color", "stroke_width", "padding", "visibility"),
      gated = character()
    ),
    plot_title = mk(
      locked = character(),
      editable = c("position_offset", "text_wrap", "font_family", "font_size", "font_weight", "color", "text_align"),
      gated = c("title_text_override")
    ),
    plot_caption = mk(
      locked = character(),
      editable = c("position_offset", "text_wrap", "font_family", "font_size", "color", "text_align"),
      gated = c("caption_text_override")
    ),
    panel_grid = mk(
      locked = c("tick_grid_alignment"),
      editable = c("stroke_color", "stroke_width", "stroke_dasharray", "opacity", "visibility"),
      gated = c("grid_breaks_override")
    ),
    panel_frame = mk(
      locked = c("panel_bbox_alignment"),
      editable = c("fill", "stroke_color", "stroke_width", "visibility"),
      gated = character()
    ),
    background = mk(
      locked = character(),
      editable = c("fill", "opacity", "visibility"),
      gated = character()
    ),
    annotation = mk(
      locked = character(),
      editable = c("position_offset", "text_wrap", "font_family", "font_size", "color", "opacity"),
      gated = c("annotation_text_override", "visibility")
    ),
    other = mk(
      locked = character(),
      editable = c("fill", "stroke_color", "stroke_width", "opacity"),
      gated = c("geometry_transform")
    )
  )
}

# --- K3: Style token helpers (shared across ggplot / patchwork / heatmap) ----

normalize_hex_rgb <- function(val) {
  if (is.null(val) || length(val) == 0L || is.na(val)) return(NA_character_)
  s <- toupper(trimws(as.character(val)[[1L]]))
  if (!nzchar(s) || identical(s, "NA") || identical(s, "NONE")) return(NA_character_)
  # Strip alpha channel from 8-digit hex (#RRGGBBAA -> #RRGGBB)
  if (grepl("^#[0-9A-F]{8}$", s)) {
    return(substr(s, 1L, 7L))
  }
  s
}

build_scale_value_to_domain_map <- function(sc) {
  out <- stats::setNames(character(), character())
  if (is.null(sc) || length(sc$map %||% list()) == 0L) return(out)
  for (m in sc$map) {
    v <- normalize_hex_rgb(m$value)
    d <- as.character(m$domain %||% "")
    if (!is.na(v) && nzchar(d) && !(v %in% names(out))) {
      out[[v]] <- d
    }
  }
  out
}

format_style_token <- function(sc, mapped_value = NULL, domain_value = NULL) {
  if (is.null(sc) || is.null(sc$scale_id) || !nzchar(sc$scale_id)) return(NA_character_)
  sid <- sc$scale_id
  stype <- sc$scale_type %||% "unknown"
  if (stype %in% c("continuous", "binned")) {
    return(paste0(sid, "::continuous"))
  }
  if (!is.null(domain_value) && !is.na(domain_value) && nzchar(as.character(domain_value)[[1L]])) {
    return(paste0(sid, "::", as.character(domain_value)[[1L]]))
  }
  if (!is.null(mapped_value) && !is.na(mapped_value)) {
    v_norm <- normalize_hex_rgb(mapped_value)
    vmap <- build_scale_value_to_domain_map(sc)
    if (!is.na(v_norm) && v_norm %in% names(vmap)) {
      return(paste0(sid, "::", unname(vmap[[v_norm]])))
    }
  }
  NA_character_
}

tag_guide_element_tokens <- function(elements, guides_ir, scales_ir) {
  if (!is.data.frame(elements) || nrow(elements) == 0L ||
      is.null(guides_ir) || length(guides_ir$entries %||% list()) == 0L ||
      length(scales_ir) == 0L) {
    return(elements)
  }
  elements <- ensure_df_columns(elements, empty_elements_df())
  scale_by_id <- stats::setNames(list(), character())
  for (sc in scales_ir) {
    if (!is.null(sc$scale_id) && nzchar(sc$scale_id)) {
      scale_by_id[[sc$scale_id]] <- sc
    }
  }
  if (length(scale_by_id) == 0L) return(elements)

  el_pos <- stats::setNames(seq_len(nrow(elements)), elements$element_id)

  for (ent in guides_ir$entries) {
    sids <- unlist(ent$scale_ids %||% if (!is.null(ent$scale_id)) list(ent$scale_id) else list(), use.names = FALSE)
    sids <- intersect(as.character(sids), names(scale_by_id))
    if (length(sids) == 0L) next

    for (sid in sids) {
      sc <- scale_by_id[[sid]]
      aes_nm <- sc$aesthetic %||% ""
      if (!(aes_nm %in% c("colour", "color", "fill"))) next
      is_fill <- identical(aes_nm, "fill")

      for (it in (ent$items %||% list())) {
        if (identical(ent$kind, "colorbar")) {
          tok <- paste0(sid, "::continuous")
          bars <- as.character(unlist(it$bar_elements %||% list(), use.names = FALSE))
          idx <- unname(el_pos[intersect(bars, names(el_pos))])
          if (length(idx) > 0L) {
            if (is_fill) {
              elements$fill_token[idx] <- tok
            } else {
              elements$color_token[idx] <- tok
            }
          }
        } else {
          dom <- as.character(it$domain %||% "")
          if (!nzchar(dom)) next
          tok <- paste0(sid, "::", dom)
          sw <- as.character(unlist(it$swatch_elements %||% list(), use.names = FALSE))
          idx <- unname(el_pos[intersect(sw, names(el_pos))])
          if (length(idx) > 0L) {
            if (is_fill) {
              elements$fill_token[idx] <- tok
            } else {
              elements$color_token[idx] <- tok
            }
          }
        }
      }
    }
  }

  elements
}

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

  # 2. Guides / legends (ggplot guide-box, patchwork legend, ComplexHeatmap heatmap_legend/annotation_legend)
  if (grepl("^guide-box|^legend|heatmap_legend|annotation_legend", sl, ignore.case = TRUE) ||
      grepl("guide-box|legend\\.box", gp)) {
    if (grepl("label", gn, ignore.case = TRUE) || identical(gc, "text") || isTRUE(has_text)) {
      return(list(semantic_role = "guide_label", edit_policy = "movable"))
    }
    if (grepl("background|frame|border", gn, ignore.case = TRUE)) {
      return(list(semantic_role = "guide_frame", edit_policy = "style_only"))
    }
    return(list(semantic_role = "guide_key", edit_policy = "style_only"))
  }

  # 2b. Clustering dendrograms (ComplexHeatmap: `<ht>_dend_row_<k>` / `<ht>_dend_column_<k>`)
  if (grepl("dendrogram|_dend_(row|column)_", sl, ignore.case = TRUE) ||
      grepl("dendrogram|_dend_(row|column)_", gp, ignore.case = TRUE)) {
    return(list(semantic_role = "dendrogram", edit_policy = "geometry_locked"))
  }

  # 3. Plot titles, subtitles, captions, tags (including patchwork title-<k> / caption-<k>)
  if (grepl("^(title|subtitle)(-|$)", sl) || grepl("plot\\.title|plot\\.subtitle", gp)) {
    return(list(semantic_role = "plot_title", edit_policy = "movable"))
  }
  if (grepl("^(caption|tag)(-|$)", sl) || grepl("plot\\.caption|plot\\.tag", gp)) {
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
    degradation_reason = NULL,
    subplot = NULL,
    attached_to = NULL) {

  n <- nrow(leaves)
  if (n == 0L) {
    return(empty_lineage_df())
  }

  sub_vec <- if (!is.null(subplot)) {
    as.integer(subplot)
  } else if ("subplot" %in% names(leaves)) {
    as.integer(leaves$subplot)
  } else {
    rep(NA_integer_, n)
  }

  att_list <- if (!is.null(attached_to)) {
    attached_to
  } else if ("attached_to" %in% names(leaves) && is.list(leaves$attached_to)) {
    unclass(leaves$attached_to)
  } else {
    vector("list", n)
  }

  df <- data.frame(
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
    subplot = sub_vec,
    stringsAsFactors = FALSE
  )
  df$attached_to <- I(att_list)
  df
}

make_attachment <- function(panel_ids, side, align_axis = NULL) {
  pids <- unique(as.character(panel_ids))
  pids <- pids[!is.na(pids) & nzchar(pids)]
  if (length(pids) == 0L || is.null(side) || !nzchar(side)) return(NULL)
  ax <- align_axis %||% if (side %in% c("top", "bottom")) "x" else "y"
  list(
    panel_ids = json_array(pids),
    side = as.character(side)[[1L]],
    align_axis = as.character(ax)[[1L]]
  )
}

# K2: Extract container gtable track types (fixed_pt vs flex_null) and panel cells
extract_gtable_layout_tracks <- function(gtable, panel_grob_to_num = NULL, panel_ids_by_num = NULL) {
  if (is.null(gtable) || !inherits(gtable, "gtable") ||
      is.null(gtable$layout) || nrow(gtable$layout) == 0L) {
    return(NULL)
  }
  classify_tracks <- function(unit_vec) {
    if (is.null(unit_vec) || length(unit_vec) == 0L) return(list())
    strs <- tryCatch(as.character(unit_vec), error = function(e) rep("unknown", length(unit_vec)))
    lapply(seq_along(strs), function(k) {
      s <- strs[[k]]
      list(
        index = as.integer(k),
        kind = if (grepl("null", s, fixed = TRUE)) "flex_null" else "fixed_pt",
        unit = s
      )
    })
  }

  panel_cells <- list()
  lay <- gtable$layout
  pan_rows <- grep("^panel", lay$name)
  for (j in pan_rows) {
    nm <- lay$name[[j]]
    if (identical(nm, "panel-area")) next
    pg <- gtable$grobs[[j]]
    pid <- NULL
    if (!is.null(pg) && !is.null(pg$name) && !is.null(panel_grob_to_num) &&
        pg$name %in% names(panel_grob_to_num)) {
      pnum <- as.character(panel_grob_to_num[[pg$name]])
      if (!is.null(panel_ids_by_num) && pnum %in% names(panel_ids_by_num)) {
        pid <- unname(panel_ids_by_num[[pnum]])
      }
    }
    panel_cells[[length(panel_cells) + 1L]] <- list(
      name = nm,
      panel_id = pid,
      t = as.integer(lay$t[[j]]),
      l = as.integer(lay$l[[j]]),
      b = as.integer(lay$b[[j]]),
      r = as.integer(lay$r[[j]])
    )
  }

  list(
    nrow = as.integer(length(gtable$heights)),
    ncol = as.integer(length(gtable$widths)),
    col_tracks = json_array(classify_tracks(gtable$widths)),
    row_tracks = json_array(classify_tracks(gtable$heights)),
    panel_cells = json_array(panel_cells)
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
      # Keep subplot & attached_to synchronized between leaves and lineage
      if (is.na(leaves$subplot[[r]]) && !is.na(lineage$subplot[[li_pos]])) {
        leaves$subplot[[r]] <- lineage$subplot[[li_pos]]
      } else if (is.na(lineage$subplot[[li_pos]]) && !is.na(leaves$subplot[[r]])) {
        lineage$subplot[[li_pos]] <- leaves$subplot[[r]]
      }
      if (is.null(leaves$attached_to[[r]]) && !is.null(lineage$attached_to[[li_pos]])) {
        leaves$attached_to[[r]] <- lineage$attached_to[[li_pos]]
      } else if (is.null(lineage$attached_to[[li_pos]]) && !is.null(leaves$attached_to[[r]])) {
        lineage$attached_to[[li_pos]] <- leaves$attached_to[[r]]
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

# --- K1: Cross-Figure Entity Coordinate System (Schema v1.2) -----------------

ENTITY_ROLE_HINTS <- list(
  subject = c(
    "patient_id", "patient", "subject_id", "subject", "participant_id",
    "participant", "donor_id", "donor", "case_id", "individual_id",
    "mouse_id", "animal_id", "subjid", "usubjid", "pat_id"
  ),
  sample = c(
    "sample_id", "sample", "specimen_id", "specimen", "aliquot_id",
    "biosample_id", "library_id", "run_id", "col_label", "sample_name"
  ),
  feature = c(
    "gene", "gene_id", "gene_symbol", "gene_name", "symbol", "ensembl_id",
    "entrez_id", "protein", "protein_id", "uniprot_id", "transcript_id",
    "probe_id", "feature_id", "feature", "metabolite", "metabolite_id",
    "peak_id", "otu_id", "asv_id", "pathway", "pathway_id", "row_label"
  ),
  cell = c(
    "cell_id", "barcode", "cell_barcode", "cell_name", "cell"
  ),
  batch = c(
    "batch", "batch_id", "plate", "plate_id", "lane", "seq_run",
    "cohort", "center", "site", "study", "study_id"
  ),
  timepoint = c(
    "timepoint", "time_point", "visit", "visit_id", "cycle", "stage"
  ),
  treatment = c(
    "treatment", "arm", "treatment_arm", "condition", "drug", "regimen",
    "genotype", "phenotype", "subtype", "cluster", "cell_type", "celltype", "group"
  ),
  region = c(
    "region", "region_id", "country", "state", "province", "county",
    "iso_a3", "fips", "location", "tissue", "organ", "anatomical_region"
  ),
  primary_key = c(
    "id", "record_id", "obs_id", "item_id", "car_id", "label", "name"
  )
)

ENTITY_ROLE_PRIORITY <- c(
  "subject", "sample", "feature", "cell", "primary_key",
  "batch", "timepoint", "treatment", "region"
)

compute_entity_domain_summary <- function(values) {
  vals <- as.character(values)
  vals <- vals[!is.na(vals) & nzchar(vals)]
  if (length(vals) == 0L) {
    return(list(
      n_distinct = 0L,
      domain_sha256 = prefixed_sha256(sha256_text("[]")),
      sample_values = list()
    ))
  }
  u <- sort(unique(enc2utf8(vals)), method = "radix")
  payload <- as.character(to_gloss_json(json_array(u), pretty = FALSE))
  list(
    n_distinct = as.integer(length(u)),
    domain_sha256 = prefixed_sha256(sha256_text(payload)),
    sample_values = json_array(utils::head(u, 5L))
  )
}

is_valid_entity_vector <- function(col, explicit = FALSE, strong_name = FALSE) {
  if (is.null(col) || length(col) == 0L || is.list(col) || inherits(col, "sfc")) {
    return(FALSE)
  }
  non_na <- col[!is.na(col)]
  if (length(non_na) == 0L) return(FALSE)

  if (isTRUE(explicit)) {
    return(is.atomic(col))
  }
  if (is.character(col) || is.factor(col)) {
    chr <- as.character(non_na)
    return(any(nzchar(trimws(chr))))
  }
  if (is.integer(col)) {
    return(TRUE)
  }
  if (is.double(col) && isTRUE(strong_name)) {
    fin <- non_na[is.finite(non_na)]
    return(length(fin) > 0L && all(abs(fin - round(fin)) < 1e-8))
  }
  FALSE
}

infer_entity_role_from_name <- function(col_name, col_vec) {
  low <- tolower(trimws(as.character(col_name)[[1L]]))
  if (!nzchar(low) || startsWith(low, "_")) return(NULL)

  for (role in names(ENTITY_ROLE_HINTS)) {
    if (low %in% ENTITY_ROLE_HINTS[[role]]) {
      strong <- role %in% c("subject", "sample", "feature", "cell", "batch", "timepoint", "primary_key")
      if (is_valid_entity_vector(col_vec, explicit = FALSE, strong_name = strong)) {
        return(role)
      }
      return(NULL)
    }
  }

  # Pattern fallbacks for compound names like `donor_code` or `patient_num`
  if (grepl("(^|_)(patient|subject|participant|donor)(_|$)", low)) {
    if (is_valid_entity_vector(col_vec, explicit = FALSE, strong_name = TRUE)) return("subject")
  }
  if (grepl("(^|_)(sample|specimen|aliquot|library)(_|$)", low)) {
    if (is_valid_entity_vector(col_vec, explicit = FALSE, strong_name = TRUE)) return("sample")
  }
  if (grepl("(^|_)(gene|protein|transcript|ensembl|feature|metabolite)(_|$)", low)) {
    if (is_valid_entity_vector(col_vec, explicit = FALSE, strong_name = TRUE)) return("feature")
  }
  if (grepl("(^|_)(cell|barcode)(_|$)", low)) {
    if (is_valid_entity_vector(col_vec, explicit = FALSE, strong_name = TRUE)) return("cell")
  }
  if (grepl("(^|_)(batch|plate|seq_run|cohort)(_|$)", low)) {
    if (is_valid_entity_vector(col_vec, explicit = FALSE, strong_name = TRUE)) return("batch")
  }
  if (grepl("(^|_)(timepoint|visit)(_|$)", low)) {
    if (is_valid_entity_vector(col_vec, explicit = FALSE, strong_name = TRUE)) return("timepoint")
  }
  if (grepl("_id$", low)) {
    if (is_valid_entity_vector(col_vec, explicit = FALSE, strong_name = TRUE)) return("primary_key")
  }

  NULL
}

normalize_explicit_entities <- function(entities) {
  if (is.null(entities) || length(entities) == 0L) {
    return(list())
  }
  out <- list()
  if (is.character(entities)) {
    nms <- names(entities)
    for (i in seq_along(entities)) {
      col_nm <- as.character(entities[[i]])[[1L]]
      if (is.na(col_nm) || !nzchar(col_nm)) next
      role <- if (!is.null(nms) && nzchar(nms[[i]])) nms[[i]] else "entity"
      out[[length(out) + 1L]] <- list(entity_role = role, column = col_nm)
    }
    return(out)
  }
  if (is.list(entities)) {
    nms <- names(entities)
    for (i in seq_along(entities)) {
      role <- if (!is.null(nms) && nzchar(nms[[i]])) nms[[i]] else "entity"
      cols <- as.character(unlist(entities[[i]], use.names = FALSE))
      cols <- cols[!is.na(cols) & nzchar(cols)]
      for (col_nm in cols) {
        out[[length(out) + 1L]] <- list(entity_role = role, column = col_nm)
      }
    }
    return(out)
  }
  cli::cli_abort("{.arg entities} must be NULL, a named character vector, or a named list of column names.")
}

extract_capture_entities <- function(tables, explicit_entities = NULL) {
  if (length(tables) == 0L) {
    return(list())
  }

  exp_specs <- normalize_explicit_entities(explicit_entities)

  # Accumulator keyed by "<entity_role>::<name>" using local environment (zero <<-)
  st <- new.env(parent = emptyenv())
  st$acc <- list()
  st$bound_keys <- character()

  add_binding <- function(role, name, table_id, axis, column, values, explicit = FALSE) {
    vals_chr <- as.character(values)
    non_na <- vals_chr[!is.na(vals_chr) & nzchar(vals_chr)]
    if (length(non_na) == 0L) return(invisible(NULL))

    bkey <- paste(table_id, axis, column %||% "<axis>", sep = "::")
    if (bkey %in% st$bound_keys) return(invisible(NULL))
    st$bound_keys <- c(st$bound_keys, bkey)

    is_uniq <- !anyNA(values) && length(unique(vals_chr)) == length(vals_chr)
    ekey <- paste(role, name, sep = "::")
    binding_obj <- list(
      table_id = table_id,
      axis = axis,
      column = column,
      unique = isTRUE(is_uniq)
    )
    if (isTRUE(explicit)) {
      binding_obj$source <- "explicit"
    }

    cur <- st$acc[[ekey]]
    if (is.null(cur)) {
      st$acc[[ekey]] <- list(
        entity_role = role,
        name = name,
        bindings = list(binding_obj),
        values = non_na
      )
    } else {
      cur$bindings[[length(cur$bindings) + 1L]] <- binding_obj
      cur$values <- c(cur$values, non_na)
      st$acc[[ekey]] <- cur
    }
    invisible(NULL)
  }

  # Choose candidate tables: raw & annotation first; fall back to built if no raw/annotation exist
  tbl_roles <- vapply(tables, function(e) e$role %||% "raw", character(1L))
  scan_tids <- names(tables)[tbl_roles %in% c("raw", "annotation")]
  if (length(scan_tids) == 0L) {
    scan_tids <- names(tables)
  }

  # Tier 1: Explicit caller declarations
  for (sp in exp_specs) {
    matched_any <- FALSE
    for (tid in names(tables)) {
      ent <- tables[[tid]]
      df <- ent$data
      if (!is.data.frame(df) || nrow(df) == 0L) next
      if (sp$column %in% names(df) && is_valid_entity_vector(df[[sp$column]], explicit = TRUE)) {
        add_binding(sp$entity_role, sp$column, tid, "row", sp$column, df[[sp$column]], explicit = TRUE)
        matched_any <- TRUE
      }
    }
    if (!matched_any) {
      # Support explicit matrix row/column entity naming on ComplexHeatmap tables
      low_c <- tolower(sp$column)
      low_r <- tolower(sp$entity_role)
      for (tid in scan_tids) {
        ent <- tables[[tid]]
        if (!is.null(ent$matrix_rownames) &&
            (low_r %in% c("feature", "gene", "row", "row_entity") || low_c %in% c("rownames", "row_label"))) {
          col_ref <- if ("row_label" %in% names(ent$data)) "row_label" else NULL
          add_binding(sp$entity_role, sp$column, tid, "row", col_ref, ent$matrix_rownames, explicit = TRUE)
        }
        if (!is.null(ent$matrix_colnames) &&
            (low_r %in% c("sample", "cell", "subject", "col", "col_entity") || low_c %in% c("colnames", "col_label"))) {
          add_binding(sp$entity_role, sp$column, tid, "col", NULL, ent$matrix_colnames, explicit = TRUE)
        }
      }
    }
  }

  # Tier 2: Heuristic auto-recognition across raw & annotation tables
  for (tid in scan_tids) {
    ent <- tables[[tid]]
    df <- ent$data
    if (!is.data.frame(df) || nrow(df) == 0L) next
    is_matrix_tbl <- !is.null(ent$matrix_colnames) || !is.null(ent$matrix_rownames)

    if (is_matrix_tbl) {
      # Register heatmap matrix row entity & column entity
      if (!is.null(ent$matrix_rownames) && length(ent$matrix_rownames) > 0L) {
        col_ref <- if ("row_label" %in% names(df)) "row_label" else NULL
        add_binding("feature", "row_label", tid, "row", col_ref, ent$matrix_rownames, explicit = FALSE)
      }
      if (!is.null(ent$matrix_colnames) && length(ent$matrix_colnames) > 0L) {
        add_binding("sample", "col_label", tid, "col", NULL, ent$matrix_colnames, explicit = FALSE)
      }
      next
    }

    for (cn in names(df)) {
      role <- infer_entity_role_from_name(cn, df[[cn]])
      if (!is.null(role)) {
        add_binding(role, cn, tid, "row", cn, df[[cn]], explicit = FALSE)
      }
    }
  }

  if (length(st$acc) == 0L) {
    return(list())
  }

  # Finalize merged entity summaries in deterministic role priority order
  entries <- lapply(st$acc, function(item) {
    dom <- compute_entity_domain_summary(item$values)
    list(
      entity_role = item$entity_role,
      name = item$name,
      bindings = json_array(item$bindings),
      n_distinct = dom$n_distinct,
      domain_sha256 = dom$domain_sha256,
      sample_values = dom$sample_values
    )
  })
  prio <- vapply(entries, function(e) {
    p <- match(e$entity_role, ENTITY_ROLE_PRIORITY)
    if (is.na(p)) 99L else as.integer(p)
  }, integer(1L))
  nms_ord <- vapply(entries, `[[`, character(1L), "name")
  unname(entries[order(prio, nms_ord)])
}

entity_column_roles_for_table <- function(entities, table_id) {
  out <- stats::setNames(character(), character())
  if (length(entities) == 0L) return(out)
  for (ent in entities) {
    role <- ent$entity_role %||% ""
    if (!nzchar(role)) next
    for (b in (ent$bindings %||% list())) {
      if (identical(b$table_id, table_id) && identical(b$axis, "row") &&
          !is.null(b$column) && nzchar(b$column) && !(b$column %in% names(out))) {
        out[[b$column]] <- role
      }
    }
  }
  out
}

# --- K6: Pre-plot upstream data funnel (Schema v1.2) -------------------------

infer_filter_hint_from_call <- function(call_expr) {
  if (is.null(call_expr) || !is.character(call_expr) || !nzchar(call_expr)) return(NULL)
  if (grepl("subset\\(|filter\\(|\\[|\\|>", call_expr)) {
    return(call_expr)
  }
  NULL
}

build_upstream_data_funnel <- function(upstream, tables, entities = list(), call_expr = NULL) {
  if (is.null(upstream)) {
    return(list(funnel = NULL, upstream_table = NULL))
  }

  up_df <- NULL
  filter_hint <- NULL
  req_col <- NULL
  req_role <- NULL
  include_table <- FALSE

  if (is.data.frame(upstream)) {
    up_df <- upstream
  } else if (is.list(upstream) && is.data.frame(upstream$data)) {
    up_df <- upstream$data
    filter_hint <- upstream$filter_hint %||% upstream$note %||% upstream$filter %||% NULL
    req_col <- upstream$entity_column %||% upstream$column %||% NULL
    req_role <- upstream$entity_role %||% upstream$role %||% NULL
    include_table <- isTRUE(upstream$include_table)
  } else {
    cli::cli_abort("{.arg upstream} must be NULL, a data.frame, or a list containing a {.field data} data.frame.")
  }

  if (is.null(filter_hint)) {
    filter_hint <- infer_filter_hint_from_call(call_expr)
  }

  # Collect plot raw input table(s)
  raw_tids <- names(tables)[vapply(tables, function(e) identical(e$role %||% "raw", "raw"), logical(1L))]
  primary_tid <- if ("raw" %in% raw_tids) {
    "raw"
  } else if (length(raw_tids) > 0L) {
    raw_tids[[1L]]
  } else if (length(tables) > 0L) {
    names(tables)[[1L]]
  } else {
    NULL
  }

  primary_df <- if (!is.null(primary_tid)) tables[[primary_tid]]$data else NULL
  n_up <- as.integer(nrow(up_df))
  n_in <- if (is.data.frame(primary_df)) as.integer(nrow(primary_df)) else 0L

  # Resolve shared entity column between upstream_df and plot raw tables
  ent_col <- NULL
  ent_role <- req_role
  if (!is.null(req_col) && req_col %in% names(up_df)) {
    ent_col <- as.character(req_col)[[1L]]
  }
  if (is.null(ent_col) && length(entities) > 0L) {
    for (ent in entities) {
      # Check entity bindings on raw tables
      for (b in (ent$bindings %||% list())) {
        if (b$table_id %in% raw_tids && identical(b$axis, "row") &&
            !is.null(b$column) && b$column %in% names(up_df)) {
          ent_col <- b$column
          ent_role <- ent_role %||% ent$entity_role
          break
        }
      }
      if (!is.null(ent_col)) break
    }
  }
  if (is.null(ent_col) && is.data.frame(primary_df)) {
    shared_cols <- intersect(names(up_df), names(primary_df))
    for (cn in shared_cols) {
      inferred <- infer_entity_role_from_name(cn, up_df[[cn]])
      if (!is.null(inferred)) {
        ent_col <- cn
        ent_role <- ent_role %||% inferred
        break
      }
    }
  }

  funnel <- list(
    n_upstream = n_up,
    n_plot_input = n_in,
    n_upstream_excluded = as.integer(max(0L, n_up - n_in))
  )

  if (!is.null(ent_col)) {
    up_vals <- unique(as.character(up_df[[ent_col]][!is.na(up_df[[ent_col]])]))
    in_vals <- character()
    for (rtid in raw_tids) {
      rdf <- tables[[rtid]]$data
      if (is.data.frame(rdf) && ent_col %in% names(rdf)) {
        v <- as.character(rdf[[ent_col]][!is.na(rdf[[ent_col]])])
        in_vals <- union(in_vals, v)
      }
    }
    if (length(in_vals) == 0L && is.data.frame(primary_df) && ent_col %in% names(primary_df)) {
      in_vals <- unique(as.character(primary_df[[ent_col]][!is.na(primary_df[[ent_col]])]))
    }
    excl_vals <- sort(setdiff(up_vals, in_vals), method = "radix")

    if (!is.null(ent_role) && nzchar(ent_role)) {
      funnel$entity_role <- as.character(ent_role)[[1L]]
    }
    funnel$entity_column <- ent_col
    funnel$n_upstream_entities <- as.integer(length(up_vals))
    funnel$n_plot_input_entities <- as.integer(length(in_vals))
    funnel$n_excluded_entities <- as.integer(length(excl_vals))
    funnel$excluded_entities_sample <- json_array(utils::head(excl_vals, 50L))
  }

  if (!is.null(filter_hint) && nzchar(as.character(filter_hint)[[1L]])) {
    funnel$filter_hint <- as.character(filter_hint)[[1L]]
  }

  up_tbl <- if (isTRUE(include_table)) {
    list(
      table_id = "upstream",
      role = "upstream",
      key = if (!is.null(ent_col) && !anyNA(up_df[[ent_col]]) &&
                length(unique(up_df[[ent_col]])) == nrow(up_df)) ent_col else character(),
      layer_id = NULL,
      data = up_df
    )
  } else {
    NULL
  }

  list(funnel = funnel, upstream_table = up_tbl)
}
