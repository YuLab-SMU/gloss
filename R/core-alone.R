# Rows placed on the page from the figure alone (plan 2026-11-12-agent-path,
# Task 2).
#
# At capture the engine says where each row of its tables must be drawn: it
# puts the rows through the coord's own transform (ggplot), the entry's user
# coordinates (base) or the order of a heatmap's cells, with its state at
# hand. That state is not kept. What a figure keeps, also after a round trip
# through a bundle, is the table's position columns and the ranges of each
# panel's scales on the page. place_rows() puts rows on the page from those
# two and nothing else; it gives a reason, never a guess, when they do not
# say where a row lands.
#
# recheck_alone() takes the engine's own claims and checks each a second
# time with its rows placed that way: the same rows, the same comparison by
# tag (core-bind.R), only the positions differ. It measures how far a check
# made after capture can go. Nothing here is exported or stored.

position_columns <- list(x = c("x", "xmin", "xmax", "xend"), y = c("y", "ymin", "ymax", "yend"))

# Device positions of `rows` of `table`, through the scales of `panel`:
# linear from the scale's range to the panel's box, y growing down. In a
# flipped panel the horizontal scale carries the table's y columns and the
# vertical one its x columns; the result is named by the page, as the
# engine's positions are (x horizontal). Returns a data frame (row, then the
# positions) or one string, the reason no position can be given.
place_rows <- function(fig, table, rows, panel) {
  t <- fig$tables[[table]]$data
  if (is.null(t)) return(sprintf("the table '%s' has no rows in the figure", table))
  rows <- as.integer(rows)
  if (anyNA(rows) || any(rows < 1L | rows > nrow(t))) {
    return(sprintf("the rows are not all in the table '%s' (%d rows)", table, nrow(t)))
  }
  panels <- fig$substrate$panels
  p <- if (is.data.frame(panels) && length(panel) == 1L && !is.na(panel)) panels[panels$id %in% panel, , drop = FALSE]
  if (is.null(p) || nrow(p) != 1L) return("the leaf lies in no panel with scales")
  rng <- c(p$x_min, p$x_max, p$y_min, p$y_max)
  if (anyNA(rng) || !all(is.finite(rng)) || rng[1] == rng[2] || rng[3] == rng[4]) {
    return(sprintf("the panel's scales are not given as ranges on the page (%s, %s)", p$x_type, p$y_type))
  }
  flipped <- p$flipped
  if (is.null(flipped) || is.na(flipped)) {
    return("the panel does not say which of the table's scales is horizontal (captured by an earlier gloss)")
  }
  # the table's column behind each position on the page
  source_of <- function(cols) {
    # the first letter only: "xmax" holds two
    src <- if (flipped) paste0(chartr("xy", "yx", substr(cols, 1L, 1L)), substring(cols, 2L)) else cols
    stats::setNames(src, cols)[src %in% names(t)]
  }
  xs <- source_of(position_columns$x)
  ys <- source_of(position_columns$y)
  if (!length(xs) || !length(ys)) return(sprintf("the table '%s' has no position columns", table))
  num <- function(v) suppressWarnings(as.double(v))
  out <- data.frame(row = rows)
  for (col in names(xs)) out[[col]] <- p$x0 + (num(t[[xs[[col]]]][rows]) - p$x_min) / (p$x_max - p$x_min) * (p$x1 - p$x0)
  for (col in names(ys)) out[[col]] <- p$y1 - (num(t[[ys[[col]]]][rows]) - p$y_min) / (p$y_max - p$y_min) * (p$y1 - p$y0)
  # keep the columns in the engine's order
  out[c("row", intersect(c("x", "y", "xmin", "xmax", "ymin", "ymax", "xend", "yend"), names(out)))]
}

# An engine's claim with its rows placed from the figure alone: the rows it
# names, their groups and what the comparisons read beside positions
# (justification, angle, label, shape) taken from the table. What only the
# engine knows about the coord is dropped: the rows were placed through
# linear scales, or not at all. Returns the claim, or the reason as a string.
alone_claim <- function(fig, cl) {
  leaves <- fig$substrate$leaves
  lf <- leaves[match(cl$leaf, leaves$id), , drop = FALSE]
  rows <- cl$pred$row
  placed <- place_rows(fig, cl$table, rows, lf$panel)
  if (is.character(placed)) return(placed)
  t <- fig$tables[[cl$table]]$data
  pred <- data.frame(row = rows, group = if ("group" %in% names(t)) t$group[rows] else rep(1L, length(rows)))
  if ("align_padding" %in% names(t)) pred$pad <- t$align_padding[rows] %in% TRUE
  for (col in setdiff(names(placed), "row")) pred[[col]] <- placed[[col]]
  for (col in intersect(c("hjust", "vjust"), names(t))) pred[[col]] <- just_value(t[[col]][rows])
  if ("angle" %in% names(t)) pred$angle <- suppressWarnings(as.double(t$angle[rows]))
  if ("label" %in% names(t)) pred$label <- as.character(t$label[rows])
  if ("shape" %in% names(t)) pred$shape <- t$shape[rows]
  list(leaf = cl$leaf, table = cl$table, pred = pred, groups = cl$groups, rows = cl$rows,
       linear = TRUE, made_reason = cl$made_reason)
}

# The largest distance, in pt, between two placements of the same rows.
placement_gap <- function(a, b) {
  cols <- intersect(unlist(position_columns), intersect(names(a), names(b)))
  if (!length(cols) || nrow(a) != nrow(b)) return(NA_real_)
  d <- unlist(lapply(cols, function(col) abs(a[[col]] - b[[col]])))
  if (all(is.na(d))) NA_real_ else max(d, na.rm = TRUE)
}

# The claim with every row at the next row's place: element k is then
# claimed to be where row k + 1 is drawn. `moved` says which rows' place
# changed by more than the tolerance (a row at its neighbour's place did
# not move).
shifted_claim <- function(cl, tol) {
  pred <- cl$pred
  n <- nrow(pred)
  cols <- intersect(unlist(position_columns), names(pred))
  if (n < 2L || !length(cols)) return(NULL)
  nxt <- c(seq_len(n)[-1L], 1L)
  d <- do.call(pmax, c(lapply(cols, function(col) abs(pred[[col]] - pred[[col]][nxt])), na.rm = TRUE))
  moved <- !is.na(d) & d > tol
  pred[cols] <- pred[nxt, cols, drop = FALSE]
  cl$pred <- pred
  list(claim = cl, moved_rows = cl$pred$row[moved])
}

passes <- function(status) status %in% c("verified", "ambiguous")

# Every claim of the engine, checked with the engine's positions and with
# the figure's own. One row per claimed leaf:
#   engine_*, alone_*   the leaf's status and its elements by status
#   same                elements with the same status under both
#   gap                 largest distance between the two placements, pt
#   alone_reason        why the figure alone gives no position
#   moved               elements whose row's place moves by more than the
#                       tolerance when every row takes the next row's place
#   moved_pass_*        of those, the elements that still pass
# and one row per element with its two statuses.
recheck_alone <- function(fig, eng, state, tol = bind_tolerance) {
  sub <- fig$substrate
  leaves <- sub$leaves
  geo <- scene_geometry(sub)
  grDevices::pdf(NULL)
  null_dev <- grDevices::dev.cur()
  on.exit(if (null_dev %in% grDevices::dev.list()) grDevices::dev.off(null_dev), add = TRUE)
  stated <- if (is.null(eng$bind)) list(claims = list()) else eng$bind(state, sub)
  geo_at <- split(seq_len(nrow(geo)), geo$leaf)
  lv <- list()
  el <- list()
  counts <- function(st, prefix) {
    stats::setNames(list(sum(st == "verified"), sum(st == "ambiguous"), sum(st == "failed")),
                    paste0(prefix, c("_verified", "_ambiguous", "_failed")))
  }
  moved_pass <- function(cl, lf, g) {
    sh <- shifted_claim(cl, tol)
    if (is.null(sh)) return(c(moved = 0L, pass = 0L))
    r <- check_claim(sh$claim, lf, g, tol)$elements
    moved <- !is.na(r$row) & r$row %in% sh$moved_rows
    c(moved = sum(moved), pass = sum(moved & passes(r$status)))
  }
  for (cl in stated$claims) {
    lf <- leaves[match(cl$leaf, leaves$id), , drop = FALSE]
    g <- geo[geo_at[[cl$leaf]] %||% integer(), , drop = FALSE]
    e <- check_claim(cl, lf, g, tol)
    ac <- alone_claim(fig, cl)
    placed <- !is.character(ac)
    a <- if (placed) check_claim(ac, lf, g, tol)
    st_e <- e$elements$status
    st_a <- if (placed) a$elements$status else rep("unbound", length(st_e))
    me <- moved_pass(cl, lf, g)
    ma <- if (placed) moved_pass(ac, lf, g) else c(moved = NA_integer_, pass = NA_integer_)
    lv[[length(lv) + 1L]] <- data.frame(c(
      list(leaf = cl$leaf, table = cl$table, coord = cl$coord %||% NA_character_, mode = e$leaf$mode,
           n_elements = length(st_e), engine_status = e$leaf$status),
      counts(st_e, "engine"),
      list(alone_status = if (placed) a$leaf$status else "unbound"),
      counts(st_a, "alone"),
      list(same = sum(st_e == st_a),
           gap = if (placed) placement_gap(cl$pred, ac$pred) else NA_real_,
           alone_reason = if (placed) a$leaf$reason else ac,
           moved = unname(me[["moved"]]), moved_pass_engine = unname(me[["pass"]]),
           moved_pass_alone = unname(ma[["pass"]]))
    ), stringsAsFactors = FALSE)
    el[[length(el) + 1L]] <- data.frame(element = e$elements$element, leaf = rep(cl$leaf, length(st_e)),
                                        engine = st_e, alone = st_a, stringsAsFactors = FALSE)
  }
  empty_lv <- data.frame(leaf = character(), table = character(), coord = character(), mode = character(),
                         n_elements = integer(), engine_status = character(), engine_verified = integer(),
                         engine_ambiguous = integer(), engine_failed = integer(), alone_status = character(),
                         alone_verified = integer(), alone_ambiguous = integer(), alone_failed = integer(),
                         same = integer(), gap = double(), alone_reason = character(), moved = integer(),
                         moved_pass_engine = integer(), moved_pass_alone = integer(), stringsAsFactors = FALSE)
  empty_el <- data.frame(element = character(), leaf = character(), engine = character(), alone = character(),
                         stringsAsFactors = FALSE)
  list(leaves = if (length(lv)) do.call(rbind, lv) else empty_lv,
       elements = if (length(el)) do.call(rbind, el) else empty_el)
}

# Capture `x` and recheck its engine's claims from the figure alone; for the
# bench and the tests, like bind_capture().
alone_capture <- function(x, width = 7, height = 5, dense = 10000, engine = NULL) {
  engines <- engine_candidates(x, engine)
  res <- capture_figure(x, engines, width = width, height = height, dense = dense, context = FALSE,
                        bind = FALSE)
  c(list(fig = res$fig), recheck_alone(res$fig, res$engine, res$state))
}
