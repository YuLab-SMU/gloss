# Page capture, spike functions (2026-11-10). Not package code.
#
# Idea under test: capture the PAGE a figure's own code draws on svglite,
# instead of a grob that an engine builds from the object (ggplot_gtable(),
# patchworkGrob(), echoGrob(), grid.grab()). Two routes, by what is on the
# device's display list:
#
#   grid page  The grid display list is forced and wrapped IN PLACE (every leaf
#              becomes probe + group, as in ADR-0001) and redrawn by grid
#              itself (grid.refresh()). No grid.grab(), no engine-built grob.
#   base page  The recorded display list is replayed one entry at a time on
#              svglite, as replayPlot() plays it, and the device is read after
#              each entry. No gridGraphics.
#
# Needs gloss internals on the search path:
#   pkgload::load_all(".", export_all = TRUE, helpers = FALSE)

# Primitives without a match in the other scene, either way (multiset).
diffn <- function(a, b) {
  ta <- table(a); tb <- table(b); cm <- intersect(names(ta), names(tb))
  length(a) + length(b) - 2L * sum(pmin(ta[cm], tb[cm]))
}

# An open svglite page leaves its clip groups open.
close_groups <- function(x) {
  open_g <- lengths(regmatches(x, gregexpr("<g[ >]", x))) - lengths(regmatches(x, gregexpr("</g>", x)))
  if (open_g <= 0L) return(x)
  sub("</svg>\\s*$", paste0(strrep("</g>\n", open_g), "</svg>\n"), x)
}

last_page <- function(s) {
  p <- as.character(s())
  if (!length(p)) return(NA_character_)
  close_groups(p[length(p)])
}

n_prims <- function(svg) {
  doc <- xml2::read_xml(svg)
  length(xml2::xml_find_all(doc, prim_xpath(), svg_ns(doc)))
}

# scene_signatures() plus the clip regions in force for each primitive: the
# geometry of every clipPath referenced by an ancestor <g>, outermost first
# (ids differ between devices, geometry does not). scene_signatures() alone
# cannot see a primitive that lost its clip: the clip is an attribute of an
# ancestor, not of the primitive (S7).
clip_signatures <- function(svg) {
  doc <- xml2::read_xml(svg); ns <- svg_ns(doc)
  defs <- xml2::xml_find_all(doc, "//d1:clipPath", ns)
  geom <- vapply(defs, function(d) paste(vapply(xml2::xml_children(d), function(k) {
    a <- xml2::xml_attrs(k); paste(xml2::xml_name(k), paste(names(a), a, sep = "=", collapse = " "))
  }, ""), collapse = ";"), "")
  names(geom) <- xml2::xml_attr(defs, "id")
  nodes <- xml2::xml_find_all(doc, prim_xpath(), ns)
  anc <- xml2::xml_find_all(nodes, "ancestor::d1:g[@clip-path]", ns, flatten = FALSE)
  chain <- vapply(anc, function(a) {
    if (!length(a)) return("")
    paste(geom[sub("^url\\(#(.*)\\)$", "\\1", xml2::xml_attr(a, "clip-path"))], collapse = " > ")
  }, "")
  paste(scene_signatures(svg), "|clip:", chain)
}

# Name of the graphics call behind a display-list entry; "call" for the
# entries grid puts there.
dl_op <- function(el) {
  f <- tryCatch(el[[2]][[1]], error = function(e) NULL)
  if (is.list(f) && !is.null(f$name)) f$name else "call"
}

# What the current device's page holds.
page_kind <- function() {
  rp <- tryCatch(grDevices::recordPlot(), error = function(e) NULL)
  ops <- if (is.null(rp)) character() else vapply(as.list(rp[[1]]), dl_op, "")
  grobs <- tryCatch(length(grid::grid.ls(print = FALSE, viewports = FALSE)$name), error = function(e) 0L)
  base <- any(grepl("^C_", ops) & ops != "C_par")
  list(rp = rp, ops = ops, grid_grobs = grobs, base = base,
       kind = if (base && grobs > 0L) "mixed" else if (base) "base" else if (grobs > 0L) "grid" else "empty")
}

# ---- grid page ---------------------------------------------------------------

# A grob's name is one string, but grid does not check it: treemap draws
# grid.rect(..., name = <one name per rectangle>), which is why grid.grab()
# returns a scene grid cannot draw (bench gallery-056, "no such index at level
# 1"). Drawing ignores the name, so the first is kept and the case counted.
scalar_names <- function(x, acc) {
  if (length(x$name) != 1L) {
    acc$vector_names <- (if (is.null(acc$vector_names)) 0L else acc$vector_names) + 1L
    x$name <- as.character(x$name)[1]
  }
  if (inherits(x, "gTree") && length(x$children)) {
    nms <- names(x$children)
    kids <- lapply(nms, function(nm) scalar_names(x$children[[nm]], acc))
    new_kids <- do.call(grid::gList, kids)
    names(new_kids) <- nms
    x$children <- new_kids
  }
  x
}

# Wrap the grid display list of the current device in place and redraw it.
# `s` is the svgstring reader of that device. Closes the device.
capture_grid_page <- function(s, width = 7, height = 5, dense = Inf) {
  rec <- new_env(); rec$n <- 0L; rec$order <- character(); rec$probe <- list()
  acc <- new_env(); acc$k <- 0L; acc$leaves <- list(); acc$grobs <- list(); acc$rec <- rec
  dev <- grDevices::dev.cur()
  on.exit(if (dev %in% grDevices::dev.list()) grDevices::dev.off(dev), add = TRUE)
  grid::grid.force()
  grid::grid.DLapply(function(elt) {
    if (inherits(elt, "grob")) wrap_leaves(scalar_names(elt, acc), character(), acc) else elt
  })
  grid::grid.refresh()
  grDevices::dev.off(dev)
  pages <- as.character(s())
  cap <- list(svg = pages[length(pages)], leaves = acc$leaves, probes = rec$probe,
              order = rec$order, wrapped = NULL, grobs = acc$grobs)
  sub <- build_substrate(cap, width, height, dense)
  sub$vector_names <- if (is.null(acc$vector_names)) 0L else acc$vector_names
  sub
}

# ---- base page ---------------------------------------------------------------

# Replay a recorded base plot one entry at a time, reading the device after
# each entry. Primitives written between two reads were drawn by that entry.
replay_by_entry <- function(rp, width = 7, height = 5) {
  dl <- as.list(rp[[1]])
  s <- svglite::svgstring(width = width, height = height, standalone = TRUE)
  dev <- grDevices::dev.cur()
  on.exit(if (dev %in% grDevices::dev.list()) grDevices::dev.off(dev), add = TRUE)
  grDevices::dev.control("enable")
  stub <- rp
  stub[1] <- list(NULL)
  grDevices::replayPlot(stub)          # restores the saved graphics state only
  seen <- integer(length(dl))
  usr <- vector("list", length(dl)); plt <- usr; fig <- usr
  for (k in seq_along(dl)) {
    e <- dl[[k]]
    do.call(e[[1]], as.list(e[[2]]), quote = TRUE)
    pg <- last_page(s)
    seen[k] <- if (is.na(pg)) 0L else n_prims(pg)
    usr[[k]] <- graphics::par("usr"); plt[[k]] <- graphics::par("plt"); fig[[k]] <- graphics::par("fig")
  }
  grDevices::dev.off(dev)
  pages <- as.character(s())
  list(page = pages[length(pages)], seen = seen, ops = vapply(dl, dl_op, ""),
       usr = usr, plt = plt, fig = fig, pages = length(pages))
}
