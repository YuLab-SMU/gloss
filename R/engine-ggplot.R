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
# background, what each layer draws in that panel in layer order, the
# facet's foreground and the coord's foreground; with
# theme(panel.ontop = TRUE) both coord grobs come last. A layer adds no child
# where it draws NULL, and several where it draws a gList (bench exts-022:
# a ggrepel layer with nothing to label in its panel); how many, each
# layer's own draw_geom() says. A panel whose children do not add up is not
# paired.
#
# Below a layer's grob: with ggplot2's default Geom$draw_panel, its children
# are its groups' grobs in the order of factor(group), a fixed number per
# group, and each leaf below child j is paired with that group only. A geom
# with a draw_panel of its own that draws a fixed number of children per row
# (geom_label: bench gallery-029) has each leaf paired with that row only.
# Otherwise the leaf is paired with all the layer's rows in the panel.
#
# Rows are put on the device through the coord's own transform with the
# panel's params, as ggplot2 draws them, then the panel's box; infinite
# positions go to the panel's edges, as ggplot2 squishes them. Under a coord
# that is not linear (coord_polar(): circular and fan trees, bench tree-025,
# -038, -057) points go through the transform one by one; a segment's ends
# do too, and the path the coord munches between them is compared by its
# ends (core-bind.R). What the coord munches without ends (a line through
# its group, a rectangle) is not compared, and says so (plan
# 2026-11-11-tree-binding, Task 3).
ggplot_bind <- function(built, gtable, sub, prefix = "") {
  leaves <- sub$leaves
  unbound <- function(ids, reason) data.frame(leaf = ids, reason = rep(reason, length(ids)), stringsAsFactors = FALSE)
  if (is.null(gtable)) return(list(claims = list(), unbound = unbound(leaves$id, "the drawn gtable was not kept")))
  n_layers <- length(built$data)
  layers <- built$plot$layers
  ontop <- isTRUE(built$plot$theme$panel.ontop %||% ggplot2::theme_get()$panel.ontop)
  drawn_counts <- ggplot_layer_children(built)
  default_panel <- vapply(layers, function(l) ggplot_default_draw_panel(l$geom), logical(1))
  pan_rows <- grep("^panel", gtable$layout$name)
  layer_of <- list()      # layer grob name -> layer index
  kids_of <- list()       # layer grob name -> its children's names
  panel_names <- character()
  bad_panels <- character()
  for (j in pan_rows) {
    g <- gtable$grobs[[j]]
    kids <- g$children
    panel_names <- c(panel_names, g$name)
    k <- suppressWarnings(as.integer(sub("^panel-([0-9]+)[.].*$", "\\1", g$name)))
    n_i <- if (is.null(drawn_counts) || is.na(k)) rep(1L, n_layers) else vapply(drawn_counts, function(cn) cn[k], 1L)
    if (anyNA(n_i) || length(kids) != sum(n_i) + 4L) {
      bad_panels <- c(bad_panels, g$name)
      next
    }
    pos <- (if (ontop) 1L else 2L) + cumsum(c(0L, n_i))[seq_len(n_layers)]
    for (i in seq_len(n_layers)) {
      for (c in seq_len(n_i[i])) {
        lg <- kids[[pos[i] + c]]
        layer_of[[lg$name]] <- i
        # a layer that draws a gList adds several children: no groups below them
        if (n_i[i] == 1L && inherits(lg, "gTree") && length(lg$children)) kids_of[[lg$name]] <- names(lg$children)
      }
    }
  }
  coord <- class(built$layout$coord)[1]
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
      ub <- rbind(ub, unbound(lf$id, "the panel's children are not background, what each layer draws, and foreground"))
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
    d <- built$data[[i]]
    d$row <- seq_len(nrow(d))
    panel_k <- sub(paste0("^", prefix, "panel"), "", pid)
    d <- d[as.character(d$PANEL) == panel_k, , drop = FALSE]
    d <- ggplot_rows_drawn(d, layers[[i]])
    pp <- built$layout$panel_params[[as.integer(panel_k)]]
    pred <- tryCatch(ggplot_rows_on_device(d, prow, built$layout$coord, pp),
                     error = function(e) sprintf("the coord's transform failed (%s): %s", coord, conditionMessage(e)))
    if (is.character(pred)) {
      ub <- rbind(ub, unbound(lf$id, pred))
      next
    }
    if (is.null(pred)) {
      ub <- rbind(ub, unbound(lf$id, "the layer's rows carry neither x and y nor xmin, xmax, ymin and ymax"))
      next
    }
    groups <- NULL
    rows <- NULL
    kn <- kids_of[[child]]
    if (!is.null(kn) && at + 2L <= length(seg) && seg[at + 2L] %in% kn) {
      j <- match(seg[at + 2L], kn)
      nk <- length(kn)
      gs <- sort(unique(pred$group))
      if (default_panel[i] && length(gs) && nk %% length(gs) == 0L) {
        groups <- gs[ceiling(j / (nk %/% length(gs)))]
      } else if (!default_panel[i] && nrow(pred) && nk %% nrow(pred) == 0L) {
        rows <- pred$row[ceiling(j / (nk %/% nrow(pred)))]
      }
    }
    linear <- !isFALSE(attr(pred, "linear"))
    # rows with bounds (bars, tiles) are drawn under a coord that is not
    # linear as polygons munched along it; the rows of a label stacked on
    # them carry the stack's bounds too, so the core decides by the tag
    rect_reason <- if (!linear && all(c("xmin", "xmax", "ymin", "ymax") %in% names(d)) &&
                       !all(is.na(d[c("xmin", "xmax", "ymin", "ymax")]))) {
      sprintf("rectangles are drawn as polygons munched along the coord (%s); no comparison for them", coord)
    }
    claims[[length(claims) + 1L]] <- list(leaf = lf$id, table = sprintf("%sbuilt_layer%d", prefix, i),
                                          pred = pred, groups = groups, rows = rows,
                                          linear = linear, coord = coord, rect_reason = rect_reason)
  }
  list(claims = claims, unbound = ub, outside = outside)
}

# For each layer, how many children it adds to each panel: 0 where it draws
# NULL, the length of a gList, else 1. NULL when a layer cannot be drawn
# again outside ggplot_gtable(); the binder then expects one child per layer.
ggplot_layer_children <- function(built) {
  out <- lapply(seq_along(built$plot$layers), function(i) {
    l <- built$plot$layers[[i]]
    gr <- tryCatch(suppressWarnings(suppressMessages(l$draw_geom(built$data[[i]], built$layout))),
                   error = function(e) NULL)
    if (is.null(gr)) return(NULL)
    vapply(gr, function(x) if (is.null(x)) 0L else if (inherits(x, "gList")) length(x) else 1L, 1L)
  })
  if (any(vapply(out, is.null, logical(1)))) NULL else out
}

# The rows a layer draws, as its geom gets them (plan 2026-11-11-tree-binding,
# Task 6):
# - a geom with ggplot2's default Geom$handle_na() drops rows missing a
#   required or non-missing aesthetic before drawing (bench tree-003: NA
#   labels at a tree's tips), as remove_missing() does;
# - a geom whose draw_panel() takes nudge_x or nudge_y adds the layer's
#   value to x or y before the coord's transform (bench tree-041: ggtree's
#   GeomSegmentGGtree adds nudge_x to x, not xend; ggimage's GeomImage both).
#   The rows do not hold it; the binder checks the moved rows like any other.
ggplot_rows_drawn <- function(d, layer) {
  geom <- layer$geom
  inner <- function(m) tryCatch(environment(m)$f, error = function(e) NULL)
  if (identical(inner(geom$handle_na), inner(ggplot2::Geom$handle_na))) {
    vars <- intersect(c(geom$required_aes, geom$non_missing_aes), names(d))
    if (length(vars)) d <- d[stats::complete.cases(d[vars]), , drop = FALSE]
  }
  args <- names(formals(inner(geom$draw_panel) %||% function() NULL))
  params <- layer$computed_geom_params %||% layer$geom_params %||% list()
  for (ax in c("x", "y")) {
    nm <- paste0("nudge_", ax)
    v <- params[[nm]]
    if (nm %in% args && is.numeric(v) && length(v) && ax %in% names(d)) {
      d[[ax]] <- suppressWarnings(as.double(d[[ax]])) + v
    }
  }
  d
}

# Whether a geom draws its panel with ggplot2's default Geom$draw_panel (one
# grob per group, from draw_group).
ggplot_default_draw_panel <- function(geom) {
  f <- tryCatch(environment(geom$draw_panel)$f, error = function(e) NULL)
  d <- tryCatch(environment(ggplot2::Geom$draw_panel)$f, error = function(e) NULL)
  !is.null(f) && !is.null(d) && identical(f, d)
}

`%|NA|%` <- function(a, b) if (length(a) != 1L || is.na(a)) b else a

# Built rows of one panel on the device: x, y and, where the layer has them,
# xmin, xmax, ymin, ymax, xend, yend; rows missing their required positions
# are dropped, as the geom drops them before drawing. Positions go through
# the coord's transform with the panel's params (npc of the panel), then the
# panel's box. A linear coord transforms every position aesthetic at once
# (coord_flip() swaps them); one that is not linear transforms points, so x,
# y and the ends xend, yend are each transformed as a point, and the result
# says so in its attribute `linear`.
ggplot_rows_on_device <- function(d, prow, coord, pp) {
  pos <- c("x", "y", "xmin", "xmax", "ymin", "ymax", "xend", "yend")
  has <- function(cols) all(cols %in% names(d)) && !all(is.na(d[cols]))
  req <- if (has(c("x", "y"))) c("x", "y") else if (has(c("xmin", "xmax", "ymin", "ymax"))) c("xmin", "xmax", "ymin", "ymax") else NULL
  if (is.null(req)) return(NULL)
  num <- function(v) suppressWarnings(as.double(v))
  keep <- stats::complete.cases(as.data.frame(lapply(d[req], num)))
  d <- d[keep, , drop = FALSE]
  linear <- isTRUE(tryCatch(coord$is_linear(), error = function(e) FALSE))
  have <- intersect(pos, names(d))
  npc <- if (linear) {
    t <- coord$transform(as.data.frame(lapply(d[have], num)), pp)
    t[intersect(pos, names(t))]
  } else {
    point <- function(cx, cy) {
      z <- coord$transform(data.frame(x = num(d[[cx]]), y = num(d[[cy]])), pp)
      stats::setNames(data.frame(z$x, z$y), c(cx, cy))
    }
    out <- point("x", "y")
    if (all(c("xend", "yend") %in% have)) out <- cbind(out, point("xend", "yend"))
    out
  }
  out <- data.frame(row = d$row, group = if ("group" %in% names(d)) d$group else rep(1L, nrow(d)))
  # stat_align()'s padding rows close an area's polygon; its outline leaves
  # them out (GeomRibbon$draw_group)
  if ("align_padding" %in% names(d)) out$pad <- d$align_padding %in% TRUE
  for (col in intersect(pos, names(npc))) {
    v <- npc[[col]]
    out[[col]] <- if (startsWith(col, "x")) prow$x0 + v * (prow$x1 - prow$x0) else prow$y1 - v * (prow$y1 - prow$y0)
  }
  # Text and labels are placed from their row by their justification and
  # angle; core-bind.R compares them in the label's own frame.
  for (col in intersect(c("hjust", "vjust"), names(d))) out[[col]] <- just_value(d[[col]])
  if ("angle" %in% names(d)) out$angle <- num(d$angle)
  if ("label" %in% names(d)) out$label <- as.character(d$label)
  # A point's shape says which parts its symbol draws (core-bind.R); a shape
  # by name is turned into a number as GeomPoint$draw_panel() does it.
  if ("shape" %in% names(d)) out$shape <- ggplot_shape(d$shape)
  attr(out, "linear") <- linear
  out
}

ggplot_shape <- function(v) {
  if (!is.character(v)) return(v)
  tr <- tryCatch(getExportedValue("ggplot2", "translate_shape_string"), error = function(e) NULL)
  if (is.null(tr)) return(v)
  tryCatch(tr(v), error = function(e) v)
}

# Justification as a number: ggplot2 accepts names as well. "inward" and
# "outward" depend on the label's position and give NA; the comparison then
# takes the label as justified where svglite anchored it.
just_value <- function(v) {
  if (is.numeric(v)) return(as.double(v))
  v <- as.character(v)
  out <- suppressWarnings(as.double(v))
  key <- c(left = 0, bottom = 0, center = 0.5, centre = 0.5, middle = 0.5, right = 1, top = 1)
  hit <- is.na(out) & v %in% names(key)
  out[hit] <- key[v[hit]]
  out
}
