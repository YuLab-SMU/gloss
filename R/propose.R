# gl_propose(): a statement about the figure given as data, checked by code
# before it counts (principle 2; ADR-0009). The first kind is a binding: this
# element draws this row of this table. The check uses the figure alone
# (core-alone.R): the row placed through its panel's scales, the element
# compared by the binder's comparison for its tag (core-bind.R). So it
# answers the same on a figure read back from a bundle, where the engine's
# state is gone. Plan 2026-11-12-agent-path, Task 3.
#
# Three outcomes, and no fourth:
#   accepted   the check ran and the pairing passes; `record` holds it
#   rejected   the proposal is not valid data (stage "schema"), names what
#              is not in the figure ("exists"), or the check ran and the
#              pairing does not pass ("check")
#   refused    the check cannot run on this figure; `reasons` says why.
#              Nothing is accepted unchecked.

proposal_schema <- list(kind = list(type = "string", enum = "binding"),
                        element = "string", table = "string", row = "integer")

# Engines whose built tables state positions the figure alone can place.
# A base table holds a call's arguments (a log axis, a polygon's vertices)
# and a heatmap's holds values: agent-path plan, Task 2.
proposal_engines <- c("ggplot", "patchwork")

# What every check of proposals on one figure needs, made once: the scene is
# parsed for the elements' geometry.
propose_context <- function(fig, tol = bind_tolerance) {
  check_figure(fig)
  modes <- fig$derived$bindings$tables$leaves
  list(fig = fig, geo = scene_geometry(fig$substrate), tol = tol,
       mode = if (is.null(modes)) character() else stats::setNames(modes$mode, modes$leaf))
}

# A value from a proposal, short enough to quote in a reason.
quoted <- function(x) {
  x <- as.character(x)[1]
  if (nchar(x) > 40L) paste0(substr(x, 1L, 40L), "...") else x
}

check_proposal <- function(ctx, proposal) {
  fig <- ctx$fig
  tol <- ctx$tol
  done <- function(outcome, stage, reasons, record = NULL) {
    structure(list(outcome = outcome, stage = stage, reasons = substr(reasons, 1L, 300L), record = record),
              class = "gloss_proposal")
  }
  problems <- gl_schema_validate(proposal, proposal_schema)
  if (length(problems)) return(done("rejected", "schema", problems))

  el <- fig$substrate$elements
  k <- match(proposal$element, el$id)
  if (is.na(k)) return(done("rejected", "exists", sprintf("no element '%s' in the figure", quoted(proposal$element))))
  tab <- fig$tables[[proposal$table]]
  if (is.null(tab) || is.null(tab$data)) {
    return(done("rejected", "exists", sprintf("no table '%s' with rows in the figure", quoted(proposal$table))))
  }
  t <- tab$data
  row <- as.integer(proposal$row)
  if (row < 1L || row > nrow(t)) {
    return(done("rejected", "exists", sprintf("row %d is outside the table '%s' (%d rows)", row, tab$name, nrow(t))))
  }

  engine <- fig$meta$engine %||% NA_character_
  if (!engine %in% proposal_engines) {
    return(done("refused", "check", sprintf(
      "bindings are checked on %s figures so far; this figure's engine is '%s'",
      paste(proposal_engines, collapse = " and "), engine)))
  }
  if (!identical(tab$role, "built")) {
    return(done("refused", "check", sprintf(
      "the table '%s' is not a layer's built data: only built data state where a row is drawn", tab$name)))
  }
  leaves <- fig$substrate$leaves
  leaf <- el$leaf[k]
  lf <- leaves[match(leaf, leaves$id), , drop = FALSE]
  panel <- if (is.na(leaf)) NA_character_ else lf$panel
  if (is.na(panel)) {
    w <- fig$status$withheld
    if (is.data.frame(w) && any(w$what %in% "panels")) {
      return(done("refused", "check", "panels of this figure are withheld, so the element's panel and its scales are not known"))
    }
    return(done("rejected", "check",
                "the element is drawn outside every panel (an axis, a legend, a title, a background): it draws no row of a layer"))
  }
  # one element for one row only: an element that draws a group of rows (a
  # line, an area) needs a proposal for the group
  tag <- el$tag[k]
  mode <- ctx$mode[leaf] %|NA|% NA_character_
  one_row <- if (is.na(mode)) tag %in% c("circle", "rect", "text", "image", "line") else mode %in% c("row", "symbol")
  if (!one_row) {
    return(done("refused", "check", sprintf(
      "a <%s> element of this leaf draws, or may draw, a whole group of rows; a binding of one element to one row is not checked for it",
      tag)))
  }
  # the plot of a composition, and the panel, the row belongs to
  plot_of <- function(x, what) sub(what, "", x)
  if (!identical(plot_of(panel, "panel[0-9]+$"), plot_of(tab$name, "built_layer[0-9]+$"))) {
    return(done("rejected", "check", sprintf("the table '%s' belongs to another plot of the composition than the element's panel (%s)",
                                             tab$name, panel)))
  }
  in_panel <- seq_len(nrow(t))
  if ("PANEL" %in% names(t)) {
    pk <- sub("^.*panel", "", panel)
    if (!identical(as.character(t$PANEL[row]), pk)) {
      return(done("rejected", "check", sprintf("row %d is drawn in another panel (PANEL %s) than the element (%s)",
                                               row, as.character(t$PANEL[row]), panel)))
    }
    in_panel <- which(as.character(t$PANEL) == pk)
  }
  all_pred <- placed_rows(fig, tab$name, in_panel, panel)
  if (is.character(all_pred)) return(done("refused", "check", all_pred))
  own <- all_pred[all_pred$row == row, , drop = FALSE]
  g <- ctx$geo[match(proposal$element, ctx$geo$id), , drop = FALSE]
  res <- check_rows(g, own, all_pred, tol)
  if (!is.null(res$reason)) return(done("refused", "check", res$reason))
  if (!isTRUE(res$pass)) {
    how_far <- if (is.na(res$dev)) "not where the element is" else sprintf("%.1f pt from the element", res$dev)
    return(done("rejected", "check", sprintf(
      "row %d of '%s', placed through the scales of %s, is %s (%s); the tolerance is %s pt",
      row, tab$name, panel, how_far, proposal$element, format(tol))))
  }
  done("accepted", "check", character(), record = list(
    kind = "binding", element = proposal$element, leaf = leaf, table = tab$name, row = row,
    status = if (res$n_pass > 1L) "ambiguous" else "verified",
    dev = round(res$dev * 1000) / 1000, tolerance = tol, basis = "figure"
  ))
}

#' Propose a pairing and have it checked
#'
#' A statement about the figure, given as data, counts only when code has
#' checked it. `gl_propose()` takes one proposal, checks it against the
#' figure and says what happened. People and agents call the same function.
#'
#' The check uses the figure alone: the row is put on the page through the
#' scales of the element's panel and compared with where the element is
#' drawn, within 0.5 pt, by the comparison [gl_bindings()] uses for that kind
#' of element. It needs neither the object that was drawn nor the bindings
#' made at capture, so it answers the same on a figure read with [gl_read()].
#'
#' @section Proposals:
#' A named list with exactly these fields:
#' * `kind`: `"binding"`, the only kind so far;
#' * `element`: an element id, see [gl_elements()];
#' * `table`: the name of a layer's built data, see [gl_tables()];
#' * `row`: a row number of that table.
#'
#' @section Outcomes:
#' * `"accepted"`: the row is drawn where the element is. `record` holds the
#'   pairing with its `status`: `"verified"`, or `"ambiguous"` when another
#'   row of the layer in that panel is drawn at the same place.
#' * `"rejected"`: the proposal is not valid data (`stage` `"schema"`), names
#'   an element, a table or a row that is not in the figure (`"exists"`), or
#'   was checked and does not hold (`"check"`). `reasons` says which.
#' * `"refused"`: the pairing cannot be checked on this figure: a panel
#'   whose scales are not ranges on the page (`coord_polar()`, `coord_sf()`),
#'   a figure of an engine other than ggplot or patchwork, an element that
#'   draws a whole group of rows. `reasons` says why. Nothing is accepted
#'   unchecked.
#'
#' A row is placed by the values its table holds. A geom that moves its rows
#' while drawing is rejected where it draws them elsewhere; the bindings
#' made at capture know such geoms, see [gl_bindings()].
#'
#' @param fig A `gloss_figure`.
#' @param proposal A proposal, see *Proposals*.
#' @return A `gloss_proposal`: a list with `outcome`, `stage`, `reasons` (a
#'   character vector, empty when accepted) and `record` (a list when
#'   accepted, else `NULL`). The figure is not changed.
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   library(ggplot2)
#'   fig <- gloss(ggplot(mtcars, aes(wt, mpg)) + geom_point())
#'   b <- gl_bindings(fig)[1, ]
#'   gl_propose(fig, list(kind = "binding", element = b$element, table = b$table, row = b$row))
#'   gl_propose(fig, list(kind = "binding", element = b$element, table = b$table, row = 20L))
#' }
#' @export
gl_propose <- function(fig, proposal) {
  check_proposal(propose_context(fig), proposal)
}

#' @export
print.gloss_proposal <- function(x, ...) {
  if (identical(x$outcome, "accepted")) {
    r <- x$record
    cat(sprintf("<gloss proposal> accepted: %s draws row %d of %s (%s, %s pt off)\n",
                r$element, r$row, r$table, r$status, format(r$dev)))
  } else {
    cat(sprintf("<gloss proposal> %s (%s)\n", x$outcome, x$stage))
    for (r in x$reasons) cat("  ", r, "\n", sep = "")
  }
  invisible(x)
}
