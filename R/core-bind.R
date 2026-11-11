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
#                  rect               corners at xmin..ymax, else centre at (x, y)
#                  line               ends at (x, y) and (xend, yend)
#                  text               anchor x at x; y inside the text's box
#                  polygon, polyline,
#                  path               centre of its box at (x, y)
#   one per group  polyline, path     vertices at the group's (x, y), in order
#                  polygon            vertices and the group's points
#                                     (x, y), (x, ymin), (x, ymax), (xmin, y),
#                                     (xmax, y) within tolerance of each other
#
# An element is `verified` when its own row passes and no other row of the
# leaf does, `ambiguous` when another row passes too (positions that tie),
# `failed` when its own row does not pass. A leaf that cannot be paired gets
# `unbound` with the reason; a leaf whose counts do not match its grob's
# keeps `count_mismatch` (design §计数对不上就拒绝绑定).
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
  list(leaves = lv, elements = el)
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
  ids <- geo$id[geo$leaf %in% cl$leaf]
  ids <- ids[order(geo$ordinal[match(ids, geo$id)])]
  g <- geo[match(ids, geo$id), , drop = FALSE]
  all_pred <- cl$pred
  pred <- if (is.null(cl$groups)) all_pred else all_pred[all_pred$group %in% cl$groups, , drop = FALSE]
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
  if (identical(leaf$status, "count_mismatch")) {
    return(done("count_mismatch", sprintf("the leaf drew %d elements, its grob %d", leaf$n_drawn, leaf$n_expected)))
  }
  if (!n_el) return(done("unbound", "the leaf drew no elements"))
  if (isTRUE(leaf$dense) && any(!g$tag %in% c("circle", "rect"))) {
    return(done("unbound", "a dense leaf keeps only the boxes of its elements, and its tags need more"))
  }
  mode <- if (n_el == n_rows) "row" else if (n_el == n_groups) "group" else NA_character_
  if (is.na(mode)) {
    return(done("unbound", sprintf("%d element%s for %d row%s in %d group%s: neither one per row nor one per group",
                                   n_el, plural(n_el), n_rows, plural(n_rows), n_groups, plural(n_groups))))
  }
  res <- if (mode == "row") check_rows(g, pred, all_pred, tol) else check_groups(g, pred, groups, all_pred, all_groups, tol)
  if (!is.null(res$reason)) return(done("unbound", res$reason, mode))
  st <- ifelse(!res$pass, "failed", ifelse(res$n_pass > 1L, "ambiguous", "verified"))
  rows <- if (mode == "row") pred$row else vapply(groups, function(k) pred$row[pred$group == k][1], 1L)
  nr <- if (mode == "row") 1L else vapply(groups, function(k) sum(pred$group == k), 1L)
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
# geometry, `row` the rows', `dev` the deviation of element k from row k,
# `count` how many rows pass for each element.
row_family <- function(tag, pred) {
  centre <- function(e) data.frame(x = (e$x0 + e$x1) / 2, y = (e$y0 + e$y1) / 2)
  at_xy <- function(p) data.frame(x = p$x, y = p$y)
  point_dev <- function(e, r) pmax(abs(e$x - r$x), abs(e$y - r$y))
  point_count <- function(e, r, tol) near_count(e$x, e$y, r$x, r$y, tol)
  has <- function(cols) all(cols %in% names(pred)) && !all(is.na(pred[cols]))
  if (tag == "circle") {
    return(list(need = c("x", "y"), element = function(e) data.frame(x = e$cx, y = e$cy),
                row = at_xy, dev = point_dev, count = point_count))
  }
  if (tag == "rect" && has(c("xmin", "xmax", "ymin", "ymax"))) {
    corners <- function(x0, x1, y0, y1) data.frame(x0 = pmin(x0, x1), x1 = pmax(x0, x1), y0 = pmin(y0, y1), y1 = pmax(y0, y1))
    return(list(need = c("x0", "x1", "y0", "y1"),
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
    return(list(need = c("x", "y", "xend", "yend"),
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
    # The anchor's x is the row's x (svglite writes text-anchor for the
    # horizontal justification). Vertical justification moves the baseline
    # by a share of the text's height, so y is checked against the text box.
    return(list(need = c("x", "y"),
                element = function(e) if (any(e$rotated)) NULL else data.frame(x = e$ax, y0 = e$y0, y1 = e$y1),
                row = at_xy,
                dev = function(e, r) {
                  dy <- pmax(e$y0 - r$y, r$y - e$y1, 0)
                  pmax(abs(e$x - r$x), dy)
                },
                count = function(e, r, tol) {
                  # rows with the anchor's x: pairs on x alone, then the box on y
                  pr <- pairs_within(e$x, rep(0, nrow(e)), r$x, rep(0, nrow(r)), tol)
                  ok <- r$y[pr$q] >= e$y0[pr$p] - tol & r$y[pr$q] <= e$y1[pr$p] + tol
                  ok[is.na(ok)] <- FALSE
                  tabulate(pr$p[ok], nbins = nrow(e))
                }))
  }
  if (tag == "rect") {
    return(list(need = c("x", "y"), element = centre, row = at_xy, dev = point_dev, count = point_count))
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
    return(list(need = c("x", "y"), element = vmean, row = at_xy, dev = point_dev, count = point_count))
  }
  NULL
}

# One element per group: element k against the k-th group, groups sorted
# as ggplot2 and grid draw them (factor order of the group ids); ambiguity
# against every group of the layer in this panel.
check_groups <- function(g, pred, groups, all_pred, all_groups, tol) {
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

# Ordered vertices against the group's (x, y) rows, after dropping rows
# with a missing position.
path_dev <- function(v, b) {
  ok <- !is.na(b$x) & !is.na(b$y)
  b <- b[ok, , drop = FALSE]
  if (nrow(v) != nrow(b)) return(Inf)
  max(abs(v[, 1] - b$x), abs(v[, 2] - b$y))
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
                    ax = NA_real_, rotated = FALSE, closed = el$tag == "polygon",
                    fill = el$fill, stringsAsFactors = FALSE)
  out$vertices <- vector("list", n)
  if (!n) return(out)
  doc <- xml2::read_xml(sub$scene)
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
      tr <- xml2::xml_attr(nd, "transform")
      out$rotated[i] <- !is.na(tr) & grepl("rotate", tr, fixed = TRUE)
      out$ax[i] <- num_attr(nd, "x")
      tx <- !is.na(tr) & !out$rotated[i] & grepl("translate", tr, fixed = TRUE)
      if (any(tx)) {
        out$ax[i[tx]] <- as.numeric(sub("^.*translate\\(\\s*([-0-9.eE]+).*$", "\\1", tr[tx]))
      }
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
