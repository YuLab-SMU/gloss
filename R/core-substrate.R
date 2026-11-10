# Capture by graphics-group delimiting plus probes (ADR-0001).
#
# Every leaf of the grid.force()d scene becomes
#   gTree(children = gList(probe, groupGrob(leaf without vp)), vp = leaf$vp)
# and the scene is drawn once on svglite. The device puts each leaf's output
# in its own <g id="group-k">; the probe records the viewport path, device
# box and native scales at draw time. Groups are then inlined in place of
# their <use>, so the scene keeps the device's drawing order.

#' Capture a figure into a substrate
#'
#' `gloss()` draws the figure once with svglite and traces every drawn
#' element to the leaf grob, viewport and panel that produced it. The result
#' is a read-only substrate plus the figure's data tables, each with an
#' inferred row key, and the context sniffed at capture time.
#'
#' The engine is chosen from the classes the registered engine plugins
#' declare, in the order of `class(x)`; `engine` overrides the choice.
#' Built-in engines handle ggplot2 plots, patchwork compositions,
#' ComplexHeatmap heatmaps, base graphics (a `recordedplot` or a function
#' that draws the plot, through gridGraphics) and any grid grob.
#'
#' A figure whose `print()` method is not a standard draw the engines follow
#' is refused with its reason: it could draw a different figure from the grob
#' gloss builds.
#'
#' Within each leaf the expected number of drawn elements is compared with
#' the number the device drew. A leaf whose counts differ keeps its
#' structure but is marked `count_mismatch` and is never bound to data rows.
#'
#' Leaves that draw at least `dense` non-text elements are kept as a raster
#' drawn by a PNG device from the same grob, plus a binary index of their
#' element geometry; queries treat them like any other leaf.
#'
#' @param x A figure: a ggplot, patchwork, `Heatmap`/`HeatmapList`,
#'   `recordedplot`, a function drawing a base plot, or a grob.
#' @param ... Passed to methods.
#' @param width,height Size in inches. Defaults to the current knitr chunk's
#'   figure size, or 7 by 5.
#' @param dense Element count from which a leaf is rasterised. `Inf` keeps
#'   every leaf as vector elements.
#' @param context Sniff context (code, data, engine, environment, document,
#'   git) at capture time.
#' @param engine Name of the engine plugin to use instead of dispatching on
#'   class.
#' @return A `gloss_figure`.
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   library(ggplot2)
#'   fig <- gloss(ggplot(mtcars, aes(wt, mpg)) + geom_point())
#'   fig
#'   head(gl_elements(fig))
#' }
#' @export
gloss <- function(x, ...) UseMethod("gloss")

#' @rdname gloss
#' @export
gloss.default <- function(x, ..., width = NULL, height = NULL, dense = 10000,
                          context = TRUE, engine = NULL) {
  expr <- substitute(x)
  call <- sys.call()
  # Record the call as the user wrote it, not as dispatched.
  if (identical(call[[1]], as.symbol("gloss.default"))) call[[1]] <- as.symbol("gloss")
  env <- parent.frame()
  size <- figure_size(width, height)
  eng <- find_engine(x, engine)
  gl_capture(x, eng, width = size$width, height = size$height, dense = dense,
             context = context, expr = expr, call = call, env = env,
             size_basis = size$basis)
}

figure_size <- function(width, height) {
  basis <- "argument"
  if ((is.null(width) || is.null(height)) && isTRUE(getOption("knitr.in.progress")) && has_pkg("knitr")) {
    width <- width %||% knitr::opts_current$get("fig.width")
    height <- height %||% knitr::opts_current$get("fig.height")
    basis <- "knitr chunk"
  }
  if (is.null(width) || is.null(height)) basis <- "default 7 x 5 in"
  list(width = as.double(width %||% 7), height = as.double(height %||% 5), basis = basis)
}

find_engine <- function(x, engine = NULL) {
  if (!is.null(engine)) return(gl_plugin("engine", engine))
  engines <- rev(plugins_of("engine"))
  for (cls in class(x)) {
    for (e in engines) if (cls %in% e$classes) return(e)
  }
  cli::cli_abort(c(
    "No engine plugin handles an object of class {.cls {class(x)}}.",
    i = "Registered engines: {.val {names(plugins_of('engine'))}}."
  ))
}

# A subclass with its own print() method can draw a different figure from the
# grob the engine builds: ggbreak's print.ggcut draws a cut axis, ggExtra's
# print.ggExtraPlot draws marginal plots. gloss captured the uncut plot / the
# gtable alone, with no error (bench 2026-11-10: exts-018, gallery-052).
# Refuse before capture instead of silently capturing another figure.
# Only print() is checked: extensions whose ggplot_build() returns something
# other than a built ggplot are already refused by build_ggplot().
standard_print_methods <- function() {
  classes <- c("ggplot2::ggplot", "ggplot", "patchwork", "gtable", "grob",
               "gList", "recordedplot", "function")
  out <- lapply(classes, function(cls) {
    tryCatch(utils::getS3method("print", cls, optional = TRUE), error = function(e) NULL)
  })
  out[!vapply(out, is.null, logical(1))]
}

check_print_dispatch <- function(x) {
  std <- standard_print_methods()
  for (cls in class(x)) {
    m <- tryCatch(utils::getS3method("print", cls, optional = TRUE),
                  error = function(e) NULL)
    if (is.null(m)) next
    if (any(vapply(std, function(f) identical(f, m), logical(1)))) return(invisible(NULL))
    cli::cli_abort(c(
      sprintf("%s has a custom print method (print.%s); gloss would capture another figure.",
              class(x)[1], cls),
      i = "The engine draws a grob built from the object. Draw the object's own print output as a grid scene instead."
    ))
  }
  invisible(NULL)
}

#' Capture with a given engine plugin
#'
#' The work behind [gloss()], for engine plugins and tests that already hold
#' the plugin object.
#'
#' @param x The figure.
#' @param engine An engine plugin, as returned by [gl_plugin()].
#' @param width,height Size in inches.
#' @param dense,context See [gloss()].
#' @param expr,call,env The expression, call and calling environment, used
#'   by context sniffers.
#' @param size_basis Where the size came from.
#' @return A `gloss_figure`.
#' @keywords internal
#' @export
gl_capture <- function(x, engine, width = 7, height = 5, dense = 10000,
                       context = TRUE, expr = NULL, call = NULL,
                       env = parent.frame(), size_basis = "argument") {
  check_print_dispatch(x)
  state <- engine$prepare(x, width, height)
  cap <- capture_scene(function() engine$grob(state), width, height)
  sub <- build_substrate(cap, width, height, dense)
  if (!is.null(engine$panels)) {
    pan <- engine$panels(state, sub)
    if (!is.null(pan)) {
      sub$panels <- pan$panels
      sub$leaves$panel <- unname(pan$leaf_panel[sub$leaves$id])
    }
  }
  tables <- if (!is.null(engine$tables)) engine$tables(state) else list()
  tables <- lapply(tables, new_table)
  names(tables) <- vapply(tables, `[[`, "", "name")
  fig <- new_figure(
    meta = list(
      gloss = gloss_version(),
      api = gloss_api_version,
      engine = engine$name,
      engine_version = engine$version,
      class = class(x),
      width = width,
      height = height,
      size_basis = size_basis,
      dense = as.double(dense),
      device = paste("svglite", pkg_version_or_na("svglite")),
      created = now_utc()
    ),
    substrate = sub,
    tables = tables,
    context = list(),
    plugins = plugin_row(engine)
  )
  if (isTRUE(context)) {
    input <- list(x = x, expr = expr, call = call, env = env, engine = engine$name,
                  state = state, tables = tables, width = width, height = height,
                  substrate = sub)
    sniffed <- sniff_context(input)
    fig$context <- sniffed$items
    fig$plugins <- rbind(fig$plugins, sniffed$plugins)
  }
  fig$meta$id <- substrate_id(fig$substrate)
  fig
}

new_figure <- function(meta, substrate, tables, context, plugins) {
  structure(list(meta = meta, substrate = substrate, tables = tables,
                 context = context, plugins = plugins, status = list()),
            class = "gloss_figure")
}

plugin_row <- function(p) {
  data.frame(kind = p$kind, name = p$name, version = p$version, package = p$package,
             stringsAsFactors = FALSE)
}

substrate_id <- function(sub) {
  ras <- vapply(sub$rasters, function(r) digest::digest(r, algo = "sha256", serialize = FALSE), "")
  digest::digest(paste(c(sub$scene, ras), collapse = "\n"), algo = "sha256", serialize = FALSE)
}

# ---- probe -----------------------------------------------------------------

probe_grob <- function(id, rec) {
  grid::gTree(name = paste0("gloss.probe.", id), cl = "gloss_probe", id = id, rec = rec)
}

#' @export
drawDetails.gloss_probe <- function(x, recording) {
  rec <- x$rec
  corners <- grid::deviceLoc(grid::unit(c(0, 1, 1, 0), "npc"), grid::unit(c(0, 0, 1, 1), "npc"))
  xs <- grid::convertX(corners$x, "in", valueOnly = TRUE)
  ys <- grid::convertY(corners$y, "in", valueOnly = TRUE)
  vp <- grid::current.viewport()
  path <- grid::current.vpPath()
  rec$n <- rec$n + 1L
  rec$order[rec$n] <- x$id
  rec$probe[[x$id]] <- list(
    vp = if (is.null(path)) "ROOT" else as.character(path),
    x = xs, y = ys,
    xscale = as.double(vp$xscale), yscale = as.double(vp$yscale)
  )
  invisible()
}

# ---- wrapping --------------------------------------------------------------

wrap_leaves <- function(x, parent, acc) {
  path <- c(parent, x$name)
  if (inherits(x, "gTree")) {
    kids <- x$children
    if (length(kids)) {
      nms <- names(kids)
      wrapped <- lapply(nms, function(nm) wrap_leaves(kids[[nm]], path, acc))
      new_kids <- do.call(grid::gList, wrapped)
      names(new_kids) <- nms
      x$children <- new_kids
    }
    return(x)
  }
  if (inherits(x, c("zeroGrob", "null"))) return(x)
  # A clipGrob draws nothing and sets the clip for what is drawn after it.
  # Inside a graphics group the clip would end with the group, and the next
  # leaves would be drawn unclipped: leave it in place, as a non-leaf.
  if (inherits(x, "clip")) return(x)
  acc$k <- acc$k + 1L
  id <- sprintf("L%03d", acc$k)
  acc$leaves[[id]] <- list(
    id = id, name = x$name, path = paste(path, collapse = "/"),
    class = class(x)[1], n_expected = expected_count(x)
  )
  v <- x$vp
  x$vp <- NULL
  acc$grobs[[id]] <- x
  grid::gTree(children = grid::gList(probe_grob(id, acc$rec), grid::groupGrob(x)),
              vp = v, name = x$name, cl = "gloss_wrap", id = id)
}

# How many SVG elements a leaf grob is expected to draw; NA when unknown.
expected_count <- function(g) {
  len <- function(u) if (is.null(u)) 0L else length(u)
  ids <- function(id, id.lengths) {
    if (!is.null(id)) return(length(unique(id)))
    if (!is.null(id.lengths)) return(length(id.lengths))
    1L
  }
  cls <- class(g)
  if ("points" %in% cls) return(max(len(g$x), len(g$y)))
  if ("text" %in% cls) return(length(g$label))
  if ("rect" %in% cls) return(max(len(g$x), len(g$y), len(g$width), len(g$height)))
  if ("circle" %in% cls) return(max(len(g$x), len(g$y), len(g$r)))
  if ("segments" %in% cls) return(max(len(g$x0), len(g$y0), len(g$x1), len(g$y1)))
  if ("polyline" %in% cls) return(ids(g$id, g$id.lengths))
  if ("polygon" %in% cls) return(ids(g$id, g$id.lengths))
  if ("pathgrob" %in% cls) return(if (is.null(g$pathId)) 1L else length(unique(g$pathId)))
  if ("lines" %in% cls) return(1L)
  if ("rastergrob" %in% cls) return(1L)
  NA_integer_
}

# ---- drawing ---------------------------------------------------------------

capture_scene <- function(make_grob, width, height) {
  rec <- new_env()
  rec$n <- 0L
  rec$order <- character()
  rec$probe <- list()
  acc <- new_env()
  acc$k <- 0L
  acc$leaves <- list()
  acc$grobs <- list()
  acc$rec <- rec

  s <- svglite::svgstring(width = width, height = height, standalone = TRUE)
  dev <- grDevices::dev.cur()
  closed <- FALSE
  on.exit(if (!closed && dev %in% grDevices::dev.list()) grDevices::dev.off(dev), add = TRUE)
  # Devices that support graphics groups report their compositing operators.
  comp <- grDevices::dev.capabilities("compositing")$compositing
  if (!is.character(comp) || !length(comp)) {
    cli::cli_abort("The capture device does not support graphics groups (needs R >= 4.2 and svglite >= 2.2).")
  }
  grid::grid.newpage()
  g <- make_grob()
  grDevices::dev.set(dev)
  if (inherits(g, "gList")) g <- grid::gTree(children = g)
  forced <- grid::grid.force(g)
  wrapped <- wrap_leaves(forced, character(), acc)
  grid::grid.newpage()
  grid::grid.draw(wrapped)
  grDevices::dev.off(dev)
  closed <- TRUE
  pages <- as.character(s())
  # The scene is forced on one page and drawn on the next; keep the last.
  list(svg = pages[length(pages)], leaves = acc$leaves, probes = rec$probe,
       order = rec$order, wrapped = wrapped, grobs = acc$grobs)
}

# ---- parsing ---------------------------------------------------------------

svg_ns <- function(doc) c(d1 = "http://www.w3.org/2000/svg")

prim_tags <- c("circle", "rect", "line", "polyline", "polygon", "path", "text", "image")

prim_xpath <- function(root = "//") {
  sel <- paste0("self::d1:", prim_tags, collapse = " or ")
  sprintf("%s*[(%s) and not(ancestor::d1:defs) and not(ancestor::d1:clipPath) and not(ancestor::d1:mask) and not(ancestor::d1:pattern)]", root, sel)
}

build_substrate <- function(cap, width, height, dense = Inf) {
  doc <- xml2::read_xml(cap$svg)
  ns <- svg_ns(doc)
  n_probe <- length(cap$order)
  groups <- xml2::xml_find_all(doc, "//d1:defs/d1:g[starts-with(@id, 'group-')]", ns)
  gids <- xml2::xml_attr(groups, "id")
  if (length(gids) != n_probe) {
    cli::cli_abort(c(
      "Capture integrity check failed: {n_probe} probe{?s} drew but the device wrote {length(gids)} group{?s}.",
      i = "A leaf that defines its own graphics group cannot be attributed; please report the figure."
    ))
  }
  # R does not apply an active viewport mask inside a graphics group, so a
  # masked leaf would be drawn unmasked. Refuse rather than degrade.
  if (length(xml2::xml_find_all(doc, "//d1:mask", ns))) {
    cli::cli_abort(c(
      "The figure uses a mask, which group capture cannot keep.",
      i = "R does not apply a viewport mask to graphics groups, so masked leaves would be drawn unmasked."
    ))
  }
  uses <- xml2::xml_find_all(doc, "//d1:use", ns)
  hrefs <- sub("^#", "", xml2::xml_attr(uses, "href"))
  group_of <- match(paste0("group-", seq_len(n_probe) - 1L), gids)
  use_of <- match(paste0("group-", seq_len(n_probe) - 1L), hrefs)
  if (anyNA(group_of) || anyNA(use_of)) {
    cli::cli_abort("Capture integrity check failed: a group is missing its definition or its <use>.")
  }
  for (k in seq_len(n_probe)) {
    gnode <- groups[[group_of[k]]]
    xml2::xml_replace(uses[[use_of[k]]], gnode, .copy = FALSE)
    xml2::xml_set_attr(gnode, "id", NULL)
    xml2::xml_set_attr(gnode, "data-gloss-leaf", cap$order[k])
  }
  empty_defs <- xml2::xml_find_all(doc, "//d1:defs[not(*)]", ns)
  xml2::xml_remove(empty_defs)

  leaves <- leaves_table(cap)
  elements <- elements_table(doc, ns)
  counts <- table(factor(elements$leaf, levels = leaves$id))
  leaves$n_drawn <- as.integer(counts[leaves$id])
  leaves$status <- ifelse(is.na(leaves$n_expected), "unknown",
                          ifelse(leaves$n_expected == leaves$n_drawn, "ok", "count_mismatch"))
  leaves$bindable <- leaves$status == "ok"
  leaves$dense <- FALSE
  leaves$panel <- NA_character_

  rasters <- list()
  text_leaves <- unique(elements$leaf[elements$tag == "text"])
  dense_ids <- leaves$id[leaves$n_drawn >= dense & !leaves$id %in% text_leaves]
  if (length(dense_ids)) {
    rasters <- rasterize_leaves(cap, dense_ids, width, height)
    for (id in dense_ids) {
      g <- xml2::xml_find_first(doc, sprintf("//d1:g[@data-gloss-leaf='%s']", id), ns)
      xml2::xml_remove(xml2::xml_children(g))
      xml2::xml_set_attr(g, "data-gloss-raster", "true")
      xml2::xml_add_child(g, "image", x = "0", y = "0",
                          width = sprintf("%.2f", width * pt_per_in),
                          height = sprintf("%.2f", height * pt_per_in),
                          preserveAspectRatio = "none",
                          href = paste0("gloss-raster:", id))
    }
    leaves$dense <- leaves$id %in% dense_ids
  }

  list(
    scene = as.character(doc),
    leaves = leaves,
    elements = elements,
    panels = empty_panels(),
    rasters = rasters
  )
}

leaves_table <- function(cap) {
  L <- cap$leaves
  ids <- names(L)
  probe <- function(id, field, i = NULL) {
    p <- cap$probes[[id]]
    if (is.null(p)) return(NA_real_)
    v <- p[[field]]
    if (is.null(i)) v else v[i]
  }
  box <- t(vapply(ids, function(id) {
    p <- cap$probes[[id]]
    if (is.null(p)) return(rep(NA_real_, 4))
    c(min(p$x), max(p$x), min(p$y), max(p$y))
  }, numeric(4)))
  if (!length(ids)) box <- matrix(numeric(), 0, 4)
  data.frame(
    id = ids,
    name = vapply(L, `[[`, "", "name"),
    path = vapply(L, `[[`, "", "path"),
    class = vapply(L, `[[`, "", "class"),
    vp = vapply(ids, function(id) cap$probes[[id]]$vp %||% NA_character_, ""),
    # device box in inches with the origin bottom-left; converted below
    bx0 = box[, 1], bx1 = box[, 2], by0 = box[, 3], by1 = box[, 4],
    xscale0 = vapply(ids, probe, 1, field = "xscale", i = 1L),
    xscale1 = vapply(ids, probe, 1, field = "xscale", i = 2L),
    yscale0 = vapply(ids, probe, 1, field = "yscale", i = 1L),
    yscale1 = vapply(ids, probe, 1, field = "yscale", i = 2L),
    n_expected = vapply(L, function(l) as.integer(l$n_expected), integer(1)),
    stringsAsFactors = FALSE, row.names = NULL
  ) |> leaves_to_pt(cap)
}

# Device inches (origin bottom-left) to SVG user units (origin top-left).
leaves_to_pt <- function(df, cap) {
  h <- svg_height_pt(cap$svg)
  df$x0 <- round_pt(df$bx0 * pt_per_in)
  df$x1 <- round_pt(df$bx1 * pt_per_in)
  df$y0 <- round_pt(h - df$by1 * pt_per_in)
  df$y1 <- round_pt(h - df$by0 * pt_per_in)
  df[c("id", "name", "path", "class", "vp", "x0", "y0", "x1", "y1",
       "xscale0", "xscale1", "yscale0", "yscale1", "n_expected")]
}

svg_height_pt <- function(svg) {
  vb <- regmatches(svg, regexpr("viewBox='[^']*'", svg))
  as.numeric(strsplit(sub("viewBox='([^']*)'", "\\1", vb), " ")[[1]][4])
}

empty_panels <- function() {
  data.frame(id = character(), key = character(), vp = character(),
             x0 = double(), y0 = double(), x1 = double(), y1 = double(),
             x_type = character(), x_min = double(), x_max = double(), x_trans = character(),
             y_type = character(), y_min = double(), y_max = double(), y_trans = character(),
             stringsAsFactors = FALSE)
}

num_attr <- function(nodes, a) suppressWarnings(as.numeric(sub("px$", "", xml2::xml_attr(nodes, a))))

# Value of one CSS property in each style attribute. Styles repeat heavily
# (one per leaf, typically), so only the distinct strings are parsed.
style_value <- function(style, prop) {
  u <- unique(style)
  pat <- paste0("(?:^|;)\\s*", prop, ":\\s*([^;]+)")
  has <- grepl(pat, u, perl = TRUE)
  val <- rep(NA_character_, length(u))
  val[has] <- trimws(sub(paste0("^.*?", pat, ".*$"), "\\1", u[has], perl = TRUE))
  val[match(style, u)]
}

elements_table <- function(doc, ns) {
  nodes <- xml2::xml_find_all(doc, prim_xpath(), ns)
  n <- length(nodes)
  tag <- xml2::xml_name(nodes)
  owner <- xml2::xml_attr(xml2::xml_find_first(nodes, "ancestor::d1:g[@data-gloss-leaf][1]", ns), "data-gloss-leaf")
  style <- xml2::xml_attr(nodes, "style")
  style[is.na(style)] <- ""
  box <- element_boxes(nodes, tag, style)
  text <- rep(NA_character_, n)
  is_text <- tag == "text"
  if (any(is_text)) text[is_text] <- xml2::xml_text(nodes[is_text])
  ord <- stats_ave_seq(owner)
  data.frame(
    id = if (n) paste0("e", seq_len(n)) else character(),
    leaf = owner,
    tag = tag,
    ordinal = ord,
    x0 = round_pt(box$x0), y0 = round_pt(box$y0),
    x1 = round_pt(box$x1), y1 = round_pt(box$y1),
    fill = style_value(style, "fill"),
    stroke = style_value(style, "stroke"),
    text = text,
    stringsAsFactors = FALSE
  )
}

# Position of each element within its leaf (1-based, document order).
stats_ave_seq <- function(owner) {
  out <- rep(NA_integer_, length(owner))
  ok <- !is.na(owner)
  if (any(ok)) {
    o <- owner[ok]
    out[ok] <- as.integer(stats_seq_by(o))
  }
  out
}

stats_seq_by <- function(g) {
  idx <- seq_along(g)
  ord <- order(match(g, unique(g)), idx)
  runs <- rle(g[ord])
  seqs <- sequence(runs$lengths)
  out <- integer(length(g))
  out[ord] <- seqs
  out
}

pair_range <- function(s) {
  nums <- regmatches(s, gregexpr("-?[0-9]*\\.?[0-9]+(?:[eE][-+]?[0-9]+)?", s, perl = TRUE))
  t(vapply(nums, function(v) {
    v <- as.numeric(v)
    if (length(v) < 2L) return(rep(NA_real_, 4))
    xs <- v[c(TRUE, FALSE)]
    ys <- v[c(FALSE, TRUE)]
    c(min(xs), max(xs), min(ys), max(ys))
  }, numeric(4)))
}

element_boxes <- function(nodes, tag, style) {
  n <- length(nodes)
  x0 <- x1 <- y0 <- y1 <- rep(NA_real_, n)
  set <- function(i, a, b, c, d) {
    x0[i] <<- a
    x1[i] <<- b
    y0[i] <<- c
    y1[i] <<- d
  }
  i <- which(tag == "circle")
  if (length(i)) {
    cx <- num_attr(nodes[i], "cx")
    cy <- num_attr(nodes[i], "cy")
    r <- num_attr(nodes[i], "r")
    set(i, cx - r, cx + r, cy - r, cy + r)
  }
  i <- which(tag %in% c("rect", "image"))
  if (length(i)) {
    x <- num_attr(nodes[i], "x")
    y <- num_attr(nodes[i], "y")
    w <- num_attr(nodes[i], "width")
    h <- num_attr(nodes[i], "height")
    x[is.na(x)] <- 0
    y[is.na(y)] <- 0
    pct <- grepl("%", xml2::xml_attr(nodes[i], "width"))
    if (any(pct)) {
      root <- xml2::xml_root(nodes[[1]])
      vb <- as.numeric(strsplit(xml2::xml_attr(root, "viewBox"), " ")[[1]])
      w[pct] <- vb[3]
      h[pct] <- vb[4]
    }
    set(i, pmin(x, x + w), pmax(x, x + w), pmin(y, y + h), pmax(y, y + h))
  }
  i <- which(tag == "line")
  if (length(i)) {
    ax <- num_attr(nodes[i], "x1")
    ay <- num_attr(nodes[i], "y1")
    bx <- num_attr(nodes[i], "x2")
    by <- num_attr(nodes[i], "y2")
    set(i, pmin(ax, bx), pmax(ax, bx), pmin(ay, by), pmax(ay, by))
  }
  i <- which(tag %in% c("polyline", "polygon"))
  if (length(i)) {
    b <- pair_range(xml2::xml_attr(nodes[i], "points"))
    set(i, b[, 1], b[, 2], b[, 3], b[, 4])
  }
  i <- which(tag == "path")
  if (length(i)) {
    b <- pair_range(xml2::xml_attr(nodes[i], "d"))
    set(i, b[, 1], b[, 2], b[, 3], b[, 4])
  }
  i <- which(tag == "text")
  if (length(i)) {
    b <- text_boxes(nodes[i], style[i])
    set(i, b[, 1], b[, 2], b[, 3], b[, 4])
  }
  list(x0 = x0, x1 = x1, y0 = y0, y1 = y1)
}

# Text boxes from the anchor point, textLength and font size. Ascent and
# descent are estimated as 0.8 and 0.2 of the font size, so the box is an
# approximation; rotation from the transform is applied exactly.
text_boxes <- function(nodes, style) {
  fs <- suppressWarnings(as.numeric(sub("px$", "", style_value(style, "font-size"))))
  fs[is.na(fs)] <- 12
  w <- num_attr(nodes, "textLength")
  txt <- xml2::xml_text(nodes)
  w[is.na(w)] <- 0.6 * fs[is.na(w)] * nchar(txt[is.na(w)])
  anchor <- xml2::xml_attr(nodes, "text-anchor")
  anchor[is.na(anchor)] <- "start"
  lx0 <- ifelse(anchor == "middle", -w / 2, ifelse(anchor == "end", -w, 0))
  lx1 <- lx0 + w
  ly0 <- -0.8 * fs
  ly1 <- 0.2 * fs
  tr <- xml2::xml_attr(nodes, "transform")
  x <- num_attr(nodes, "x")
  y <- num_attr(nodes, "y")
  tx <- ifelse(is.na(x), 0, x)
  ty <- ifelse(is.na(y), 0, y)
  ang <- rep(0, length(nodes))
  has_tr <- !is.na(tr)
  if (any(has_tr)) {
    tt <- regmatches(tr[has_tr], regexec("translate\\(\\s*([-0-9.eE]+)[ ,]+([-0-9.eE]+)\\s*\\)", tr[has_tr]))
    rr <- regmatches(tr[has_tr], regexec("rotate\\(\\s*([-0-9.eE]+)", tr[has_tr]))
    tx[has_tr] <- tx[has_tr] + vapply(tt, function(v) if (length(v) == 3L) as.numeric(v[2]) else 0, 1)
    ty[has_tr] <- ty[has_tr] + vapply(tt, function(v) if (length(v) == 3L) as.numeric(v[3]) else 0, 1)
    ang[has_tr] <- vapply(rr, function(v) if (length(v) == 2L) as.numeric(v[2]) else 0, 1)
  }
  th <- ang * pi / 180
  cx <- cbind(lx0, lx1, lx1, lx0)
  cy <- cbind(ly0, ly0, ly1, ly1)
  rx <- cos(th) * cx - sin(th) * cy + tx
  ry <- sin(th) * cx + cos(th) * cy + ty
  cbind(apply(rx, 1, min), apply(rx, 1, max), apply(ry, 1, min), apply(ry, 1, max))
}

# ---- dense leaves -----------------------------------------------------------

# Draw only the dense leaves, each with its own viewport, on a transparent
# PNG device of the same size. Everything else is replaced by nothing, so
# viewports and clipping are those of the captured scene.
rasterize_leaves <- function(cap, ids, width, height, dpi = 144) {
  out <- list()
  for (id in ids) {
    tree <- keep_only_leaf(cap$wrapped, id, cap$grobs)
    out[[id]] <- render_png(tree, width, height, dpi)
  }
  out
}

keep_only_leaf <- function(x, id, grobs) {
  if (inherits(x, "gloss_wrap")) {
    if (identical(x$id, id)) {
      return(grid::gTree(children = grid::gList(grobs[[id]]), vp = x$vp, name = x$name))
    }
    return(grid::nullGrob(name = x$name))
  }
  if (inherits(x, "gTree") && length(x$children)) {
    nms <- names(x$children)
    kids <- lapply(nms, function(nm) keep_only_leaf(x$children[[nm]], id, grobs))
    new_kids <- do.call(grid::gList, kids)
    names(new_kids) <- nms
    x$children <- new_kids
  }
  x
}

render_png <- function(tree, width, height, dpi) {
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f), add = TRUE)
  if (has_pkg("ragg")) {
    ragg::agg_png(f, width = width, height = height, units = "in", res = dpi, background = "transparent")
  } else {
    grDevices::png(f, width = width, height = height, units = "in", res = dpi, bg = "transparent")
  }
  dev <- grDevices::dev.cur()
  tryCatch({
    grid::grid.newpage()
    grid::grid.draw(tree)
  }, finally = grDevices::dev.off(dev))
  readBin(f, "raw", file.size(f))
}

# ---- printing ---------------------------------------------------------------

#' @export
print.gloss_figure <- function(x, ...) {
  s <- x$substrate
  m <- x$meta
  cat(sprintf("<gloss figure> %s engine, %g x %g in\n", m$engine %||% "unknown",
              m$width %||% NA, m$height %||% NA))
  n_el <- nrow(s$elements)
  owned <- sum(!is.na(s$elements$leaf))
  cat(sprintf("  %d elements from %d leaves (%d without a leaf)\n", n_el, nrow(s$leaves), n_el - owned))
  if (nrow(s$leaves)) {
    st <- table(s$leaves$status)
    cat(sprintf("  leaf counts: %s\n", paste(sprintf("%s %d", names(st), as.integer(st)), collapse = ", ")))
    if (any(s$leaves$dense)) cat(sprintf("  %d dense leaf rasterised\n", sum(s$leaves$dense)))
  }
  if (nrow(s$panels)) cat(sprintf("  %d panel%s\n", nrow(s$panels), if (nrow(s$panels) > 1) "s" else ""))
  if (length(x$tables)) {
    for (t in x$tables) {
      cat(sprintf("  table %s: %s rows, key %s (rule %s)%s\n", t$name,
                  if (is.null(t$data)) "?" else nrow(t$data),
                  paste(t$key, collapse = " + "), t$key_rule,
                  if (!is.null(t$status) && !identical(t$status, "ok")) paste0(" [", t$status, "]") else ""))
    }
  }
  if (length(x$context)) {
    found <- vapply(x$context, function(i) isTRUE(i$found), logical(1))
    listing <- function(v) if (length(v)) paste(v, collapse = ", ") else "none"
    cat(sprintf("  context found: %s; not found: %s\n",
                listing(names(x$context)[found]), listing(names(x$context)[!found])))
  }
  if (length(x$status)) {
    for (nm in names(x$status)) cat(sprintf("  status %s: %s\n", nm, paste(format(x$status[[nm]]), collapse = ", ")))
  }
  invisible(x)
}

# ---- regression signature -----------------------------------------------------

# Tag, attributes and text of every drawn primitive in document order, used
# to check that a captured scene draws exactly what plain svglite draws.
# Attributes added by gloss (data-gloss-*) are ignored.
scene_signatures <- function(svg) {
  doc <- xml2::read_xml(svg)
  nodes <- xml2::xml_find_all(doc, prim_xpath(), svg_ns(doc))
  vapply(nodes, function(n) {
    a <- xml2::xml_attrs(n)
    a <- a[!startsWith(names(a), "data-gloss-")]
    paste(xml2::xml_name(n), paste(sprintf("%s=%s", names(a), a), collapse = " "), xml2::xml_text(n))
  }, "")
}

plain_svg <- function(draw, width, height) {
  s <- svglite::svgstring(width = width, height = height, standalone = TRUE)
  dev <- grDevices::dev.cur()
  tryCatch(draw(), finally = grDevices::dev.off(dev))
  pages <- as.character(s())
  pages[length(pages)]
}
