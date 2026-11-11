# Engine plugin: ggplot2.
#
# ggplot2's print() starts a page, builds the plot and draws its gtable. The
# engine does the same and keeps the build, so the built tables are the data
# drawn even when the build draws random numbers (position_jitter() without a
# seed: 0 of 32 rows on the page from a separate build, 32 of 32 from the
# drawn one; dev_docs/research/capture-fidelity/p2-jitter-tables.out). An
# object whose class has its own print method (ggbreak's ggcut) is printed;
# its built data and panels describe the plot before that method, so they are
# withheld with the reason (ADR-0006 point 4). Its raw data is kept.

register_engine_ggplot <- function() {
  gl_register(
    "engine", name = "ggplot", version = "0.1.0", package = "gloss",
    description = "ggplot2 plots: built layer data, facet panels and position scales",
    classes = c("ggplot", "ggplot2::ggplot"),
    packages = "ggplot2",
    prepare = function(x, width, height) {
      owner <- ggplot_print_owner(x)
      # An extension whose ggplot_build() returns something else (gganimate)
      # is refused before its own print method runs.
      list(plot = x, owner = owner, built = if (is.null(owner)) NULL else build_ggplot(x))
    },
    draw = function(state) {
      if (is.null(state$owner)) {
        ggplot2::set_last_plot(state$plot)
        grid::grid.newpage()
        state$built <- build_ggplot(state$plot)
        # The table drawn is kept: binding maps leaves to layers through it.
        state$gtable <- ggplot2::ggplot_gtable(state$built)
        grid::grid.draw(state$gtable)
      } else {
        print(state$plot)
      }
      state
    },
    tables = function(state) {
      ggplot_tables(state$plot, state$built, withheld = print_owner_reason(state$owner))
    },
    panels = function(state, substrate) {
      if (!is.null(state$owner)) return(list(withheld = print_owner_reason(state$owner)))
      ggplot_panels(state$built, substrate)
    },
    bind = function(state, substrate) {
      if (!is.null(state$owner)) {
        return(list(claims = list(), unbound = data.frame(
          leaf = substrate$leaves$id, reason = print_owner_reason(state$owner), stringsAsFactors = FALSE)))
      }
      ggplot_bind(state$built, state$gtable, substrate)
    },
    describe = function(state) ggplot_describe(state$plot),
    example = function() {
      ggplot2::ggplot(datasets::mtcars, ggplot2::aes(.data$wt, .data$mpg)) +
        ggplot2::geom_point()
    }
  )
}

# ggplot_build(), refusing an extension whose own ggplot_build() method
# returns something other than a built ggplot (gganimate's "gganim_built"):
# gloss captures one static ggplot and cannot draw it.
build_ggplot <- function(x) {
  built <- ggplot2::ggplot_build(x)
  if (!inherits(built, c("ggplot_built", "ggplot2::ggplot_built"))) {
    cli::cli_abort(c(
      "{.cls {class(x)[1]}} builds into {.cls {class(built)[1]}}, not a built ggplot.",
      i = "Its own {.fn ggplot_build} method changes what is drawn (an animation, for example); gloss captures one static ggplot."
    ))
  }
  built
}

# The class whose print method draws `x`, when that method is not ggplot2's.
ggplot_print_owner <- function(x) {
  std <- lapply(c("ggplot2::ggplot", "ggplot"), function(cls) {
    tryCatch(utils::getS3method("print", cls, optional = TRUE), error = function(e) NULL)
  })
  std <- std[!vapply(std, is.null, logical(1))]
  for (cls in class(x)) {
    m <- tryCatch(utils::getS3method("print", cls, optional = TRUE), error = function(e) NULL)
    if (is.null(m)) next
    if (any(vapply(std, function(f) identical(f, m), logical(1)))) return(NULL)
    return(cls)
  }
  NULL
}

print_owner_reason <- function(owner) {
  if (is.null(owner)) return(NULL)
  sprintf(paste("print.%s draws the page, not ggplot2's print method; the built data and panels",
                "describe the plot before that method, so gloss cannot show they describe the page drawn."),
          owner)
}

quo_vars <- function(q) {
  if (is.null(q)) return(character())
  tryCatch(all.vars(rlang::quo_get_expr(q)), error = function(e) character())
}

# Columns named by a bare symbol (or .data$col) in a mapping, by aesthetic.
mapping_symbols <- function(mapping) {
  out <- character()
  for (aes in names(mapping)) {
    e <- tryCatch(rlang::quo_get_expr(mapping[[aes]]), error = function(e) NULL)
    if (is.symbol(e)) {
      out[aes] <- as.character(e)
    } else if (is.call(e) && identical(e[[1]], as.symbol("$")) && identical(e[[2]], as.symbol(".data"))) {
      out[aes] <- as.character(e[[3]])
    }
  }
  out
}

ggplot_facet_vars <- function(built) {
  lay <- built$layout$layout
  setdiff(names(lay), c("PANEL", "ROW", "COL", "SCALE_X", "SCALE_Y", "COORD"))
}

# Raw tables of the plot and of its layers, and the built data of each
# layer. With `withheld`, the built data are listed as withheld with that
# reason instead (the raw data are what the plot was given, whatever drew it).
ggplot_tables <- function(plot, built, withheld = NULL) {
  key_aes <- c("label", "group", "data_id", "tooltip", "text", "id")
  maps <- c(list(plot$mapping), lapply(plot$layers, function(l) l$mapping))
  referenced <- unique(c(unlist(lapply(maps, function(m) unlist(lapply(m, quo_vars)))),
                         if (is.null(built)) character() else ggplot_facet_vars(built)))
  hints_all <- unlist(lapply(maps, mapping_symbols))
  hints <- hints_all[names(hints_all) %in% key_aes]
  out <- list()
  if (is.data.frame(plot$data)) {
    out[[length(out) + 1L]] <- list(
      name = "raw", role = "raw", data = plot$data, referenced = intersect(referenced, names(plot$data)),
      key_hints = hints, description = "plot data"
    )
  }
  for (i in seq_along(plot$layers)) {
    l <- plot$layers[[i]]
    if (is.data.frame(l$data)) {
      out[[length(out) + 1L]] <- list(
        name = sprintf("raw_layer%d", i), role = "raw", layer = i, data = l$data,
        referenced = intersect(referenced, names(l$data)), key_hints = hints,
        description = sprintf("data of layer %d", i)
      )
    }
  }
  # built data follows the built plot's layers: ggplot_build() adds a
  # geom_blank layer to a plot that has none (wrapped patchwork elements)
  built_layers <- built$plot$layers %||% plot$layers
  if (!is.null(withheld)) {
    n <- if (is.null(built)) max(1L, length(plot$layers)) else length(built$data)
    for (i in seq_len(n)) {
      out[[length(out) + 1L]] <- list(name = sprintf("built_layer%d", i), withheld = withheld)
    }
    return(out)
  }
  for (i in seq_along(built$data)) {
    l <- if (i <= length(built_layers)) built_layers[[i]] else NULL
    out[[length(out) + 1L]] <- list(
      name = sprintf("built_layer%d", i), role = "built", layer = i, data = built$data[[i]],
      description = sprintf("built data of layer %d (%s, %s)", i, class(l$geom)[1], class(l$stat)[1])
    )
  }
  out
}

# Panels: one per PANEL of the built layout. Panel viewports are found from
# the probes (every leaf drawn inside a panel cell has its viewport path),
# and matched to ROW/COL of the layout by position on the page.
ggplot_panels <- function(built, substrate, prefix = "", leaf_filter = NULL) {
  leaves <- substrate$leaves
  if (!is.null(leaf_filter)) leaves <- leaves[leaf_filter, , drop = FALSE]
  seg <- vapply(strsplit(leaves$vp, "::", fixed = TRUE), function(parts) {
    hit <- grep("^panel(-[0-9]+)*\\.[0-9-]+$|^panel\\.[0-9-]+$", parts, value = TRUE)
    if (length(hit)) hit[length(hit)] else NA_character_
  }, "")
  vps <- unique(stats::na.omit(seg))
  lay <- built$layout$layout
  if (length(vps) != nrow(lay)) {
    return(list(withheld = sprintf(
      "%d panel viewport%s on the page and %d panel%s in the built layout: panels cannot be matched to the page.",
      length(vps), if (length(vps) == 1L) "" else "s", nrow(lay), if (nrow(lay) == 1L) "" else "s")))
  }
  first <- match(vps, seg)
  box <- leaves[first, c("x0", "y0", "x1", "y1")]
  col_rank <- match(round(box$x0, 1), sort(unique(round(box$x0, 1))))
  row_rank <- match(round(box$y0, 1), sort(unique(round(box$y0, 1))))
  idx <- match(paste(lay$ROW, lay$COL), paste(row_rank, col_rank))
  if (anyNA(idx)) {
    # Layouts that do not fill a grid by position fall back to drawing order.
    idx <- seq_len(nrow(lay))
  }
  fvars <- ggplot_facet_vars(built)
  key <- if (length(fvars)) {
    do.call(paste, c(lapply(fvars, function(v) paste0(v, "=", as.character(lay[[v]]))), sep = ", "))
  } else rep("", nrow(lay))
  coord <- class(built$layout$coord)[1]
  cartesian <- coord %in% c("CoordCartesian", "CoordFlip", "CoordFixed")
  rows <- lapply(seq_len(nrow(lay)), function(k) {
    pp <- built$layout$panel_params[[k]]
    b <- box[idx[k], ]
    sx <- scale_info(pp$x, cartesian)
    sy <- scale_info(pp$y, cartesian)
    data.frame(
      id = paste0(prefix, "panel", lay$PANEL[k]), key = key[k], vp = vps[idx[k]],
      x0 = b$x0, y0 = b$y0, x1 = b$x1, y1 = b$y1,
      x_type = sx$type, x_min = sx$min, x_max = sx$max, x_trans = sx$trans,
      y_type = sy$type, y_min = sy$min, y_max = sy$max, y_trans = sy$trans,
      stringsAsFactors = FALSE
    )
  })
  panels <- do.call(rbind, rows)
  rownames(panels) <- NULL
  leaf_panel <- stats::setNames(panels$id[match(seg, panels$vp)], leaves$id)
  list(panels = panels, leaf_panel = leaf_panel)
}

scale_info <- function(vs, cartesian) {
  if (!cartesian || is.null(vs) || is.null(vs$continuous_range)) {
    return(list(type = "unsupported", min = NA_real_, max = NA_real_, trans = NA_character_))
  }
  rng <- as.double(vs$continuous_range)
  discrete <- tryCatch(isTRUE(vs$is_discrete()), error = function(e) FALSE)
  trans <- tryCatch(vs$scale$get_transformation()$name, error = function(e) NULL) %||%
    tryCatch(vs$scale$trans$name, error = function(e) NULL) %||% NA_character_
  list(type = if (discrete) "discrete" else "continuous", min = rng[1], max = rng[2],
       trans = as.character(trans))
}

ggplot_describe <- function(plot) {
  list(
    layers = lapply(plot$layers, function(l) {
      list(geom = class(l$geom)[1], stat = class(l$stat)[1], position = class(l$position)[1])
    }),
    facet = class(plot$facet)[1],
    coord = class(plot$coordinates)[1]
  )
}

# ---- binding ----------------------------------------------------------------

# Pairings of layer leaves with built rows (core-bind.R checks them).
#
# Which layer drew a leaf is read from the gtable the engine drew, by
# construction (ggplot2 4.x, Facet$draw_panel_content and Coord$draw_panel):
# a panel grob's children are the coord's background, the facet's
# background, one grob per layer in layer order, the facet's foreground and
# the coord's foreground; with theme(panel.ontop = TRUE) both coord grobs come
# last. A panel whose children do not number layers + 4 is not paired. A
# layer grob built by Geom$draw_panel's default holds its groups' grobs in
# the order of factor(group), a fixed number per group; when its children
# divide evenly among the panel's groups, each leaf below child j is paired
# with group ceiling(j / (children / groups)) only.
#
# Rows are put on the device through the panel's scales (identify.R's
# mapping); infinite positions go to the panel's edges, as ggplot2 squishes
# them. Under coord_flip() the horizontal scale is the data's y.
ggplot_bind <- function(built, gtable, sub) {
  leaves <- sub$leaves
  unbound <- function(ids, reason) data.frame(leaf = ids, reason = rep(reason, length(ids)), stringsAsFactors = FALSE)
  if (is.null(gtable)) return(list(claims = list(), unbound = unbound(leaves$id, "the drawn gtable was not kept")))
  n_layers <- length(built$data)
  ontop <- isTRUE(built$plot$theme$panel.ontop %||% ggplot2::theme_get()$panel.ontop)
  pan_rows <- grep("^panel", gtable$layout$name)
  layer_of <- list()      # layer grob name -> layer index
  group_of <- list()      # layer grob name -> named child index (draw_group children)
  panel_names <- character()
  bad_panels <- character()
  for (j in pan_rows) {
    g <- gtable$grobs[[j]]
    kids <- g$children
    panel_names <- c(panel_names, g$name)
    if (length(kids) != n_layers + 4L) {
      bad_panels <- c(bad_panels, g$name)
      next
    }
    at <- (if (ontop) 1L else 2L) + seq_len(n_layers)
    for (i in seq_len(n_layers)) {
      lg <- kids[[at[i]]]
      layer_of[[lg$name]] <- i
      if (inherits(lg, "gTree") && length(lg$children)) {
        group_of[[lg$name]] <- stats::setNames(seq_along(lg$children), names(lg$children))
      }
    }
  }
  coord <- class(built$layout$coord)[1]
  flip <- identical(coord, "CoordFlip")
  claims <- list()
  ub <- unbound(character(), character())
  outside <- character()
  for (r in seq_len(nrow(leaves))) {
    lf <- leaves[r, ]
    seg <- strsplit(lf$path, "/", fixed = TRUE)[[1]]
    at <- match(TRUE, seg %in% panel_names)
    if (is.na(at)) {
      outside <- c(outside, lf$id)
      next
    }
    if (seg[at] %in% bad_panels) {
      ub <- rbind(ub, unbound(lf$id, sprintf("the panel holds other grobs than background, %d layer%s and foreground",
                                             n_layers, plural(n_layers))))
      next
    }
    child <- if (at < length(seg)) seg[at + 1L] else NA_character_
    i <- layer_of[[child %|NA|% ""]]
    if (is.null(i)) {
      outside <- c(outside, lf$id)
      next
    }
    pid <- lf$panel
    prow <- sub$panels[sub$panels$id %in% pid, , drop = FALSE]
    if (!nrow(prow)) {
      ub <- rbind(ub, unbound(lf$id, "the leaf lies in no panel with scales"))
      next
    }
    if (!all(c(prow$x_type, prow$y_type) %in% c("continuous", "discrete"))) {
      ub <- rbind(ub, unbound(lf$id, sprintf("the panel's scales cannot be mapped (%s)", coord)))
      next
    }
    d <- built$data[[i]]
    d$row <- seq_len(nrow(d))
    d <- d[as.character(d$PANEL) == sub("^panel", "", pid), , drop = FALSE]
    pred <- ggplot_rows_on_device(d, prow, flip)
    if (is.null(pred)) {
      ub <- rbind(ub, unbound(lf$id, "the layer's rows carry neither x and y nor xmin, xmax, ymin and ymax"))
      next
    }
    groups <- NULL
    gmap <- group_of[[child]]
    if (!is.null(gmap) && at + 2L <= length(seg) && seg[at + 2L] %in% names(gmap)) {
      gs <- sort(unique(pred$group))
      nk <- length(gmap)
      if (length(gs) && nk %% length(gs) == 0L) {
        per <- nk %/% length(gs)
        groups <- gs[ceiling(gmap[[seg[at + 2L]]] / per)]
      }
    }
    claims[[length(claims) + 1L]] <- list(leaf = lf$id, table = sprintf("built_layer%d", i),
                                          pred = pred, groups = groups)
  }
  list(claims = claims, unbound = ub, outside = outside)
}

`%|NA|%` <- function(a, b) if (length(a) != 1L || is.na(a)) b else a

# Built rows of one panel on the device: x, y and, where the layer has them,
# xmin, xmax, ymin, ymax, xend, yend; rows missing their required positions
# are dropped, as the geom drops them before drawing.
ggplot_rows_on_device <- function(d, prow, flip) {
  pos <- c("x", "y", "xmin", "xmax", "ymin", "ymax", "xend", "yend")
  if (flip) {
    swap <- c(x = "y", y = "x", xmin = "ymin", xmax = "ymax", ymin = "xmin", ymax = "xmax", xend = "yend", yend = "xend")
    hit <- names(d) %in% names(swap)
    names(d)[hit] <- swap[names(d)[hit]]
  }
  has <- function(cols) all(cols %in% names(d)) && !all(is.na(d[cols]))
  req <- if (has(c("x", "y"))) c("x", "y") else if (has(c("xmin", "xmax", "ymin", "ymax"))) c("xmin", "xmax", "ymin", "ymax") else NULL
  if (is.null(req)) return(NULL)
  num <- function(v) suppressWarnings(as.double(v))
  keep <- stats::complete.cases(as.data.frame(lapply(d[req], num)))
  d <- d[keep, , drop = FALSE]
  to_x <- function(v) {
    v <- num(v)
    out <- prow$x0 + (v - prow$x_min) / (prow$x_max - prow$x_min) * (prow$x1 - prow$x0)
    out[!is.na(v) & v == -Inf] <- prow$x0
    out[!is.na(v) & v == Inf] <- prow$x1
    out
  }
  to_y <- function(v) {
    v <- num(v)
    out <- prow$y1 - (v - prow$y_min) / (prow$y_max - prow$y_min) * (prow$y1 - prow$y0)
    out[!is.na(v) & v == -Inf] <- prow$y1
    out[!is.na(v) & v == Inf] <- prow$y0
    out
  }
  out <- data.frame(row = d$row, group = if ("group" %in% names(d)) d$group else rep(1L, nrow(d)))
  for (col in intersect(pos, names(d))) {
    out[[col]] <- if (startsWith(col, "x")) to_x(d[[col]]) else to_y(d[[col]])
  }
  out
}
