# Engine plugin: base graphics. Accepts a recorded plot or a function that
# draws a base page. gloss replays the page one display-list entry at a time
# (ADR-0006); each entry that draws is a leaf, named by its call. Panels are
# the plot regions of the page's figures, with the user coordinates of
# par("usr"); a leaf lies in a panel when its primitives are clipped to that
# plot region. Base graphics carry no data tables: the engine states the
# arguments of the data-mark calls as tables and binds each entry's elements
# to them (see below). The core hands it the recorded page as
# `state$recorded`.

register_engine_base <- function() {
  gl_register(
    "engine", name = "base", version = "0.2.0", package = "gloss",
    description = "base graphics, replayed one display-list entry at a time: plot regions with user coordinates",
    classes = c("recordedplot", "function"),
    page = "base",
    packages = "graphics",
    prepare = function(x, width, height) list(x = x, width = width, height = height),
    tables = function(state) {
      tabs <- base_tables_from(state$recorded)
      lapply(names(tabs), function(nm) list(
        name = paste0("base_", nm), role = "engine", data = tabs[[nm]],
        description = sprintf(paste("arguments of the page's %s calls, one row per element drawn",
                                    "(polylines and polygons: one row per vertex); entry: the display-list entry"), nm)))
    },
    bind = function(state, substrate) base_bind(state, substrate),
    panels = function(state, substrate) {
      leaves <- substrate$leaves
      seg <- ifelse(endsWith(leaves$vp, "::plot"), leaves$vp, NA_character_)
      native_panels(leaves, seg, key_fun = function(v) sub("::plot$", "", v))
    },
    example = function() {
      function() graphics::plot(datasets::mtcars$wt, datasets::mtcars$mpg, pch = 19)
    }
  )
}

# ---- binding ----------------------------------------------------------------

# Base graphics have no data tables; what a data-mark entry draws is fixed by
# its arguments. The engine states one table per kind of data-mark call, one
# row per element the entry draws, in drawing order, with the entry's index:
# `plotXY` (points and lines), `segments`, `arrows`, `rect`, `polygon`,
# `path`, `text`, `symbols`. Each leaf (one display-list entry) is paired
# with its entry's rows, put on the device through that entry's plot region
# and `usr` (read while capturing) and its log axes (read by replaying the
# recorded page on a null device), and checked like any other binding. What
# links those arguments to the rows of a user's data frame is not stated:
# the call only received vectors (M1 plan Task 5).
base_data_ops <- c("C_plotXY", "C_segments", "C_arrows", "C_rect", "C_polygon", "C_path", "C_text", "C_symbols")

# Per entry: op and the argument rows, element by element (NULL when the
# entry is not a data-mark call or draws elements no row describes).
base_entry_rows <- function(e) {
  a <- tryCatch(as.list(e[[2]]), error = function(err) list())
  op <- tryCatch(a[[1]]$name, error = function(err) "")
  if (!is.character(op) || length(op) != 1L || !op %in% base_data_ops) return(NULL)
  fin <- function(...) Reduce(`&`, lapply(list(...), function(v) !is.na(v) & is.finite(v)))
  recycle <- function(args) {
    n <- max(lengths(args))
    lapply(args, rep_len, length.out = n)
  }
  rows <- tryCatch(switch(op,
    C_plotXY = {
      xy <- a[[2]]
      type <- a[[3]]
      ok <- fin(xy$x, xy$y)
      if (identical(type, "p")) {
        data.frame(x = xy$x[ok], y = xy$y[ok])
      } else if (identical(type, "l")) {
        # one polyline per run of finite points: the run is the group
        r <- rle(ok)
        run <- rep(seq_along(r$lengths), r$lengths)
        keep <- ok & run %in% which(r$values & r$lengths >= 2L)
        data.frame(x = xy$x[keep], y = xy$y[keep], group = match(run[keep], unique(run[keep])))
      } else {
        why <- switch(type,
          s = , S = "steps run between the points, not through them",
          b = , o = "it draws a point and a piece of line for each point",
          c = "it draws the pieces of line between the points, not the points",
          h = "it draws a line from the base line to each point",
          "its type draws elements the points do not give one by one")
        return(list(op = op, rows = NULL, reason = sprintf("plotXY of type '%s': %s", type, why)))
      }
    },
    C_segments = , C_arrows = {
      v <- recycle(a[2:5])
      ok <- fin(v[[1]], v[[2]], v[[3]], v[[4]])
      if (op == "C_arrows") {
        code <- a$code %||% 2
        moved <- ok & (v[[1]] != v[[3]] | v[[2]] != v[[4]])
        # heads are drawn as extra elements: only arrows without heads pair one to one
        if (code != 0 && any(moved)) return(list(op = op, rows = NULL, reason = "arrows draw a shaft and heads per arrow"))
      }
      data.frame(x = v[[1]][ok], y = v[[2]][ok], xend = v[[3]][ok], yend = v[[4]][ok])
    },
    C_rect = {
      v <- recycle(a[2:5])
      ok <- fin(v[[1]], v[[2]], v[[3]], v[[4]])
      data.frame(xmin = v[[1]][ok], ymin = v[[2]][ok], xmax = v[[3]][ok], ymax = v[[4]][ok])
    },
    C_polygon = {
      ok <- fin(a[[2]], a[[3]])
      r <- rle(ok)
      run <- rep(seq_along(r$lengths), r$lengths)
      keep <- ok & run %in% which(r$values & r$lengths >= 2L)
      # one row per polygon, at its vertices; the device mean is taken later
      data.frame(x = a[[2]][keep], y = a[[3]][keep], part = match(run[keep], unique(run[keep])))
    },
    C_path = {
      ok <- fin(a[[2]], a[[3]])
      if (!any(ok)) NULL else data.frame(x = a[[2]][ok], y = a[[3]][ok], part = 1L)
    },
    C_text = {
      xy <- a[[2]]
      lab <- a[[3]]
      if (!is.atomic(lab)) return(list(op = op, rows = NULL, reason = "plotmath labels draw an unknown number of pieces"))
      if (length(a) >= 5L && !is.null(a[[5]])) {
        return(list(op = op, rows = NULL, reason = "text placed with pos is offset from its x and y"))
      }
      v <- recycle(list(xy$x, xy$y, as.character(lab)))
      ok <- fin(v[[1]], v[[2]]) & !is.na(v[[3]])
      data.frame(x = v[[1]][ok], y = v[[2]][ok], label = v[[3]][ok], stringsAsFactors = FALSE)
    },
    C_symbols = {
      kind <- a[[4]]
      d <- a[[5]]
      ok <- fin(a[[2]], a[[3]])
      if (kind %in% c(1, 2)) {
        ok <- ok & fin(d)
        data.frame(x = a[[2]][ok], y = a[[3]][ok], size = d[ok])
      } else if (kind == 3 && is.matrix(d)) {
        ok <- ok & fin(d[, 1], d[, 2])
        data.frame(x = a[[2]][ok], y = a[[3]][ok], width = d[ok, 1], height = d[ok, 2])
      } else NULL
    },
    NULL), error = function(err) NULL)
  list(op = op, rows = rows)
}

# The tables: one per kind of data-mark call on the page, rows in display-list
# order, each with the entry it belongs to.
base_tables_from <- function(rp) {
  dl <- if (is.null(rp)) list() else as.list(rp[[1]])
  per <- list()
  for (k in seq_along(dl)) {
    r <- base_entry_rows(dl[[k]])
    if (is.null(r) || is.null(r$rows) || !nrow(r$rows)) next
    nm <- sub("^C_", "", r$op)
    per[[nm]] <- c(per[[nm]], list(cbind(entry = k, element = base_elements(r$rows), r$rows)))
  }
  # entries of one kind can differ in columns (points have no group, lines do)
  lapply(per, function(x) {
    cols <- unique(unlist(lapply(x, names)))
    do.call(rbind, lapply(x, function(d) {
      for (cn in setdiff(cols, names(d))) d[[cn]] <- NA
      d[cols]
    }))
  })
}

# The element each row belongs to, within its entry: rows of a polyline or
# a polygon share one.
base_elements <- function(rows) {
  if (!is.null(rows$group)) return(rows$group)
  if (!is.null(rows$part)) return(rows$part)
  seq_len(nrow(rows))
}

# par("xlog") and par("ylog") after each entry, from a replay of the page on
# a null device (the arguments are data values; on a log axis usr is not).
base_log_axes <- function(rp, width, height) {
  dl <- as.list(rp[[1]])
  out <- matrix(NA, length(dl), 2)
  grDevices::pdf(NULL, width = width, height = height)
  dev <- grDevices::dev.cur()
  on.exit(if (dev %in% grDevices::dev.list()) grDevices::dev.off(dev), add = TRUE)
  stub <- rp
  stub[1] <- list(NULL)
  ok <- tryCatch({ grDevices::replayPlot(stub); TRUE }, error = function(e) FALSE)
  if (!ok) return(out)
  for (k in seq_along(dl)) {
    e <- dl[[k]]
    done <- tryCatch({ suppressWarnings(do.call(e[[1]], as.list(e[[2]]), quote = TRUE)); TRUE }, error = function(err) FALSE)
    if (!done) break
    out[k, ] <- c(graphics::par("xlog"), graphics::par("ylog"))
  }
  out
}

# Pairings of base leaves with their entries' rows (core-bind.R checks them).
base_bind <- function(state, sub) {
  leaves <- sub$leaves
  ub <- data.frame(leaf = character(), reason = character(), stringsAsFactors = FALSE)
  unbound <- function(id, reason) data.frame(leaf = id, reason = reason, stringsAsFactors = FALSE)
  rp <- state$recorded
  if (is.null(rp)) return(list(claims = list(), unbound = unbound(leaves$id, "the recorded page was not kept")))
  dl <- as.list(rp[[1]])
  logs <- base_log_axes(rp, state$width %||% 7, state$height %||% 5)
  tabs <- base_tables_from(rp)
  claims <- list()
  outside <- character()
  for (r in seq_len(nrow(leaves))) {
    lf <- leaves[r, ]
    k <- suppressWarnings(as.integer(sub("^base/([0-9]+)/.*$", "\\1", lf$path)))
    e <- if (is.na(k) || k > length(dl)) NULL else base_entry_rows(dl[[k]])
    if (is.null(e)) {
      outside <- c(outside, lf$id)
      next
    }
    if (is.null(e$rows)) {
      ub <- rbind(ub, unbound(lf$id, e$reason %||% sprintf("%s draws elements its arguments do not give one by one", sub("^C_", "", e$op))))
      next
    }
    nm <- sub("^C_", "", e$op)
    tab <- tabs[[nm]]
    rows <- which(tab$entry == k)
    scale <- c(lf$xscale0, lf$xscale1, lf$yscale0, lf$yscale1)
    if (anyNA(scale) || scale[1] == scale[2] || scale[3] == scale[4] || anyNA(logs[k, ])) {
      ub <- rbind(ub, unbound(lf$id, "the entry has no user coordinates to put its arguments on the page"))
      next
    }
    pred <- base_rows_on_device(tab[rows, , drop = FALSE], rows, lf, logs[k, ])
    claims[[length(claims) + 1L]] <- list(leaf = lf$id, table = paste0("base_", nm), pred = pred)
  }
  list(claims = claims, unbound = ub, outside = outside)
}

# Rows on the device: data values through log10 where the axis is
# logarithmic, then the entry's usr onto its plot region (y grows down).
base_rows_on_device <- function(d, rows, lf, logs) {
  tx <- function(v) {
    u <- if (isTRUE(logs[1])) log10(v) else v
    lf$x0 + (u - lf$xscale0) / (lf$xscale1 - lf$xscale0) * (lf$x1 - lf$x0)
  }
  ty <- function(v) {
    u <- if (isTRUE(logs[2])) log10(v) else v
    lf$y1 - (u - lf$yscale0) / (lf$yscale1 - lf$yscale0) * (lf$y1 - lf$y0)
  }
  out <- data.frame(row = rows)
  for (col in intersect(c("x", "xend", "xmin", "xmax"), names(d))) out[[col]] <- tx(d[[col]])
  for (col in intersect(c("y", "yend", "ymin", "ymax"), names(d))) out[[col]] <- ty(d[[col]])
  if (!is.null(d$group)) out$group <- d$group
  if (!is.null(d$part)) {
    # one element per polygon: the mean of its vertices on the device
    parts <- unique(d$part)
    out <- data.frame(row = rows[match(parts, d$part)],
                      x = vapply(parts, function(p) mean(out$x[d$part == p]), 1),
                      y = vapply(parts, function(p) mean(out$y[d$part == p]), 1))
  }
  out
}
