# Binding: the elements of a leaf paired with rows of an engine table, and
# every pairing checked by back-substitution (design §绑定假设; plan
# 2026-11-11-m1-roles-and-binding, Task 2).
#
# An engine's optional `bind(state, substrate)` states pairings. For each
# leaf it can pair it returns the table, the rows in the order the engine
# believes they were drawn, their groups, and where each row must be drawn on
# the device: columns x, y and, when the table has them, xmin, xmax, ymin,
# ymax, xend, yend, all in SVG user units from the top left. The core never
# trusts the order: it reads every element's geometry from the captured scene
# and checks it against the row it was paired with. Which comparison applies
# is decided by the counts (one element per row, or one per group) and the
# element's tag, not by the engine's geom names. When the engine also states
# a row's `fill` (a heatmap cell's colour from its value), the element's fill
# must match it: in a grid of cells the position says only which cell, the
# colour says which value.
#
#   one per row    circle             centre at (x, y)
#                  rect, image        corners at xmin..ymax, else centre at (x, y)
#                  line               ends at (x, y) and (xend, yend)
#                  text               in the label's frame: along the
#                                     baseline at (hjust - anchor) x its
#                                     width from (x, y); across it, (x, y)
#                                     inside the text's box, moved by the
#                                     part of vjust outside 0..1
#                  polygon with       centre of its box at (x, y) moved by
#                  hjust and vjust    (0.5 - hjust) x width, (0.5 - vjust)
#                                     x height, in the row's angle
#                  polyline, path     first vertex at (x, y), last at
#                  with xend, yend    (xend, yend): a segment munched along
#                                     a coord that is not linear, a curve
#                  polygon, polyline,
#                  path               centre (vertex mean) at (x, y)
#   per symbol     a points leaf      each row draws the parts its shape's
#                  whose rows state   symbol draws, in order; each part's
#                  their shape        box holds (x, y) where the symbol puts
#                                     it (the centre; 2/3 or 1/3 down a
#                                     triangle); boxes only, so dense
#                                     leaves bind too
#   one per group  image              its box the bounds of the group's
#                                     cells (a raster over its cells)
#   one per group  polyline, path     vertices at the group's (x, y), in order
#                  polygon            vertices and the group's points
#                                     (x, y), (x, ymin), (x, ymax), (xmin, y),
#                                     (xmax, y) within tolerance of each other
#
# An element is `verified` when its own row passes and no other row of the
# leaf does, `ambiguous` when another row passes too (positions that tie),
# `failed` when its own row does not pass. A leaf that cannot be paired gets
# `unbound` with the reason; a leaf whose counts do not match its grob's
# keeps `count_mismatch` (design §计数对不上就拒绝绑定). Under a coord that is
# not linear, a path one per group is munched along the coord and is
# unbound with that reason; so are polygons and paths whose rows have
# bounds (rectangles munched along it).
#
# Nothing here is stored in the figure: where roles and bindings live is
# plan Task 6 (ADR-0007).

bind_tolerance <- 0.5  # SVG user units, 1/72 in (design §绑定假设: 0.5 px)

# Capture `x` and bind it; internal until ADR-0007. Returns the figure and
# the bindings by element and by leaf.
bind_capture <- function(x, width = 7, height = 5, dense = 10000, engine = NULL) {
  engines <- engine_candidates(x, engine)
  res <- capture_figure(x, engines, width = width, height = height, dense = dense, context = FALSE)
  c(list(fig = res$fig), bind_figure(res$fig, res$engine, res$state))
}

bind_figure <- function(fig, eng, state, tol = bind_tolerance) {
  sub <- fig$substrate
  leaves <- sub$leaves
  geo <- scene_geometry(sub)
  # An engine's bind step may draw again to measure (ggplot's layer children
  # with text): on a null device of its own, never R's default device, which
  # writes Rplots.pdf, or fails where it cannot (then the step would fall back
  # without saying so).
  grDevices::pdf(NULL)
  null_dev <- grDevices::dev.cur()
  on.exit(if (null_dev %in% grDevices::dev.list()) grDevices::dev.off(null_dev), add = TRUE)
  stated <- if (is.null(eng$bind)) {
    list(claims = list(), unbound = data.frame(
      leaf = leaves$id, reason = sprintf("engine '%s' states no bindings", eng$name),
      stringsAsFactors = FALSE))
  } else {
    tryCatch(eng$bind(state, sub), error = function(e) list(claims = list(), unbound = data.frame(
      leaf = leaves$id, reason = paste("the engine's bind step failed:", conditionMessage(e)),
      stringsAsFactors = FALSE)))
  }
  per_leaf <- list()
  per_el <- list()
  for (cl in stated$claims) {
    r <- check_claim(cl, leaves[leaves$id == cl$leaf, , drop = FALSE], geo, tol)
    per_leaf[[cl$leaf]] <- r$leaf
    per_el[[cl$leaf]] <- r$elements
  }
  for (id in setdiff(stated$outside %||% character(), names(per_leaf))) {
    per_leaf[[id]] <- leaf_row(id, status = "outside",
                               reason = "drawn outside the layers (axis, legend, strip, title, panel background or grid)",
                               n_elements = leaves$n_drawn[leaves$id == id])
  }
  ub <- stated$unbound
  if (is.data.frame(ub) && nrow(ub)) {
    ub <- ub[!ub$leaf %in% names(per_leaf) & !duplicated(ub$leaf), , drop = FALSE]
    for (k in seq_len(nrow(ub))) {
      per_leaf[[ub$leaf[k]]] <- leaf_row(ub$leaf[k], status = "unbound", reason = ub$reason[k],
                                         n_elements = leaves$n_drawn[leaves$id == ub$leaf[k]])
    }
  }
  rest <- setdiff(leaves$id, names(per_leaf))
  for (id in rest) {
    per_leaf[[id]] <- leaf_row(id, status = "not_paired", reason = "the engine states no pairing for this leaf",
                               n_elements = leaves$n_drawn[leaves$id == id])
  }
  lv <- do.call(rbind, unname(per_leaf))
  lv <- lv[match(leaves$id, lv$leaf), , drop = FALSE]
  rownames(lv) <- NULL
  el <- if (length(per_el)) do.call(rbind, unname(per_el)) else element_rows(character(), character())
  rownames(el) <- NULL
  mark_copies(list(leaves = lv, elements = el), leaves, geo, sub$elements)
}

# A failed leaf whose elements are those of a passing sibling (same parent,
# same table, the same tags and texts in the same order), all moved by one
# offset, is a copy drawn off its rows on purpose: a halo or a shadow
# (shadowtext draws 16 copies of each label: bench tree-072). It is unbound
# with the offset, not failed: its elements are its sibling's rows. Plan
# 2026-11-11-tree-binding, Task 6.
mark_copies <- function(b, leaves, geo, elements, tol = 0.05) {
  lv <- b$leaves
  bad <- which(lv$status %in% c("failed", "partly_failed"))
  if (!length(bad)) return(b)
  good <- which(lv$status %in% c("verified", "ambiguous"))
  parent <- sub("/[^/]*$", "", leaves$path[match(lv$leaf, leaves$id)])
  shape <- function(id) {
    k <- geo$leaf %in% id
    g <- geo[k, , drop = FALSE]
    g <- g[order(g$ordinal), , drop = FALSE]
    g$text <- elements$text[match(g$id, elements$id)]
    g
  }
  for (i in bad) {
    sib <- good[parent[good] == parent[i] & lv$table[good] %in% lv$table[i] & lv$n_elements[good] == lv$n_elements[i]]
    if (!length(sib)) next
    a <- shape(lv$leaf[i])
    best <- NULL
    for (j in sib) {
      o <- shape(lv$leaf[j])
      if (nrow(o) != nrow(a) || !identical(a$tag, o$tag) || !identical(a$text %in% NA, o$text %in% NA) ||
          !all(a$text == o$text, na.rm = TRUE)) next
      dx <- c(a$x0 - o$x0, a$x1 - o$x1)
      dy <- c(a$y0 - o$y0, a$y1 - o$y1)
      if (anyNA(c(dx, dy)) || diff(range(dx)) > tol || diff(range(dy)) > tol) next
      off <- c(mean(dx), mean(dy))
      if (is.null(best) || sum(off^2) < sum(best$off^2)) best <- list(leaf = lv$leaf[j], off = off)
    }
    if (is.null(best)) next
    lv$status[i] <- "unbound"
    lv$reason[i] <- sprintf("a copy of %s moved by (%.2f, %.2f) pt, element for element (a halo or a shadow?): drawn off its rows",
                            best$leaf, best$off[1], best$off[2])
    lv[i, c("verified", "ambiguous", "failed")] <- 0L
    lv$max_dev[i] <- NA_real_
    k <- b$elements$leaf == lv$leaf[i]
    b$elements$status[k] <- "unbound"
    b$elements$dev[k] <- NA_real_
  }
  b$leaves <- lv
  b
}

leaf_row <- function(leaf, status, reason = NA_character_, table = NA_character_, mode = NA_character_,
                     n_elements = NA_integer_, n_rows = NA_integer_, n_groups = NA_integer_,
                     verified = 0L, ambiguous = 0L, failed = 0L, max_dev = NA_real_) {
  data.frame(leaf = leaf, table = table, mode = mode, status = status,
             n_elements = as.integer(n_elements), n_rows = as.integer(n_rows), n_groups = as.integer(n_groups),
             verified = as.integer(verified), ambiguous = as.integer(ambiguous), failed = as.integer(failed),
             max_dev = as.double(max_dev), reason = reason, stringsAsFactors = FALSE)
}

element_rows <- function(ids, leaf, table = NA_character_, row = NA_integer_, n_rows = NA_integer_,
                         status = character(), dev = NA_real_) {
  n <- length(ids)
  data.frame(element = ids, leaf = rep(leaf, length.out = n), table = rep(table, length.out = n),
             row = rep(as.integer(row), length.out = n), n_rows = rep(as.integer(n_rows), length.out = n),
             status = rep(status, length.out = n), dev = rep(as.double(dev), length.out = n),
             stringsAsFactors = FALSE)
}

# ---- one claim --------------------------------------------------------------

check_claim <- function(cl, leaf, geo, tol = bind_tolerance) {
  r <- check_claim_rows(cl, leaf, geo, tol)
  # a leaf the engine could pair only with all the layer's rows, because it
  # was made when its layer's grob was drawn, is unbound with the engine's
  # reason when that pairing does not pass (plan 2026-11-11-tree-binding,
  # Task 6). A count mismatch was never paired and keeps its own reason.
  if (!is.null(cl$made_reason) && r$leaf$status %in% c("failed", "partly_failed", "unbound")) {
    r$leaf$status <- "unbound"
    r$leaf$reason <- cl$made_reason
    r$leaf[c("verified", "ambiguous", "failed")] <- 0L
    r$leaf$max_dev <- NA_real_
    r$elements$status <- "unbound"
    r$elements$row <- NA_integer_
    r$elements$dev <- NA_real_
  }
  r
}

check_claim_rows <- function(cl, leaf, geo, tol = bind_tolerance) {
  ids <- geo$id[geo$leaf %in% cl$leaf]
  ids <- ids[order(geo$ordinal[match(ids, geo$id)])]
  g <- geo[match(ids, geo$id), , drop = FALSE]
  all_pred <- cl$pred
  pred <- if (!is.null(cl$rows)) all_pred[all_pred$row %in% cl$rows, , drop = FALSE]
          else if (!is.null(cl$groups)) all_pred[all_pred$group %in% cl$groups, , drop = FALSE]
          else all_pred
  n_el <- length(ids)
  n_rows <- nrow(pred)
  groups <- sort(unique(pred$group))
  all_groups <- sort(unique(all_pred$group))
  n_groups <- length(groups)
  base <- list(leaf = cl$leaf, table = cl$table, n_elements = n_el, n_rows = n_rows, n_groups = n_groups)
  done <- function(status, reason, mode = NA_character_, el_status = status) {
    list(leaf = do.call(leaf_row, c(base, list(status = status, reason = reason, mode = mode))),
         elements = element_rows(ids, cl$leaf, cl$table, status = el_status))
  }
  # A text leaf whose elements are all paths was drawn as glyph outlines
  # (showtext: the ggtree book's figures). Outlines are not text, so no
  # comparison here applies; say what they are, whether or not the counts
  # match (plan 2026-11-11-tree-binding, Task 4).
  outlines <- identical(leaf$class, "text") && n_el > 0L && all(g$tag == "path")
  if (outlines) {
    labels <- if (!is.null(pred$label)) pred$label else NULL
    chars <- if (is.null(labels)) NA_integer_ else sum(nchar(gsub("[[:space:]]", "", labels)))
    why <- sprintf("the text was drawn as glyph outlines (showtext?): %d path%s for %d label%s%s; no comparison for outlines",
                   n_el, plural(n_el), n_rows, plural(n_rows),
                   if (is.na(chars)) "" else sprintf(" with %d character%s other than spaces", chars, plural(chars)))
    return(done(if (identical(leaf$status, "count_mismatch")) "count_mismatch" else "unbound", why))
  }
  if (identical(leaf$status, "count_mismatch")) {
    return(done("count_mismatch", sprintf("the leaf drew %d elements, its grob %d", leaf$n_drawn, leaf$n_expected)))
  }
  if (!n_el) return(done("unbound", "the leaf drew no elements"))
  # rows with bounds drawn as polygons or paths under a coord that is not
  # linear: rectangles munched along it, which no comparison here knows
  if (!is.null(cl$rect_reason) && all(g$tag %in% c("polygon", "polyline", "path"))) {
    return(done("unbound", cl$rect_reason))
  }
  # points whose rows state their shape: each row draws its symbol's parts
  # (plan 2026-11-11-tree-binding, Task 5; bench tree-014). Parts are
  # compared by their boxes, which a dense leaf keeps.
  # (grid's points grob, or base's plot.xy())
  symbols <- leaf$class %in% c("points", "plotXY") && "shape" %in% names(pred) && !all(is.na(pred$shape))
  if (!symbols && isTRUE(leaf$dense) && any(!g$tag %in% c("circle", "rect"))) {
    return(done("unbound", "a dense leaf keeps only the boxes of its elements, and its tags need more"))
  }
  mode <- if (symbols) "symbol" else if (n_el == n_rows) "row" else if (n_el == n_groups) "group" else NA_character_
  if (is.na(mode)) {
    return(done("unbound", sprintf("%d element%s for %d row%s in %d group%s: neither one per row nor one per group",
                                   n_el, plural(n_el), n_rows, plural(n_rows), n_groups, plural(n_groups))))
  }
  if (mode == "group" && isFALSE(cl$linear)) {
    # a line through its group's rows is drawn along the coord's arcs, so its
    # vertices are not the rows' points (plan 2026-11-11-tree-binding, Task 3)
    return(done("unbound", sprintf("a path through its group's rows is drawn munched along the coord (%s); no comparison for it",
                                   cl$coord %||% "not linear"), mode))
  }
  res <- switch(mode,
                symbol = check_symbols(g, pred, all_pred, tol),
                row = check_rows(g, pred, all_pred, tol),
                group = check_groups(g, pred, groups, all_pred, all_groups, tol))
  if (!is.null(res$reason)) return(done("unbound", res$reason, mode))
  st <- ifelse(!res$pass, "failed", ifelse(res$n_pass > 1L, "ambiguous", "verified"))
  rows <- switch(mode, symbol = res$rows, row = pred$row,
                 group = vapply(groups, function(k) pred$row[pred$group == k][1], 1L))
  nr <- if (mode == "group") vapply(groups, function(k) sum(pred$group == k), 1L) else 1L
  leaf_status <- if (all(st == "verified")) "verified"
                 else if (all(st == "failed")) "failed"
                 else if (any(st == "failed")) "partly_failed"
                 else "ambiguous"
  dev <- res$dev
  list(
    leaf = do.call(leaf_row, c(base, list(status = leaf_status, mode = mode,
                                          verified = sum(st == "verified"), ambiguous = sum(st == "ambiguous"),
                                          failed = sum(st == "failed"),
                                          max_dev = if (all(is.na(dev))) NA_real_ else max(dev, na.rm = TRUE)))),
    elements = element_rows(ids, cl$leaf, cl$table, row = rows, n_rows = nr, status = st, dev = dev)
  )
}

plural <- function(n) if (n == 1L) "" else "s"

# One row drawn as the parts of its symbol, rows in drawing order: row k's
# parts follow row k-1's (dev_docs/research/point-symbols). A part passes
# when its tag is the one its symbol draws there and its box holds the
# row's point at the share its symbol puts it (centred, or 2/3, 1/3, 3/7,
# 4/7 down a triangle's box); a character drawn as text by the text rule.
# Another row passes too when its point is where the part's box puts this
# one (ambiguous). The rows' shapes say how many parts each draws; when
# they do not add up to the elements, the leaf is not paired part by part.
check_symbols <- function(g, pred, all_pred, tol) {
  kind <- symbol_kind(pred$shape)
  k <- match(kind, names(symbol_parts))
  n_parts <- ifelse(is.na(k), 0L, lengths(symbol_parts)[k])
  if (sum(n_parts) != nrow(g)) {
    return(list(reason = sprintf("the rows' shapes draw %d part%s, the leaf drew %d element%s",
                                 sum(n_parts), plural(sum(n_parts)), nrow(g), plural(nrow(g)))))
  }
  at <- rep(seq_len(nrow(pred)), n_parts)
  want <- unlist(symbol_parts[k[!is.na(k)]], use.names = FALSE)
  fy <- unlist(symbol_fy[k[!is.na(k)]], use.names = FALSE)
  # a circle's centre as the scene writes it (scene_geometry: the box's
  # centre in a dense leaf), as the rule one per row reads it
  circ <- g$tag == "circle"
  px <- ifelse(circ, g$cx, (g$x0 + g$x1) / 2)
  py <- ifelse(circ, g$cy, g$y0 + fy * (g$y1 - g$y0))
  dev <- pmax(abs(px - pred$x[at]), abs(py - pred$y[at]))
  n_pass <- near_count(px, py, all_pred$x, all_pred$y, tol)
  tx <- which(want == "text" & g$tag == "text")
  if (length(tx)) {
    f <- row_family("text", pred)
    ep <- f$element(g[tx, , drop = FALSE])
    dev[tx] <- f$dev(ep, f$row(pred[at[tx], , drop = FALSE]))
    n_pass[tx] <- f$count(ep, f$row(all_pred), tol)
  }
  # A character drawn as a glyph outline (showtext: bench tree-061). R's
  # engine centres a symbol's character on its point by the glyph's metric
  # box, which showtext takes from the outline: across the baseline the
  # outline's box is centred on the point (0.01 pt); along it the side
  # bearings are not on the page (a "j": 0.24-1.36 pt off the centre), so
  # the point need only lie inside the box. dev_docs/research/point-symbols,
  # glyph.R. The vertex mean of an outline is not its point (0.49-10.7 pt).
  gl <- which(want == "text" & g$tag == "path")
  if (length(gl)) {
    cy <- (g$y0[gl] + g$y1[gl]) / 2
    glyph_dev <- function(i, x, y) pmax(abs(cy[i] - y), g$x0[gl[i]] - x, x - g$x1[gl[i]], 0)
    dev[gl] <- glyph_dev(seq_along(gl), pred$x[at[gl]], pred$y[at[gl]])
    reach <- max((g$x1[gl] - g$x0[gl]) / 2, 0, na.rm = TRUE) + tol
    pr <- pairs_within(px[gl], cy, all_pred$x, all_pred$y, reach)
    ok <- glyph_dev(pr$p, all_pred$x[pr$q], all_pred$y[pr$q]) <= tol
    ok[is.na(ok)] <- FALSE
    n_pass[gl] <- tabulate(pr$p[ok], nbins = length(gl))
    want[gl] <- "path"
  }
  pass <- g$tag == want & !is.na(dev) & dev <= tol
  list(pass = pass, dev = dev, n_pass = n_pass, rows = pred$row[at])
}

# One element per row: element k against row k, and how many rows of the
# layer in this panel would pass for element k (more than one: ambiguous).
check_rows <- function(g, pred, all_pred, tol) {
  n <- nrow(g)
  pass <- logical(n)
  dev <- rep(NA_real_, n)
  n_pass <- integer(n)
  for (tag in unique(g$tag)) {
    k <- which(g$tag == tag)
    f <- row_family(tag, pred)
    if (is.null(f)) return(list(reason = sprintf("no comparison for <%s> elements paired one per row", tag)))
    # a layer's rows can lack a position the comparison reads (a boxplot's
    # rows have no y: bench run 2026-11-11-1319, patchwork-012)
    miss <- setdiff(f$cols, names(pred))
    if (length(miss)) {
      return(list(reason = sprintf("the rows paired with <%s> elements have no %s", tag, paste(miss, collapse = ", "))))
    }
    ep <- f$element(g[k, , drop = FALSE])
    if (is.null(ep)) return(list(reason = sprintf("the <%s> elements carry no geometry to compare (rotated text?)", tag)))
    rp <- f$row(pred)
    if (anyNA(rp[k, f$need, drop = FALSE])) {
      return(list(reason = sprintf("rows paired with <%s> elements lack %s", tag, paste(f$need, collapse = ", "))))
    }
    d <- f$dev(ep, rp[k, , drop = FALSE])
    dev[k] <- d
    pass[k] <- d <= tol
    if (!is.null(pred$fill)) pass[k] <- pass[k] & same_colour(g$fill[k], pred$fill[k])
    n_pass[k] <- f$count(ep, f$row(all_pred), tol)
  }
  list(pass = pass, dev = dev, n_pass = n_pass)
}

# Comparisons for one element per row. `element` gives the element's
# geometry, `row` the rows' (from the row columns `cols`), `dev` the
# deviation of element k from row k, `count` how many rows pass for each
# element.
row_family <- function(tag, pred) {
  centre <- function(e) data.frame(x = (e$x0 + e$x1) / 2, y = (e$y0 + e$y1) / 2)
  at_xy <- function(p) data.frame(x = p$x, y = p$y)
  point_dev <- function(e, r) pmax(abs(e$x - r$x), abs(e$y - r$y))
  point_count <- function(e, r, tol) near_count(e$x, e$y, r$x, r$y, tol)
  has <- function(cols) all(cols %in% names(pred)) && !all(is.na(pred[cols]))
  if (tag == "circle") {
    return(list(need = c("x", "y"), cols = c("x", "y"), element = function(e) data.frame(x = e$cx, y = e$cy),
                row = at_xy, dev = point_dev, count = point_count))
  }
  # an <image> is placed by its box as a rect is (ggimage's rasterGrob,
  # centred on its row; a raster over a cell's bounds)
  if (tag %in% c("rect", "image") && has(c("xmin", "xmax", "ymin", "ymax"))) {
    corners <- function(x0, x1, y0, y1) data.frame(x0 = pmin(x0, x1), x1 = pmax(x0, x1), y0 = pmin(y0, y1), y1 = pmax(y0, y1))
    return(list(need = c("x0", "x1", "y0", "y1"), cols = c("xmin", "xmax", "ymin", "ymax"),
                element = function(e) corners(e$x0, e$x1, e$y0, e$y1),
                row = function(p) corners(p$xmin, p$xmax, p$ymin, p$ymax),
                dev = function(e, r) pmax(abs(e$x0 - r$x0), abs(e$x1 - r$x1), abs(e$y0 - r$y0), abs(e$y1 - r$y1)),
                count = function(e, r, tol) {
                  # rows whose centre is near, and whose corners pass too (centres tie while sizes differ)
                  pr <- pairs_within((e$x0 + e$x1) / 2, (e$y0 + e$y1) / 2, (r$x0 + r$x1) / 2, (r$y0 + r$y1) / 2, tol)
                  ok <- pmax(abs(e$x0[pr$p] - r$x0[pr$q]), abs(e$x1[pr$p] - r$x1[pr$q]),
                             abs(e$y0[pr$p] - r$y0[pr$q]), abs(e$y1[pr$p] - r$y1[pr$q])) <= tol
                  tabulate(pr$p[ok], nbins = nrow(e))
                }))
  }
  if (tag == "line") {
    if (!has(c("xend", "yend"))) return(NULL)
    return(list(need = c("x", "y", "xend", "yend"), cols = c("x", "y", "xend", "yend"),
                element = function(e) data.frame(x = e$lx1, y = e$ly1, xend = e$lx2, yend = e$ly2),
                row = function(p) data.frame(x = p$x, y = p$y, xend = p$xend, yend = p$yend),
                dev = function(e, r) pmax(abs(e$x - r$x), abs(e$y - r$y), abs(e$xend - r$xend), abs(e$yend - r$yend)),
                count = function(e, r, tol) {
                  pr <- pairs_within(e$x, e$y, r$x, r$y, tol)
                  ok <- abs(e$xend[pr$p] - r$xend[pr$q]) <= tol & abs(e$yend[pr$p] - r$yend[pr$q]) <= tol
                  ok[is.na(ok)] <- FALSE
                  tabulate(pr$p[ok], nbins = nrow(e))
                }))
  }
  if (tag == "text") {
    # R's engine (GEText) places a text from its row in the text's own
    # frame: along the baseline by (hjust - the anchor svglite writes as
    # text-anchor) times the width R measured, which svglite writes as
    # textLength; across it by vjust times the ascent of "M" on the device.
    # Along the baseline the check is exact (a hand drawing, 120 cases of
    # hjust, vjust and angle: within 0.005 pt). Across it the row must lie
    # inside the text's box, as before: a label's text sits by its margins
    # and descent (ggplot2's labelGrob), not by vjust alone. The part of
    # vjust outside 0..1 moves the text off its row by that share of the
    # ascent, so the box is moved by it (ggtree's labels, vjust = -.5:
    # bench tree-062; plan 2026-11-11-tree-binding, Task 2). A row that
    # states no justification is taken as justified where svglite anchored.
    return(list(need = c("x", "y"), cols = c("x", "y"),
                element = text_frame,
                row = function(p) data.frame(x = p$x, y = p$y, hjust = col_or(p, "hjust", NA_real_),
                                             vjust = col_or(p, "vjust", NA_real_)),
                dev = text_dev,
                count = function(e, r, tol) {
                  pr <- pairs_within(e$ax, e$ay, r$x, r$y, text_reach(e, r) + tol)
                  ok <- text_dev(e[pr$p, , drop = FALSE], r[pr$q, , drop = FALSE]) <= tol
                  ok[is.na(ok)] <- FALSE
                  tabulate(pr$p[ok], nbins = nrow(e))
                }))
  }
  # A label's box (ggplot2's labelGrob): its centre is the row moved by
  # (0.5 - hjust) of its width and (0.5 - vjust) of its height, in the
  # row's angle. The vertex mean of a rounded rectangle is not its centre:
  # bench tree-041 and tree-045, boxes 0.67-0.74 pt off with hjust = .5.
  # An image whose rows state a justification is placed the same way, as
  # grid justifies a rasterGrob (ggimage's tip images, hjust = 0: bench
  # tree-041). ggimage moves an image only for hjust 0 and 1 and centres it
  # for any other value; such an image would fail here.
  if ((tag == "polygon" && has(c("hjust", "vjust"))) || (tag == "image" && (has("hjust") || has("vjust")))) {
    return(list(need = c("x", "y"), cols = c("x", "y"),
                element = function(e) e,
                row = function(p) data.frame(x = p$x, y = p$y, hjust = col_or(p, "hjust", 0.5),
                                             vjust = col_or(p, "vjust", 0.5), angle = col_or(p, "angle", 0)),
                dev = box_dev,
                count = function(e, r, tol) {
                  size <- max(e$x1 - e$x0, e$y1 - e$y0, na.rm = TRUE)
                  off <- max(abs(c(r$hjust, r$vjust) - 0.5), 0.5, na.rm = TRUE)
                  pr <- pairs_within((e$x0 + e$x1) / 2, (e$y0 + e$y1) / 2, r$x, r$y, (off + 0.5) * size + tol)
                  ok <- box_dev(e[pr$p, , drop = FALSE], r[pr$q, , drop = FALSE]) <= tol
                  ok[is.na(ok)] <- FALSE
                  tabulate(pr$p[ok], nbins = nrow(e))
                }))
  }
  if (tag %in% c("rect", "image")) {
    return(list(need = c("x", "y"), cols = c("x", "y"), element = centre, row = at_xy, dev = point_dev, count = point_count))
  }
  if (tag %in% c("polyline", "path") && has(c("xend", "yend"))) {
    # A segment drawn as a path: munched along a coord that is not linear
    # (coord_polar(): bench tree-025, -038, -057), or a curve (geom_curve()).
    # Its first vertex is the row's start, its last the row's end.
    ends <- function(e) {
      v <- e$vertices
      if (any(vapply(v, is.null, logical(1)))) return(NULL)
      data.frame(x = vapply(v, function(m) m[1, 1], 1), y = vapply(v, function(m) m[1, 2], 1),
                 xend = vapply(v, function(m) m[nrow(m), 1], 1), yend = vapply(v, function(m) m[nrow(m), 2], 1))
    }
    return(list(need = c("x", "y", "xend", "yend"), cols = c("x", "y", "xend", "yend"),
                element = ends,
                row = function(p) data.frame(x = p$x, y = p$y, xend = p$xend, yend = p$yend),
                dev = function(e, r) pmax(abs(e$x - r$x), abs(e$y - r$y), abs(e$xend - r$xend), abs(e$yend - r$yend)),
                count = function(e, r, tol) {
                  pr <- pairs_within(e$x, e$y, r$x, r$y, tol)
                  ok <- abs(e$xend[pr$p] - r$xend[pr$q]) <= tol & abs(e$yend[pr$p] - r$yend[pr$q]) <= tol
                  ok[is.na(ok)] <- FALSE
                  tabulate(pr$p[ok], nbins = nrow(e))
                }))
  }
  if (tag %in% c("polygon", "polyline", "path")) {
    # A point symbol drawn as a polygon (a triangle) is centred on its vertex
    # mean, not on its box; so is a hexagon.
    vmean <- function(e) {
      m <- t(vapply(seq_len(nrow(e)), function(i) {
        v <- e$vertices[[i]]
        if (is.null(v)) c((e$x0[i] + e$x1[i]) / 2, (e$y0[i] + e$y1[i]) / 2) else colMeans(v)
      }, numeric(2)))
      data.frame(x = m[, 1], y = m[, 2])
    }
    return(list(need = c("x", "y"), cols = c("x", "y"), element = vmean, row = at_xy, dev = point_dev, count = point_count))
  }
  NULL
}

col_or <- function(p, col, default) {
  v <- if (col %in% names(p)) as.double(p[[col]]) else rep(NA_real_, nrow(p))
  v[is.na(v)] <- default
  v
}

# A text element in its own frame: anchor (ax, ay), angle (R's, counter-
# clockwise), the anchor svglite wrote (ha: 0, 0.5, 1), width W, font size
# fs and the device's ascent of "M" for its font, H.
text_frame <- function(e) {
  data.frame(ax = e$ax, ay = e$ay, theta = e$angle, ha = e$hadj, W = e$tlen, fs = e$fsize,
             H = text_m_ascent(e$font, e$fsize))
}

# Deviation of text element i from row i (rows in device units, y down).
text_dev <- function(e, r) {
  hj <- ifelse(is.na(r$hjust), e$ha, r$hjust)
  vj <- r$vjust
  ex <- ifelse(is.na(vj), 0, vj - pmin(pmax(vj, 0), 1))
  shift <- ifelse(ex == 0, 0, ex * e$H)
  th <- e$theta * pi / 180
  dx <- r$x - e$ax
  dy <- e$ay - r$y
  du <- cos(th) * dx + sin(th) * dy
  dv <- -sin(th) * dx + cos(th) * dy
  along <- abs(du - (hj - e$ha) * e$W)
  across <- pmax(-0.2 * e$fs + shift - dv, dv - 0.8 * e$fs - shift, 0)
  pmax(along, across)
}

# How far from its anchor a text's row can lie and still pass.
text_reach <- function(e, r) {
  hj <- r$hjust[!is.na(r$hjust)]
  vj <- r$vjust[!is.na(r$vjust)]
  dh <- if (length(hj)) max(abs(c(hj - min(e$ha), hj - max(e$ha)))) else 0
  ex <- if (length(vj)) max(abs(vj - pmin(pmax(vj, 0), 1))) else 0
  max(dh * e$W + 0.8 * e$fs + ex * e$H, 0, na.rm = TRUE) + 1
}

# Deviation of a box element i from row i, in the row's angle.
box_dev <- function(e, r) {
  vapply(seq_len(nrow(e)), function(i) {
    th <- r$angle[i] * pi / 180
    v <- e$vertices[[i]]
    if (is.null(v)) v <- cbind(c(e$x0[i], e$x1[i]), c(e$y0[i], e$y1[i]))
    u <- cos(th) * v[, 1] - sin(th) * v[, 2]
    w <- -sin(th) * v[, 1] - cos(th) * v[, 2]
    ur <- cos(th) * r$x[i] - sin(th) * r$y[i]
    wr <- -sin(th) * r$x[i] - cos(th) * r$y[i]
    wb <- diff(range(u))
    hb <- diff(range(w))
    max(abs(mean(range(u)) - ur - (0.5 - r$hjust[i]) * wb), abs(mean(range(w)) - wr - (0.5 - r$vjust[i]) * hb))
  }, 1)
}

# The ascent of "M" on svglite for a font and size: what R's engine moves a
# one-line text by for its vertical justification (GEStrHeight). Measured on
# the device gloss captures with, once per font and size in a session.
m_ascent_cache <- new.env(parent = emptyenv())

text_m_ascent <- function(font, size) {
  key <- paste(font, sprintf("%.2f", size))
  out <- rep(NA_real_, length(key))
  for (k in unique(key[!is.na(size)])) {
    if (is.null(m_ascent_cache[[k]])) {
      i <- match(k, key)
      m_ascent_cache[[k]] <- tryCatch(measure_m_ascent(font[i], size[i]), error = function(e) NA_real_)
    }
    out[key == k] <- m_ascent_cache[[k]]
  }
  out
}

measure_m_ascent <- function(font, size) {
  part <- strsplit(font, "|", fixed = TRUE)[[1]]
  family <- gsub("^[\"']|[\"']$", "", part[1])
  if (is.na(family) || family == "NA") family <- ""
  face <- 1L + identical(part[2], "bold") + 2L * identical(part[3], "italic")
  prev <- grDevices::dev.cur()
  svglite::svgstring(width = 2, height = 2)
  dev <- grDevices::dev.cur()
  on.exit({
    grDevices::dev.off(dev)
    if (prev > 1L && prev %in% grDevices::dev.list()) grDevices::dev.set(prev)
  }, add = TRUE)
  graphics::plot.new()
  graphics::par(family = family, ps = 12)
  graphics::strheight("M", units = "inches", cex = size / 12, font = face) * pt_per_in
}

# One element per group: element k against the k-th group, groups sorted
# as ggplot2 and grid draw them (factor order of the group ids); ambiguity
# against every group of the layer in this panel.
check_groups <- function(g, pred, groups, all_pred, all_groups, tol) {
  if (nrow(g) && all(g$tag == "image")) return(check_image_groups(g, pred, groups, all_pred, all_groups, tol))
  n <- nrow(g)
  verts <- g$vertices
  if (any(!g$tag %in% c("polyline", "polygon", "path"))) {
    return(list(reason = sprintf("no comparison for <%s> elements paired one per group",
                                 paste(unique(g$tag[!g$tag %in% c("polyline", "polygon", "path")]), collapse = ", "))))
  }
  if (any(vapply(verts, is.null, logical(1)))) {
    return(list(reason = "some elements have no vertex list (a dense leaf, or a path with curves)"))
  }
  own <- lapply(groups, function(k) pred[pred$group == k, , drop = FALSE])
  by_group <- lapply(all_groups, function(k) all_pred[all_pred$group == k, , drop = FALSE])
  ordered <- g$tag %in% c("polyline", "path") & !g$closed
  cmp_rows <- function(i, b) {
    if (ordered[i]) path_dev(verts[[i]], b) else polygon_dev(verts[[i]], b)
  }
  dev <- vapply(seq_len(n), function(i) cmp_rows(i, own[[i]]), 1)
  self_at <- match(groups, all_groups)
  pass <- dev <= tol
  pass[is.na(pass)] <- FALSE
  # Other groups that would pass as well: only groups with a point near the
  # element's first vertex can.
  first <- t(vapply(verts, function(v) v[1, ], numeric(2)))
  gi <- match(all_pred$group, all_groups)
  px <- c(all_pred$x, if (!is.null(all_pred$ymin)) all_pred$x, if (!is.null(all_pred$ymax)) all_pred$x)
  py <- c(all_pred$y, all_pred$ymin, all_pred$ymax)
  pg <- rep(gi, length.out = length(px))
  pr <- pairs_within(first[, 1], first[, 2], px, py, tol)
  cand <- split(pg[pr$q], factor(pr$p, levels = seq_len(n)))
  n_pass <- vapply(seq_len(n), function(i) {
    if (!pass[i]) return(0L)
    others <- setdiff(unique(cand[[i]]), self_at[i])
    1L + sum(vapply(others, function(j) isTRUE(cmp_rows(i, by_group[[j]]) <= tol), logical(1)))
  }, 1L)
  list(pass = pass, dev = dev, n_pass = n_pass)
}

# One image per group (geom_raster(): one raster over all its cells): the
# image's box is the bounds of the group's cells (plan
# 2026-11-11-tree-binding, Task 6; v0 gallery-015).
check_image_groups <- function(g, pred, groups, all_pred, all_groups, tol) {
  b <- c("xmin", "xmax", "ymin", "ymax")
  if (!all(b %in% names(pred)) || all(is.na(pred[b]))) {
    return(list(reason = "an <image> paired one per group is compared with its rows' cell bounds (xmin, xmax, ymin, ymax), which the rows do not have"))
  }
  bounds <- function(d) c(min(d$xmin, d$xmax, na.rm = TRUE), max(d$xmin, d$xmax, na.rm = TRUE),
                          min(d$ymin, d$ymax, na.rm = TRUE), max(d$ymin, d$ymax, na.rm = TRUE))
  box_dev <- function(i, bb) max(abs(c(g$x0[i], g$x1[i], g$y0[i], g$y1[i]) - bb))
  own <- lapply(groups, function(k) bounds(pred[pred$group == k, , drop = FALSE]))
  every <- lapply(all_groups, function(k) bounds(all_pred[all_pred$group == k, , drop = FALSE]))
  dev <- vapply(seq_len(nrow(g)), function(i) box_dev(i, own[[i]]), 1)
  pass <- !is.na(dev) & dev <= tol
  n_pass <- vapply(seq_len(nrow(g)), function(i) sum(vapply(every, function(bb) isTRUE(box_dev(i, bb) <= tol), logical(1))), 1L)
  list(pass = pass, dev = dev, n_pass = n_pass)
}

# Ordered vertices against the group's rows, after dropping rows with a
# missing position: the line through (x, y), or, for a ribbon or an area,
# its outline through (x, ymax) or (x, ymin) (bench gallery-024: an area's
# outline runs along ymax, which a stacked area's y is not); the smallest
# deviation of the lines the rows define. Rows the engine marks as padding
# (`pad`) may be left out of an outline, as ggplot2 leaves them out.
path_dev <- function(v, b) {
  lines <- list(c("x", "y"), c("x", "ymax"), c("x", "ymin"), c("xmax", "y"), c("xmin", "y"))
  pad <- if (is.null(b$pad)) NULL else b$pad
  one <- function(xs, ys, keep) {
    ok <- keep & !is.na(xs) & !is.na(ys)
    if (nrow(v) != sum(ok)) return(Inf)
    max(abs(v[, 1] - xs[ok]), abs(v[, 2] - ys[ok]))
  }
  devs <- vapply(lines, function(cols) {
    if (!all(cols %in% names(b))) return(Inf)
    xs <- b[[cols[1]]]
    ys <- b[[cols[2]]]
    d <- one(xs, ys, rep(TRUE, length(xs)))
    if (!is.null(pad) && any(pad)) d <- min(d, one(xs, ys, !pad))
    d
  }, 1)
  min(devs)
}

# Polygon vertices and the group's points within tolerance of each other,
# both ways (the order in which a geom walks its rows is the geom's own).
polygon_dev <- function(v, b) {
  pts <- rbind(cbind(b$x, b$y),
               if (!is.null(b$ymin)) cbind(b$x, b$ymin), if (!is.null(b$ymax)) cbind(b$x, b$ymax),
               if (!is.null(b$xmin)) cbind(b$xmin, b$y), if (!is.null(b$xmax)) cbind(b$xmax, b$y))
  pts <- pts[stats::complete.cases(pts), , drop = FALSE]
  if (!nrow(pts) || !nrow(v)) return(Inf)
  # every vertex is near some point of the group
  a <- nearest_dist(v[, 1], v[, 2], pts[, 1], pts[, 2])
  # every point the group would draw is near some vertex; points that are
  # alternatives (y and ymax at the same x) need only one of them drawn
  b_side <- nearest_dist(b$x, b$y, v[, 1], v[, 2])
  if (!is.null(b$ymin) && !is.null(b$ymax) && !all(is.na(b$ymin))) {
    lo <- nearest_dist(b$x, b$ymin, v[, 1], v[, 2])
    hi <- nearest_dist(b$x, b$ymax, v[, 1], v[, 2])
    b_side <- pmax(lo, hi)
  } else if (!is.null(b$xmin) && !is.null(b$xmax) && !all(is.na(b$xmin))) {
    lo <- nearest_dist(b$xmin, b$y, v[, 1], v[, 2])
    hi <- nearest_dist(b$xmax, b$y, v[, 1], v[, 2])
    b_side <- pmax(lo, hi)
  }
  max(a, b_side, na.rm = TRUE)
}

# Pairs (p, q) with q within `tol` of p (Chebyshev distance), found through
# square cells `tol` wide: each p looks only into its own and the 8
# neighbouring cells, so 10^5 points stay near linear.
pairs_within <- function(px, py, qx, qy, tol) {
  empty <- list(p = integer(), q = integer())
  okp <- which(!is.na(px) & !is.na(py) & is.finite(px) & is.finite(py))
  okq <- which(!is.na(qx) & !is.na(qy) & is.finite(qx) & is.finite(qy))
  if (!length(okp) || !length(okq)) return(empty)
  cell <- max(tol, 1e-6)
  pi <- floor(px[okp] / cell)
  pj <- floor(py[okp] / cell)
  qi <- floor(qx[okq] / cell)
  qj <- floor(qy[okq] / cell)
  i0 <- min(pi, qi) - 1
  j0 <- min(pj, qj) - 1
  w <- max(pj, qj) - j0 + 2
  kq <- (qi - i0) * w + (qj - j0)
  o <- order(kq)
  kq <- kq[o]
  out_p <- list()
  out_q <- list()
  for (di in -1:1) for (dj in -1:1) {
    kp <- (pi + di - i0) * w + (pj + dj - j0)
    lo <- findInterval(kp - 0.5, kq) + 1L
    hi <- findInterval(kp + 0.5, kq)
    cnt <- pmax(hi - lo + 1L, 0L)
    if (!sum(cnt)) next
    a <- rep(seq_along(kp), cnt)
    b <- o[sequence(cnt[cnt > 0L], from = lo[cnt > 0L])]
    hit <- abs(qx[okq][b] - px[okp][a]) <= tol & abs(qy[okq][b] - py[okp][a]) <= tol
    out_p[[length(out_p) + 1L]] <- okp[a[hit]]
    out_q[[length(out_q) + 1L]] <- okq[b[hit]]
  }
  list(p = unlist(out_p, use.names = FALSE) %||% integer(), q = unlist(out_q, use.names = FALSE) %||% integer())
}

# For each point p, how many points q lie within `tol`.
near_count <- function(px, py, qx, qy, tol) {
  pr <- pairs_within(px, py, qx, qy, tol)
  tabulate(pr$p, nbins = length(px))
}

# Chebyshev distance from each point p to the nearest point q. Exact when
# the pairs are few; otherwise exact within `cap` and Inf beyond it, which
# is all a check against a tolerance below `cap` needs.
nearest_dist <- function(px, py, qx, qy, cap = 4 * bind_tolerance) {
  ok <- !is.na(qx) & !is.na(qy)
  qx <- qx[ok]
  qy <- qy[ok]
  if (!length(qx)) return(rep(Inf, length(px)))
  if (as.double(length(px)) * length(qx) <= 4e5) {
    return(vapply(seq_along(px), function(i) {
      if (is.na(px[i]) || is.na(py[i])) return(NA_real_)
      min(pmax(abs(qx - px[i]), abs(qy - py[i])))
    }, 1))
  }
  pr <- pairs_within(px, py, qx, qy, cap)
  out <- rep(Inf, length(px))
  out[is.na(px) | is.na(py)] <- NA_real_
  if (length(pr$p)) {
    d <- pmax(abs(qx[pr$q] - px[pr$p]), abs(qy[pr$q] - py[pr$p]))
    m <- tapply(d, pr$p, min)
    out[as.integer(names(m))] <- m
  }
  out
}

# ---- geometry from the scene ------------------------------------------------

# Every element of the substrate with the geometry its tag carries in the
# scene: circle centres, line ends, text anchors, vertex lists. Elements of a
# dense leaf are not in the scene (a raster stands in their place); they keep
# their boxes, which give circle centres and rect corners.
scene_geometry <- function(sub) {
  el <- sub$elements
  n <- nrow(el)
  out <- data.frame(id = el$id, leaf = el$leaf, tag = el$tag, ordinal = el$ordinal,
                    x0 = el$x0, y0 = el$y0, x1 = el$x1, y1 = el$y1,
                    cx = (el$x0 + el$x1) / 2, cy = (el$y0 + el$y1) / 2,
                    lx1 = NA_real_, ly1 = NA_real_, lx2 = NA_real_, ly2 = NA_real_,
                    ax = NA_real_, ay = NA_real_, angle = 0, hadj = NA_real_, tlen = NA_real_,
                    fsize = NA_real_, font = NA_character_, rotated = FALSE, closed = el$tag == "polygon",
                    fill = el$fill, stringsAsFactors = FALSE)
  out$vertices <- vector("list", n)
  if (!n) return(out)
  doc <- read_page(sub$scene)
  ns <- svg_ns(doc)
  nodes <- xml2::xml_find_all(doc, prim_xpath(), ns)
  owner <- xml2::xml_attr(xml2::xml_find_first(nodes, "ancestor::d1:g[@data-gloss-leaf][1]", ns), "data-gloss-leaf")
  ord <- stats_ave_seq(owner)
  at <- match(paste(owner, ord), paste(el$leaf, el$ordinal))
  keep <- !is.na(owner) & !is.na(at)
  nodes <- nodes[keep]
  at <- at[keep]
  tag <- xml2::xml_name(nodes)
  for (t in unique(tag)) {
    k <- which(tag == t)
    nd <- nodes[k]
    i <- at[k]
    if (t == "circle") {
      out$cx[i] <- num_attr(nd, "cx")
      out$cy[i] <- num_attr(nd, "cy")
    } else if (t == "line") {
      out$lx1[i] <- num_attr(nd, "x1")
      out$ly1[i] <- num_attr(nd, "y1")
      out$lx2[i] <- num_attr(nd, "x2")
      out$ly2[i] <- num_attr(nd, "y2")
    } else if (t == "text") {
      # anchor, angle and the anchor svglite wrote, the width R measured
      # (textLength) and the font: the label's frame (row_family)
      tr <- xml2::xml_attr(nd, "transform")
      x <- num_attr(nd, "x")
      y <- num_attr(nd, "y")
      x[is.na(x)] <- 0
      y[is.na(y)] <- 0
      has_tr <- !is.na(tr)
      if (any(has_tr)) {
        tt <- regmatches(tr[has_tr], regexec("translate\\(\\s*([-0-9.eE]+)[ ,]+([-0-9.eE]+)\\s*\\)", tr[has_tr]))
        rr <- regmatches(tr[has_tr], regexec("rotate\\(\\s*([-0-9.eE]+)", tr[has_tr]))
        x[has_tr] <- x[has_tr] + vapply(tt, function(v) if (length(v) == 3L) as.numeric(v[2]) else 0, 1)
        y[has_tr] <- y[has_tr] + vapply(tt, function(v) if (length(v) == 3L) as.numeric(v[3]) else 0, 1)
        # svglite writes rotate(-rot) for R's counter-clockwise rot
        out$angle[i[has_tr]] <- -vapply(rr, function(v) if (length(v) == 2L) as.numeric(v[2]) else 0, 1)
      }
      out$rotated[i] <- out$angle[i] != 0
      out$ax[i] <- x
      out$ay[i] <- y
      anchor <- xml2::xml_attr(nd, "text-anchor")
      out$hadj[i] <- ifelse(is.na(anchor), 0, ifelse(anchor == "middle", 0.5, ifelse(anchor == "end", 1, 0)))
      st <- xml2::xml_attr(nd, "style")
      fs <- suppressWarnings(as.numeric(sub("px$", "", style_value(st, "font-size"))))
      fs[is.na(fs)] <- 12
      out$fsize[i] <- fs
      out$font[i] <- paste(style_value(st, "font-family"), style_value(st, "font-weight"),
                           style_value(st, "font-style"), sep = "|")
      w <- num_attr(nd, "textLength")
      # as text_boxes() estimates a width svglite did not write
      w[is.na(w)] <- 0.6 * fs[is.na(w)] * nchar(xml2::xml_text(nd[is.na(w)]))
      out$tlen[i] <- w
    } else if (t %in% c("polyline", "polygon")) {
      out$vertices[i] <- lapply(xml2::xml_attr(nd, "points"), parse_points)
    } else if (t == "path") {
      d <- xml2::xml_attr(nd, "d")
      out$vertices[i] <- lapply(d, parse_path_lines)
      out$closed[i] <- grepl("[Zz]\\s*$", d)
    }
  }
  out
}

parse_points <- function(s) {
  v <- suppressWarnings(as.numeric(strsplit(trimws(s), "[ ,]+")[[1]]))
  if (!length(v) || anyNA(v) || length(v) %% 2L) return(NULL)
  matrix(v, ncol = 2L, byrow = TRUE)
}

# Vertices of a path made only of M, L and Z commands; NULL for curves.
parse_path_lines <- function(d) {
  if (is.na(d) || grepl("[^MLZmlz0-9eE.,+ \\-]", d)) return(NULL)
  if (grepl("[mlz]", d)) return(NULL)  # relative commands: not written by svglite
  v <- suppressWarnings(as.numeric(strsplit(trimws(gsub("[MLZ]", " ", d)), "[ ,]+")[[1]]))
  v <- v[!is.na(v)]
  if (!length(v) || length(v) %% 2L) return(NULL)
  matrix(v, ncol = 2L, byrow = TRUE)
}

# Two colours as svglite writes them and as R names them, compared on RGB.
same_colour <- function(a, b) {
  rgb <- function(v) {
    out <- rep(NA_character_, length(v))
    ok <- !is.na(v) & nzchar(v) & v != "none"
    out[ok] <- tryCatch(toupper(substr(grDevices::rgb(t(grDevices::col2rgb(v[ok])), maxColorValue = 255), 1, 7)),
                        error = function(e) NA_character_)
    out
  }
  x <- rgb(a)
  y <- rgb(b)
  !is.na(x) & !is.na(y) & x == y
}
