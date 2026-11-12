# Identify: the public geometry queries over the substrate. Device space is
# SVG user units (1/72 in) with the origin at the top left, as in the scene.

#' Elements of a figure
#'
#' @param fig A `gloss_figure`.
#' @param where Optional named list of filters, e.g.
#'   `list(leaf = "L006")`, `list(tag = "circle", panel = "panel1")`.
#'   Values are matched with `%in%`.
#' @return A data frame with one row per drawn element: `id`, `leaf`, `tag`,
#'   `ordinal` (position within the leaf), the box `x0`, `y0`, `x1`, `y1`
#'   (device space), `fill`, `stroke`, `text` and `panel`.
#' @export
gl_elements <- function(fig, where = NULL) {
  check_figure(fig)
  el <- fig$substrate$elements
  lv <- fig$substrate$leaves
  el$panel <- lv$panel[match(el$leaf, lv$id)]
  for (nm in names(where)) {
    if (!nm %in% names(el)) cli::cli_abort("Unknown element field {.val {nm}}.")
    el <- el[el[[nm]] %in% where[[nm]], , drop = FALSE]
  }
  rownames(el) <- NULL
  el
}

#' Leaves of a figure
#'
#' @param fig A `gloss_figure`.
#' @param id Optional leaf id. Without it, all leaves are returned.
#' @return With `id`, a list describing one leaf: grob path and class,
#'   viewport path, device box, native scales, expected and drawn element
#'   counts, count status and panel. Without `id`, the leaves as a data
#'   frame.
#' @export
gl_leaf <- function(fig, id = NULL) {
  check_figure(fig)
  lv <- fig$substrate$leaves
  if (is.null(id)) return(lv)
  row <- lv[lv$id == id, , drop = FALSE]
  if (!nrow(row)) cli::cli_abort("No leaf {.val {id}}.")
  out <- as.list(row)
  out$elements <- fig$substrate$elements$id[fig$substrate$elements$leaf %in% id]
  out
}

#' Panels of a figure
#'
#' @param fig A `gloss_figure`.
#' @return A data frame with one row per panel: id, facet key, viewport,
#'   device box and the type, range and transformation of the horizontal (`x`)
#'   and vertical (`y`) scales.
#' @export
gl_panels <- function(fig) {
  check_figure(fig)
  fig$substrate$panels
}

#' Elements under a point
#'
#' @param fig A `gloss_figure`.
#' @param x,y A point. In `"device"` space, SVG user units from the top left;
#'   in `"data"` space, values on the scales of `panel`.
#' @param space `"device"` or `"data"`.
#' @param panel Panel id, required for `"data"` space.
#' @param tolerance Extra distance, in device units, around each element.
#' @return Elements whose box contains the point, topmost first (circles
#'   are tested by distance to their centre).
#' @export
gl_hit <- function(fig, x, y, space = c("device", "data"), panel = NULL, tolerance = 0) {
  space <- match.arg(space)
  if (space == "data") {
    if (is.null(panel)) cli::cli_abort("{.arg panel} is required in data space.")
    px <- gl_to_pixel(fig, panel, x, y)
    x <- px$x
    y <- px$y
  }
  el <- gl_elements(fig)
  inside <- el$x0 - tolerance <= x & x <= el$x1 + tolerance &
    el$y0 - tolerance <= y & y <= el$y1 + tolerance
  inside[is.na(inside)] <- FALSE
  circ <- inside & el$tag == "circle"
  if (any(circ)) {
    cx <- (el$x0[circ] + el$x1[circ]) / 2
    cy <- (el$y0[circ] + el$y1[circ]) / 2
    r <- (el$x1[circ] - el$x0[circ]) / 2
    inside[circ] <- (x - cx)^2 + (y - cy)^2 <= (r + tolerance)^2 + 1e-9
  }
  out <- el[inside, , drop = FALSE]
  out <- out[rev(seq_len(nrow(out))), , drop = FALSE]
  rownames(out) <- NULL
  out
}

element_row <- function(fig, id) {
  el <- gl_elements(fig)
  row <- el[el$id == id, , drop = FALSE]
  if (!nrow(row)) cli::cli_abort("No element {.val {id}}.")
  row
}

#' Nearest elements
#'
#' @param fig A `gloss_figure`.
#' @param anchor An element id. (Anchors with several selectors arrive in M2.)
#' @param k Number of neighbours.
#' @param same_leaf Only consider elements of the same leaf.
#' @return The `k` elements whose box centres are nearest the anchor's, with
#'   a `distance` column in device units.
#' @export
gl_near <- function(fig, anchor, k = 5, same_leaf = FALSE) {
  a <- element_row(fig, anchor)
  el <- gl_elements(fig)
  el <- el[el$id != anchor & !is.na(el$x0), , drop = FALSE]
  if (same_leaf) el <- el[el$leaf %in% a$leaf, , drop = FALSE]
  ax <- (a$x0 + a$x1) / 2
  ay <- (a$y0 + a$y1) / 2
  el$distance <- sqrt(((el$x0 + el$x1) / 2 - ax)^2 + ((el$y0 + el$y1) / 2 - ay)^2)
  out <- el[order(el$distance), , drop = FALSE]
  out <- utils::head(out, k)
  rownames(out) <- NULL
  out
}

#' Elements overlapping an element
#'
#' @inheritParams gl_near
#' @return Elements whose box intersects the anchor's, with `relation`
#'   `"above"` (drawn later, so on top) or `"below"` (drawn earlier).
#' @export
gl_overlap <- function(fig, anchor) {
  a <- element_row(fig, anchor)
  el <- gl_elements(fig)
  pos <- match(anchor, el$id)
  hit <- el$x0 < a$x1 & el$x1 > a$x0 & el$y0 < a$y1 & el$y1 > a$y0
  hit[is.na(hit)] <- FALSE
  hit[pos] <- FALSE
  out <- el[hit, , drop = FALSE]
  out$relation <- ifelse(which(hit) > pos, "above", "below")
  rownames(out) <- NULL
  out
}

panel_row <- function(fig, panel) {
  p <- fig$substrate$panels
  row <- p[p$id == panel, , drop = FALSE]
  if (!nrow(row)) cli::cli_abort(c("No panel {.val {panel}}.", i = "Panels: {.val {p$id}}."))
  for (ax in c("x", "y")) {
    if (!row[[paste0(ax, "_type")]] %in% c("continuous", "discrete", "native")) {
      cli::cli_abort("The {ax} scale of panel {.val {panel}} cannot be mapped ({row[[paste0(ax, '_type')]]}).")
    }
  }
  row
}

#' Map between data and device coordinates
#'
#' `x` is a value on the panel's horizontal scale and `y` on its vertical
#' scale, in the scale's own space: transformed values for transformed
#' continuous scales, positions (1, 2, ...) for discrete scales. Under
#' `coord_flip()` the horizontal scale is the one mapped to `y` in the plot.
#'
#' @param fig A `gloss_figure`.
#' @param panel Panel id, see [gl_panels()].
#' @param x,y Coordinates.
#' @return A list with `x` and `y` in the target space.
#' @export
gl_to_pixel <- function(fig, panel, x, y) {
  p <- panel_row(fig, panel)
  list(
    x = p$x0 + (x - p$x_min) / (p$x_max - p$x_min) * (p$x1 - p$x0),
    y = p$y1 - (y - p$y_min) / (p$y_max - p$y_min) * (p$y1 - p$y0)
  )
}

#' @rdname gl_to_pixel
#' @export
gl_to_data <- function(fig, panel, x, y) {
  p <- panel_row(fig, panel)
  list(
    x = p$x_min + (x - p$x0) / (p$x1 - p$x0) * (p$x_max - p$x_min),
    y = p$y_min + (p$y1 - y) / (p$y1 - p$y0) * (p$y_max - p$y_min)
  )
}
