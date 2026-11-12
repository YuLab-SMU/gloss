# Engine plugin: ComplexHeatmap. Tables are the matrices and the row and
# column orders after clustering; panels are the heatmap body slices, with
# the native scales of their viewports. The engine draws the heatmap itself
# to keep what draw() returns; its page is the page show() draws.

register_engine_heatmap <- function() {
  gl_register(
    "engine", name = "heatmap", version = "0.1.0", package = "gloss",
    description = "ComplexHeatmap heatmaps: matrices, orders and body slices",
    classes = c("Heatmap", "HeatmapList"),
    packages = "ComplexHeatmap",
    prepare = function(x, width, height) {
      st <- new_env()
      st$ht <- x
      st$width <- width
      st$height <- height
      st
    },
    # Draws on the page and keeps the drawn HeatmapList: the row and column
    # orders after clustering exist only once the heatmap is drawn.
    draw = function(state) {
      state$drawn <- ComplexHeatmap::draw(state$ht)
      state
    },
    tables = function(state) heatmap_tables(state$drawn),
    panels = function(state, substrate) heatmap_panels(substrate),
    bind = function(state, substrate) heatmap_bind(state$drawn, substrate),
    describe = function(state) {
      hl <- state$drawn
      list(heatmaps = names(hl@ht_list), classes = vapply(hl@ht_list, function(h) class(h)[1], ""))
    },
    example = function() {
      m <- matrix(c(1, 3, 2, 5, 4, 6), 2, dimnames = list(c("g1", "g2"), c("s1", "s2", "s3")))
      ComplexHeatmap::Heatmap(m, name = "z")
    }
  )
}

heatmap_tables <- function(drawn) {
  out <- list()
  if (is.null(drawn)) return(out)
  for (nm in names(drawn@ht_list)) {
    h <- drawn@ht_list[[nm]]
    if (!methods::is(h, "Heatmap")) next
    m <- h@matrix
    df <- as.data.frame(m, stringsAsFactors = FALSE)
    if (is.null(rownames(m))) df <- cbind(.row = seq_len(nrow(m)), df)
    out[[length(out) + 1L]] <- list(name = paste0("matrix_", nm), role = "engine", data = df,
                                    description = sprintf("matrix of heatmap '%s'", nm))
    ro <- tryCatch(ComplexHeatmap::row_order(drawn)[[nm]] %||% ComplexHeatmap::row_order(drawn),
                   error = function(e) NULL)
    co <- tryCatch(ComplexHeatmap::column_order(drawn)[[nm]] %||% ComplexHeatmap::column_order(drawn),
                   error = function(e) NULL)
    ord <- rbind(order_rows("row", ro, rownames(m)), order_rows("column", co, colnames(m)))
    if (!is.null(ord) && nrow(ord)) {
      out[[length(out) + 1L]] <- list(name = paste0("order_", nm), role = "engine", data = ord,
                                      description = sprintf("row and column order of heatmap '%s'", nm))
    }
  }
  out
}

order_rows <- function(dimension, ord, labels) {
  if (is.null(ord)) return(NULL)
  if (!is.list(ord)) ord <- list(ord)
  rows <- lapply(seq_along(ord), function(s) {
    idx <- as.integer(ord[[s]])
    data.frame(dimension = dimension, slice = s, position = seq_along(idx), index = idx,
               label = if (is.null(labels)) NA_character_ else labels[idx],
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

heatmap_panels <- function(substrate) {
  leaves <- substrate$leaves
  seg <- vapply(strsplit(leaves$vp, "::", fixed = TRUE), function(parts) {
    hit <- grep("_heatmap_body_[0-9]+_[0-9]+$", parts, value = TRUE)
    if (length(hit)) hit[length(hit)] else NA_character_
  }, "")
  native_panels(leaves, seg, key_fun = function(v) sub("_heatmap_body_", " slice ", v))
}

# Panels whose scales are the native scales of their viewports, as recorded
# by the probes, or by the replay of a base page. Used for heatmap bodies
# and base plot regions.
native_panels <- function(leaves, seg, key_fun = identity) {
  vps <- unique(stats::na.omit(seg))
  if (!length(vps)) return(NULL)
  first <- match(vps, seg)
  l <- leaves[first, , drop = FALSE]
  panels <- data.frame(
    id = paste0("panel", seq_along(vps)), key = key_fun(vps), vp = vps,
    x0 = l$x0, y0 = l$y0, x1 = l$x1, y1 = l$y1,
    x_type = "native", x_min = l$xscale0, x_max = l$xscale1, x_trans = "identity",
    y_type = "native", y_min = l$yscale0, y_max = l$yscale1, y_trans = "identity",
    stringsAsFactors = FALSE
  )
  list(panels = panels, leaf_panel = stats::setNames(panels$id[match(seg, vps)], leaves$id))
}

# ---- binding ----------------------------------------------------------------

# Body cells paired with matrix cells (core-bind.R checks them). A body slice
# is drawn in viewport <name>_heatmap_body_<i>_<j>, one rect per cell, column
# by column, top row first, rows and columns in the slice's order after
# clustering. Each cell's place in the slice's viewport and its colour, the
# colour mapping of its value, are what the elements must show; the colour is
# the check that the order is right, since every cell sits at its grid place
# whatever value it holds. A body drawn as a raster image has one element
# and is not paired. Annotations and dendrograms are not paired yet.
heatmap_bind <- function(drawn, sub) {
  leaves <- sub$leaves
  claims <- list()
  ub <- data.frame(leaf = character(), reason = character(), stringsAsFactors = FALSE)
  outside <- character()
  hits <- regmatches(leaves$vp, regexec("(?:^|::)([^:]+)_heatmap_body_([0-9]+)_([0-9]+)$", leaves$vp, perl = TRUE))
  for (r in seq_len(nrow(leaves))) {
    h <- hits[[r]]
    if (!length(h)) {
      if (grepl("_dend_|annotation", leaves$vp[r])) {
        ub <- rbind(ub, data.frame(leaf = leaves$id[r], reason = "annotation tracks and dendrograms are not paired yet",
                                   stringsAsFactors = FALSE))
      } else {
        outside <- c(outside, leaves$id[r])
      }
      next
    }
    nm <- h[2]
    ht <- if (nm %in% names(drawn@ht_list)) drawn@ht_list[[nm]] else NULL
    if (is.null(ht) || !methods::is(ht, "Heatmap")) {
      ub <- rbind(ub, data.frame(leaf = leaves$id[r], reason = sprintf("no heatmap named '%s' in the drawn list", nm),
                                 stringsAsFactors = FALSE))
      next
    }
    i <- as.integer(h[3])
    j <- as.integer(h[4])
    ro <- ht@row_order_list[[i]]
    co <- ht@column_order_list[[j]]
    m <- ht@matrix
    nr <- length(ro)
    nc <- length(co)
    lf <- leaves[r, ]
    cell_r <- rep(ro, times = nc)
    cell_c <- rep(co, each = nr)
    pos_r <- rep(seq_len(nr), times = nc)
    pos_c <- rep(seq_len(nc), each = nr)
    w <- (lf$x1 - lf$x0) / nc
    hgt <- (lf$y1 - lf$y0) / nr
    value <- m[cbind(cell_r, cell_c)]
    fill <- tryCatch(ComplexHeatmap::map_to_colors(ht@matrix_color_mapping, value), error = function(e) NULL)
    pred <- data.frame(
      row = (cell_c - 1L) * nrow(m) + cell_r,   # cell of the matrix table, column-major
      group = seq_along(cell_r),
      x = lf$x0 + (pos_c - 0.5) * w, y = lf$y0 + (pos_r - 0.5) * hgt,
      xmin = lf$x0 + (pos_c - 1) * w, xmax = lf$x0 + pos_c * w,
      ymin = lf$y0 + (pos_r - 1) * hgt, ymax = lf$y0 + pos_r * hgt
    )
    if (!is.null(fill)) pred$fill <- as.character(fill)
    claims[[length(claims) + 1L]] <- list(leaf = lf$id, table = paste0("matrix_", nm), pred = pred)
  }
  list(claims = claims, unbound = ub, outside = outside)
}
