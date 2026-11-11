# Capture the page the figure draws (ADR-0006), by graphics-group delimiting
# plus probes (ADR-0001).
#
# The input draws itself on gloss's svglite device: print() or show() for an
# object, grid.draw() for a grob, a call for a function, replayPlot() for a
# recorded plot. That page is the reference. On a grid page the display list
# is forced and every leaf is wrapped in place as
#   gTree(children = gList(probe, groupGrob(leaf without vp)), vp = leaf$vp)
# and grid redraws it. The device puts each leaf's output in its own
# <g id="group-k">; the probe records the viewport path, device box and
# native scales at draw time. Groups are then inlined in place of their
# <use>, so the scene keeps the device's drawing order. The captured page is
# compared with the page drawn before anything else is built from it.

#' Capture a figure into a substrate
#'
#' `gloss()` lets the figure draw itself on an svglite device, captures that
#' page, and traces every drawn element to the leaf grob, viewport and panel
#' that produced it. The result is a read-only substrate plus the figure's
#' data tables, each with an inferred row key, and the context sniffed at
#' capture time.
#'
#' The figure draws itself the way R displays it: an object is printed
#' (`show()` for S4), a grob is drawn with [grid::grid.draw()], a function is
#' called and a recorded plot is replayed. An object with its own `print()`
#' method is captured as what that method draws. If the input draws several
#' pages, the last is captured with a warning. A page with nothing on it, and
#' a page that mixes base graphics and grid, are refused with the reason.
#'
#' gloss then compares the captured page with the page the figure drew,
#' primitive for primitive and with the clip region of each. When they are
#' equal the figure is captured. When a plain redraw of the page differs from
#' the first drawing too, the figure is not deterministic (it draws random
#' numbers, for example): it is captured with a warning, and the verdict is
#' stored in `meta$page`. When only the capture differs, gloss stops: it would
#' otherwise hold another figure.
#'
#' The engine is chosen from the classes the registered engine plugins
#' declare, in the order of `class(x)`; `engine` overrides the choice. When
#' several engines declare the class but capture different kinds of page (a
#' function can draw with base graphics or with grid), the page drawn
#' chooses. Built-in engines handle ggplot2 plots, patchwork compositions,
#' ComplexHeatmap heatmaps, base graphics (a `recordedplot` or a function that
#' draws the plot; the page is replayed one display-list entry at a time and
#' each entry that draws is a leaf) and any grid grob, function or recorded
#' plot that draws with grid.
#'
#' The engine's tables and panels are statements about the page drawn. Those
#' it cannot show describe that page are withheld and listed with the reason
#' in `fig$status$withheld`: the built data of a ggplot printed by another
#' class's print method, and of a patchwork plot whose build draws random
#' numbers.
#'
#' Within each leaf the expected number of drawn elements is compared with
#' the number the device drew. A leaf whose counts differ keeps its
#' structure but is marked `count_mismatch` and is never bound to data rows.
#'
#' Leaves that draw at least `dense` non-text elements are kept as a raster
#' drawn by a PNG device from the same display list, plus a binary index of
#' their element geometry; queries treat them like any other leaf.
#'
#' @param x A figure: a ggplot, patchwork, `Heatmap`/`HeatmapList`,
#'   `recordedplot`, a function that draws a plot, or a grob.
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
  engines <- engine_candidates(x, engine)
  gl_capture(x, engines, width = size$width, height = size$height, dense = dense,
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

# The engines that declare the first class of `x` any engine declares, most
# recently registered first. Candidates that capture different kinds of page
# (a function: base or grid) are told apart by the page drawn.
engine_candidates <- function(x, engine = NULL) {
  if (!is.null(engine)) return(list(gl_plugin("engine", engine)))
  engines <- rev(plugins_of("engine"))
  for (cls in class(x)) {
    hit <- Filter(function(e) cls %in% e$classes, engines)
    if (length(hit)) return(unname(hit))
  }
  cli::cli_abort(c(
    "No engine plugin handles an object of class {.cls {class(x)}}.",
    i = "Registered engines: {.val {names(plugins_of('engine'))}}."
  ))
}

engine_page <- function(engine) engine$page %||% "grid"

#' Capture with a given engine plugin
#'
#' The work behind [gloss()], for engine plugins and tests that already hold
#' the plugin object.
#'
#' @param x The figure.
#' @param engine An engine plugin, as returned by [gl_plugin()], or a list of
#'   candidate engine plugins; when the candidates capture different kinds of
#'   page, the page `x` draws chooses among them.
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
  capture_figure(x, engine, width = width, height = height, dense = dense, context = context,
                 expr = expr, call = call, env = env, size_basis = size_basis)$fig
}

# gl_capture()'s work. Also returns the engine and its state after drawing,
# which the figure does not keep: binding (core-bind.R) reads the build and
# the grob tree the engine drew.
capture_figure <- function(x, engine, width = 7, height = 5, dense = 10000,
                           context = TRUE, expr = NULL, call = NULL,
                           env = parent.frame(), size_basis = "argument") {
  engines <- if (inherits(engine, "gloss_plugin")) list(engine) else engine
  cap <- capture_page(x, engines, width, height)
  eng <- cap$engine
  state <- cap$state
  doc <- if (identical(cap$route, "base")) base_scene_doc(cap) else inline_groups(cap)
  check <- page_verdict(
    drawn = page_signature(read_page(cap$drawn)),
    captured = page_signature(doc),
    redraw = function() page_signature(read_page(cap$redraw()))
  )
  if (cap$pages > 1L) {
    cli::cli_warn(c(
      "The input drew {cap$pages} pages; gloss captured the last one.",
      i = "The page count is stored in {.code meta$page$pages}."
    ))
  }
  if (identical(check$verdict, "not_deterministic")) {
    cli::cli_warn(c(
      "The figure is not deterministic: drawn again, {check$differ} of its {check$primitives} primitive{?s} differ from the first drawing.",
      i = "gloss captured a redraw. The verdict is stored in {.code meta$page$verdict}."
    ))
  }
  sub <- substrate_from_doc(doc, cap, width, height, dense)
  # Tables and panels are the engine's statements about the page; those it
  # cannot show describe the page drawn come back withheld, with the reason.
  withheld <- data.frame(what = character(), reason = character(), stringsAsFactors = FALSE)
  if (!is.null(eng$panels)) {
    pan <- eng$panels(state, sub)
    # Some panels can be withheld while others are stated (a patchwork plot
    # whose build draws random numbers, beside plots whose builds do not).
    if (!is.null(pan$withheld)) {
      withheld <- rbind(withheld, data.frame(what = "panels", reason = pan$withheld, stringsAsFactors = FALSE))
    }
    if (!is.null(pan$panels)) {
      sub$panels <- pan$panels
      sub$leaves$panel <- unname(pan$leaf_panel[sub$leaves$id])
    }
  }
  tables <- if (!is.null(eng$tables)) eng$tables(state) else list()
  held <- vapply(tables, function(t) !is.null(t$withheld), logical(1))
  if (any(held)) {
    withheld <- rbind(withheld, data.frame(what = vapply(tables[held], `[[`, "", "name"),
                                           reason = vapply(tables[held], `[[`, "", "withheld"),
                                           stringsAsFactors = FALSE))
  }
  tables <- lapply(tables[!held], new_table)
  names(tables) <- vapply(tables, `[[`, "", "name")
  fig <- new_figure(
    meta = list(
      gloss = gloss_version(),
      api = gloss_api_version,
      engine = eng$name,
      engine_version = eng$version,
      class = class(x),
      width = width,
      height = height,
      size_basis = size_basis,
      dense = as.double(dense),
      device = paste("svglite", pkg_version_or_na("svglite")),
      created = now_utc(),
      page = list(
        kind = cap$kind,
        drawn_by = cap$drawn_by,
        pages = cap$pages,
        verdict = check$verdict,
        differ = check$differ,
        primitives = check$primitives,
        renamed = cap$renamed %||% 0L,
        note = cap$note %||% NA_character_
      )
    ),
    substrate = sub,
    tables = tables,
    context = list(),
    plugins = plugin_row(eng)
  )
  if (isTRUE(context)) {
    input <- list(x = x, expr = expr, call = call, env = env, engine = eng$name,
                  state = state, tables = tables, width = width, height = height,
                  substrate = sub)
    sniffed <- sniff_context(input)
    fig$context <- sniffed$items
    fig$plugins <- rbind(fig$plugins, sniffed$plugins)
  }
  if (nrow(withheld)) {
    rownames(withheld) <- NULL
    fig$status$withheld <- withheld
  }
  fig$meta$id <- substrate_id(fig$substrate)
  list(fig = fig, engine = eng, state = state)
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

# Draw `x` on a fresh svglite device, choose the engine and capture the page.
# Returns what the substrate is built from (`svg`, the captured page, and the
# probes and leaves), the page first drawn (`drawn`), the display list before
# and after wrapping (`orig`, `dl`), and how the page was drawn.
capture_page <- function(x, engines, width, height) {
  prev <- grDevices::dev.cur()
  on.exit(if (prev > 1L && prev %in% grDevices::dev.list()) grDevices::dev.set(prev), add = TRUE)
  dev <- open_page_device(width, height)
  on.exit(close_page_device(dev), add = TRUE)
  kinds <- unique(vapply(engines, engine_page, ""))
  eng <- if (length(kinds) == 1L) engines[[1]] else NULL
  state <- NULL
  if (!is.null(eng)) state <- eng$prepare(x, width, height)
  drawn_by <- if (!is.null(eng$draw)) draw_engine(eng, state, dev) else draw_input(x)
  if (is.list(drawn_by)) {
    state <- drawn_by$state
    drawn_by <- "the engine"
  }
  back_to_device(dev)
  pages <- length(dev$read())
  page <- page_kind()
  if (is.null(eng)) {
    # Class did not fix the page kind: the page drawn chooses the engine.
    refuse_page(page, NULL)
    hit <- Filter(function(e) identical(engine_page(e), page$kind), engines)
    if (!length(hit)) refuse_page(page, engines[[1]])
    eng <- hit[[1]]
    state <- eng$prepare(x, width, height)
    if (!is.null(eng$draw)) {
      # The engine draws the page itself; start again on a fresh device.
      close_page_device(dev)
      dev <- open_page_device(width, height)
      state <- draw_engine(eng, state, dev)$state
      drawn_by <- "the engine"
      back_to_device(dev)
      page <- page_kind()
    }
  }
  refuse_page(page, eng)
  drawn_at <- length(dev$read())
  if (identical(page$kind, "base")) {
    # The base route replays the recorded page on a device of its own.
    rp <- page$rp
    close_page_device(dev)
    cap <- capture_base_page(rp, width, height)
    if (inherits(x, "recordedplot")) {
      cap$note <- paste("A recorded plot is replayed with svglite's text metrics; if it was recorded on",
                        "another device, text and what is placed from it can differ from that device's page.")
    }
  } else {
    cap <- capture_grid_page()
    orig <- cap$orig
    cap$redraw <- function() plain_svg(function() draw_dl(orig), width, height)
    cap$draw_leaf <- function(id) draw_dl(lapply(cap$dl, keep_only_leaf, id = id, grobs = cap$grobs))
    close_page_device(dev)
  }
  all_pages <- as.character(dev$read())
  # The page drawn is closed once grid starts the next one; keep it and the last.
  cap$drawn <- all_pages[drawn_at]
  if (is.null(cap$svg)) cap$svg <- all_pages[length(all_pages)]
  cap$engine <- eng
  cap$state <- state
  # A base engine reads the arguments of the page's calls from the recording.
  if (identical(page$kind, "base") && is.list(cap$state)) cap$state$recorded <- page$rp
  cap$kind <- page$kind
  cap$drawn_by <- drawn_by
  cap$pages <- as.integer(pages)
  cap
}

open_page_device <- function(width, height) {
  s <- svglite::svgstring(width = width, height = height, standalone = TRUE)
  dev <- grDevices::dev.cur()
  # Devices that support graphics groups report their compositing operators.
  comp <- grDevices::dev.capabilities("compositing")$compositing
  if (!is.character(comp) || !length(comp)) {
    grDevices::dev.off(dev)
    cli::cli_abort("The capture device does not support graphics groups (needs R >= 4.2 and svglite >= 2.2).")
  }
  # Base graphics are recorded only on a device with its display list on.
  grDevices::dev.control("enable")
  list(dev = dev, read = s)
}

close_page_device <- function(dev) {
  if (dev$dev %in% grDevices::dev.list()) grDevices::dev.off(dev$dev)
  invisible()
}

# The input may open, switch or close devices while it draws.
back_to_device <- function(dev) {
  if (!dev$dev %in% grDevices::dev.list()) {
    cli::cli_abort(c(
      "The input closed gloss's device while drawing, so there is no page to capture.",
      i = "gloss captures the page the input draws on the device it opens."
    ))
  }
  if (grDevices::dev.cur() != dev$dev) grDevices::dev.set(dev$dev)
  invisible()
}

# Draw `x` the way R displays it; returns how.
draw_input <- function(x) {
  if (inherits(x, "recordedplot")) {
    # Replay a deep copy. grid's display list, restored from the recording,
    # is the list inside the recording itself: wrapping its leaves in place
    # changed the caller's object, and a second capture of it failed (bench
    # run 2026-11-11-1205, three grid figures). A copy through serialize()
    # replays as two pages; a deep copy in memory replays as one.
    grDevices::replayPlot(rlang::duplicate(x, shallow = FALSE))
    return("replayPlot()")
  }
  if (is.function(x)) {
    x()
    return("calling the function")
  }
  if (inherits(x, c("grob", "gList"))) {
    grid::grid.newpage()
    grid::grid.draw(x)
    return("grid.draw()")
  }
  if (isS4(x)) {
    methods::show(x)
    return("show()")
  }
  print(x)
  "print()"
}

# An engine's own drawing step keeps what drawing returns (ADR-0006 point 4);
# the contract test checks that its page is the input's own page.
draw_engine <- function(eng, state, dev) {
  out <- eng$draw(state)
  list(state = if (is.null(out)) state else out)
}

# What the current page holds, read from the device's display list, which a
# new page clears: base graphics operations and grid's drawing operations.
# grid's own display list is not evidence of what is on a base page: a new
# base page does not clear it, so after a grid page it still holds that
# page's grobs (two held-out base figures at the end of a vignette were
# refused as mixed for this, bench run 2026-11-11-0837). It is only asked
# whether a page without base operations holds anything.
page_kind <- function() {
  rp <- tryCatch(grDevices::recordPlot(), error = function(e) NULL)
  ops <- if (is.null(rp)) character() else vapply(rp[[1]], dl_op, "")
  base_ops <- sum(startsWith(ops, "C_") & ops != "C_par")
  grid_ops <- sum(ops == "call" | startsWith(ops, "L_"))
  grobs <- length(grid::grid.ls(viewports = FALSE, recursive = FALSE, print = FALSE)$name)
  kind <- if (base_ops > 0L && grid_ops > 0L) "mixed"
          else if (base_ops > 0L) "base"
          else if (grobs > 0L) "grid"
          else "empty"
  list(kind = kind, base_ops = base_ops, grid_ops = grid_ops, grobs = grobs, rp = rp)
}

# Name of the graphics call behind a display-list entry; "call" for entries
# that are not a registered native routine.
dl_op <- function(el) {
  f <- tryCatch(el[[2]][[1]], error = function(e) NULL)
  if (is.list(f) && !is.null(f$name)) f$name else "call"
}

# Stop on a page gloss cannot capture with `eng`; with `eng = NULL`, only on
# pages no engine can capture.
refuse_page <- function(page, eng) {
  if (identical(page$kind, "empty")) {
    cli::cli_abort(c(
      "The input drew nothing on gloss's device.",
      i = "gloss captures the page the input draws: it prints an object, calls a function or replays a recorded plot.",
      i = "An animation, or code that draws on another device, leaves this page empty."
    ))
  }
  if (identical(page$kind, "mixed")) {
    cli::cli_abort(c(
      "The page mixes base graphics and grid ({page$base_ops} base operation{?s}, {page$grid_ops} grid operation{?s}); gloss cannot attribute its elements.",
      i = "Capture a page drawn by one graphics system."
    ))
  }
  if (!is.null(eng) && identical(page$kind, "base") && !identical(engine_page(eng), "base")) {
    cli::cli_abort(c(
      "The input drew a base graphics page, which engine {.val {eng$name}} cannot capture.",
      i = "Base pages are captured by an engine that declares {.code page = \"base\"}, such as the base engine."
    ))
  }
  invisible()
}

# Wrap the grid display list of the current device in place and redraw it.
capture_grid_page <- function() {
  rec <- new_env()
  rec$n <- 0L
  rec$order <- character()
  rec$probe <- list()
  acc <- new_env()
  acc$k <- 0L
  acc$leaves <- list()
  acc$grobs <- list()
  acc$rec <- rec
  acc$renamed <- 0L
  acc$orig <- list()
  acc$dl <- list()
  grid::grid.force()
  grid::grid.DLapply(function(elt) {
    i <- length(acc$orig) + 1L
    acc$orig[i] <- list(elt)
    new <- if (inherits(elt, "grob")) wrap_leaves(scalar_names(elt, acc), character(), acc) else elt
    acc$dl[i] <- list(new)
    new
  })
  grid::grid.refresh()
  list(leaves = acc$leaves, probes = rec$probe, order = rec$order, grobs = acc$grobs,
       orig = acc$orig, dl = acc$dl, renamed = acc$renamed)
}

# A grob's name is one string, but grid does not check it: treemap draws
# grid.rect(..., name = <one name per rectangle>) (bench gallery-056). Drawing
# ignores the name, so the first is kept and the grob counted.
scalar_names <- function(x, acc) {
  if (length(x$name) != 1L) {
    acc$renamed <- acc$renamed + 1L
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

# Draw a list of grid display-list elements on a new page of the current
# device, as grid.refresh() draws the display list.
draw_dl <- function(dl) {
  grid::grid.newpage()
  for (e in dl) if (!is.null(e)) grid::grid.draw(e, recording = FALSE)
  invisible()
}

# ---- base pages ---------------------------------------------------------------

# A recorded base page replayed one display-list entry at a time on a file
# svglite device kept valid while it is written; after each entry only the
# bytes it added are read (dev_docs/research/capture-fidelity/s6: 5008
# entries in 0.31 s, the same counts and page as parsing the whole page after
# each entry). An entry's primitives are the primitives the device wrote
# during it, so the leaf is the entry and nothing is estimated (ADR-0006).
#
# The display list's structure is internal to R and may change between
# versions; the self-check compares the result with the page drawn, so a
# change shows as a difference, not as a silently wrong capture.
utf8_text <- function(bytes) {
  x <- rawToChar(bytes)
  Encoding(x) <- "UTF-8"
  x
}

capture_base_page <- function(rp, width, height) {
  dl <- as.list(rp[[1]])
  ops <- vapply(dl, dl_op, "")
  f <- tempfile(fileext = ".svg")
  svglite::svglite(f, width = width, height = height, standalone = TRUE, always_valid = TRUE)
  dev <- grDevices::dev.cur()
  rd <- new_env()
  rd$pos <- 0
  on.exit({
    if (dev %in% grDevices::dev.list()) grDevices::dev.off(dev)
    unlink(f)
  }, add = TRUE)
  # n bytes from offset `from`, through a connection opened for this read: on
  # Linux a connection kept open and seeked again returned bytes from before
  # svglite rewrote the file's closing tags (dev log 2026-11-11).
  read_bytes <- function(from, n) {
    con <- file(f, "rb")
    on.exit(close(con))
    seek(con, from)
    readBin(con, "raw", n)
  }
  # The bytes added since the last read, without the closing tags that keep
  # the file valid (the next write overwrites them).
  read_new <- function() {
    size <- file.size(f)
    if (is.na(size) || size < rd$pos) {
      cli::cli_abort("Replaying the base page started a new page; gloss cannot split it by entry.")
    }
    if (size == rd$pos) return("")
    bytes <- read_bytes(rd$pos, size - rd$pos)
    txt <- utf8_text(bytes)
    closing <- regmatches(txt, regexpr("(\\s*</g>)*\\s*</svg>\\s*$", txt))
    # offsets are bytes: a label may hold multibyte characters (plotmath writes alpha as U+03B1)
    keep <- length(bytes) - if (length(closing)) nchar(closing, "bytes") else 0L
    rd$pos <- rd$pos + keep
    utf8_text(bytes[seq_len(keep)])
  }
  grDevices::dev.control("enable")
  # An empty display list restores the recorded graphics state and starts the page.
  stub <- rp
  stub[1] <- list(NULL)
  grDevices::replayPlot(stub)
  head <- read_new()
  n <- length(dl)
  chunks <- character(n)
  boxes <- matrix(NA_real_, n, 8)
  for (k in seq_len(n)) {
    e <- dl[[k]]
    res <- tryCatch(do.call(e[[1]], as.list(e[[2]]), quote = TRUE), error = function(err) err)
    if (inherits(res, "error")) {
      cli::cli_abort(c(
        "Replaying display-list entry {k} ({ops[k]}) of the base page failed: {conditionMessage(res)}",
        i = "gloss captures a base page by replaying its display list one entry at a time."
      ))
    }
    chunks[k] <- read_new()
    boxes[k, ] <- plot_region(width, height)
  }
  grDevices::dev.off(dev)
  tail <- utf8_text(read_bytes(rd$pos, file.size(f) - rd$pos))
  entries <- base_entries(dl, ops, chunks, boxes, head, width, height)
  list(route = "base", svg = paste0(head, paste(entries$text, collapse = ""), tail),
       leaves_df = entries$leaves, entry_counts = entries$counts, renamed = 0L,
       redraw = function() plain_svg(function() grDevices::replayPlot(rp), width, height),
       draw_leaf = function(id) {
         k <- entries$entry[[id]]
         graphics::par(bg = "transparent")  # the recorded background would cover the scene
         grDevices::replayPlot(stub)
         graphics::par(bg = "transparent")
         for (j in seq_len(n)) {
           if (j == k || !entries$drew[j]) do.call(dl[[j]][[1]], as.list(dl[[j]][[2]]), quote = TRUE)
         }
       })
}

# The plot region on the device in SVG user units (origin top-left), and
# par("usr"), after the entry just replayed.
plot_region <- function(width, height) {
  tryCatch({
    x <- graphics::grconvertX(c(0, 1), "npc", "ndc") * width * pt_per_in
    y <- (1 - graphics::grconvertY(c(1, 0), "npc", "ndc")) * height * pt_per_in
    c(x, y, graphics::par("usr"))
  }, error = function(e) rep(NA_real_, 8))
}

# Leaves, wrapped text and counts per entry. Each run of an entry's
# primitives between two clip changes is wrapped in <g data-gloss-leaf>; the
# clip in force at the entry's first primitive decides whether the leaf lies
# in its figure's plot region.
base_entries <- function(dl, ops, chunks, boxes, head, width, height) {
  n <- length(chunks)
  clip <- clip_tracker(head)
  text <- chunks
  counts <- integer(n)
  in_plot <- logical(n)
  ids <- character(n)
  k_leaf <- 0L
  for (k in seq_len(n)) {
    lines <- strsplit(chunks[k], "\n", fixed = TRUE)[[1]]
    prim <- base_prim(lines)
    if (any(prim)) {
      first <- which(prim)[1]
      at <- clip$feed(lines[seq_len(first - 1L)])
      clip$feed(lines[first:length(lines)])
      in_plot[k] <- !is.null(at) && !anyNA(boxes[k, 1:4]) && all(abs(at - boxes[k, 1:4]) < 0.02)
      k_leaf <- k_leaf + 1L
      ids[k] <- sprintf("L%03d", k_leaf)
      w <- wrap_entry(chunks[k], ids[k], lines = lines, prim = prim)
      text[k] <- w$text
      counts[k] <- w$n
    } else {
      clip$feed(lines)
    }
  }
  drew <- counts > 0L
  fig <- cumsum(ops == "C_plot_new")
  name <- sub("^C_", "", ops)
  vp <- ifelse(in_plot, sprintf("figure-%d::plot", fig), sprintf("figure-%d", fig))
  k <- which(drew)
  leaves <- data.frame(
    id = ids[k], name = name[k], path = sprintf("base/%d/%s", k, name[k]), class = name[k], vp = vp[k],
    x0 = round_pt(boxes[k, 1]), y0 = round_pt(boxes[k, 3]), x1 = round_pt(boxes[k, 2]), y1 = round_pt(boxes[k, 4]),
    xscale0 = boxes[k, 5], xscale1 = boxes[k, 6], yscale0 = boxes[k, 7], yscale1 = boxes[k, 8],
    n_expected = vapply(dl[k], base_expected, integer(1)),
    stringsAsFactors = FALSE
  )
  list(text = text, leaves = leaves, counts = stats::setNames(counts[k], ids[k]),
       drew = drew, entry = stats::setNames(as.list(k), ids[k]))
}

base_prim_line <- "^<(circle|rect|line|polyline|polygon|path|text|image)[ />]"

# Drawn primitive lines of an entry's output. svglite's page background
# (width and height 100%) is the device's, not the entry's: it stays without
# a leaf, as on grid pages.
base_prim <- function(lines) {
  grepl(base_prim_line, lines, perl = TRUE) & !startsWith(lines, "<rect width='100%' height='100%'")
}

# Wrap each run of primitive lines of one entry's output in a leaf group.
# svglite writes a drawn primitive on a line of its own, from the first
# column; clip-path definitions are indented. The scene's counts are checked
# against these afterwards.
wrap_entry <- function(chunk, id, lines = strsplit(chunk, "\n", fixed = TRUE)[[1]],
                       prim = base_prim(lines)) {
  if (!any(prim)) return(list(text = chunk, n = 0L))
  r <- rle(prim)
  ends <- cumsum(r$lengths)
  starts <- ends - r$lengths + 1L
  out <- character()
  for (i in seq_along(r$lengths)) {
    seg <- lines[starts[i]:ends[i]]
    out <- c(out, if (r$values[i]) c(sprintf("<g data-gloss-leaf='%s'>", id), seg, "</g>") else seg)
  }
  trail <- if (endsWith(chunk, "\n")) "\n" else ""
  list(text = paste0(paste(out, collapse = "\n"), trail), n = sum(prim))
}

# Which clip region is in force, as c(x0, x1, y0, y1) in SVG user units,
# from the clip-path definitions and clip groups svglite writes, read in
# drawing order: feed() reads lines and returns the clip in force after them.
clip_tracker <- function(head) {
  st <- new_env()
  st$geom <- list()
  st$current <- NULL
  st$pending <- NULL
  feed <- function(lines) {
    for (ln in lines[grep("<clipPath id=|^\\s+<rect x=|^<g clip-path=|^</g>$", lines)]) {
      if (grepl("<clipPath id=", ln, fixed = TRUE)) {
        st$pending <- sub("^.*<clipPath id='([^']+)'.*$", "\\1", ln)
      } else if (startsWith(ln, "<g clip-path=")) {
        st$current <- st$geom[[sub("^<g clip-path='url\\(#([^)]+)\\)'>.*$", "\\1", ln)]]
      } else if (identical(ln, "</g>")) {
        st$current <- NULL
      } else if (!is.null(st$pending)) {
        v <- as.numeric(regmatches(ln, gregexpr("-?[0-9.]+", ln))[[1]][1:4])
        st$geom[[st$pending]] <- c(v[1], v[1] + v[3], v[2], v[2] + v[4])
        st$pending <- NULL
      }
    }
    st$current
  }
  feed(strsplit(head, "\n", fixed = TRUE)[[1]])
  list(feed = feed)
}

# The scene of a base page, with its leaf groups.
base_scene_doc <- function(cap) {
  doc <- tryCatch(read_page(cap$svg), error = function(e) conditionMessage(e))
  if (is.character(doc)) {
    cli::cli_abort(c(
      "Capture integrity check failed: the base page split by entry is not well-formed SVG.",
      x = "The XML parser says: {doc}",
      i = "Please report the figure."
    ))
  }
  if (length(xml2::xml_find_all(doc, "//d1:mask", svg_ns(doc)))) {
    cli::cli_abort("The figure uses a mask, which gloss cannot attribute.")
  }
  doc
}

# How many SVG elements a display-list entry is expected to draw; NA when
# unknown. The argument positions are those of R's graphics routines.
base_expected <- function(e) {
  a <- tryCatch(as.list(e[[2]]), error = function(err) list())
  op <- tryCatch(a[[1]]$name, error = function(err) "")
  if (!is.character(op) || length(op) != 1L) return(NA_integer_)
  ok_xy <- function(xy) !is.na(xy$x) & !is.na(xy$y) & is.finite(xy$x) & is.finite(xy$y)
  # runs of finite points: their lengths
  runs <- function(ok) {
    r <- rle(ok)
    r$lengths[r$values]
  }
  fin <- function(...) Reduce(`&`, lapply(list(...), function(v) !is.na(v) & is.finite(v)))
  # A call whose arguments do not have the shape a rule expects has no count
  # (unknown), never a failed capture.
  out <- tryCatch(switch(op,
    C_plotXY = {
      type <- a[[3]]
      ok <- ok_xy(a[[2]])
      n <- runs(ok)
      switch(type,
        p = sum(ok),
        l = , s = , S = sum(n >= 2L),
        b = sum(ok) + sum(pmax(n - 1L, 0L)),
        o = sum(ok) + sum(n >= 2L),
        h = sum(ok),
        c = sum(pmax(n - 1L, 0L)),
        n = 0L,
        NA)
    },
    # one polygon per NA-separated run of at least 2 points
    C_polygon = sum(runs(fin(a[[2]], a[[3]])) >= 2L),
    # polypath() draws all its subpaths as one path
    C_path = as.integer(any(fin(a[[2]], a[[3]]))),
    C_arrows = {
      n <- max(lengths(a[2:5]))
      v <- lapply(a[2:5], rep_len, length.out = n)
      ok <- fin(v[[1]], v[[2]], v[[3]], v[[4]])
      code <- a$code %||% a[[8]]
      heads <- if (code %in% c(1, 2)) 1L else if (code == 3) 2L else 0L
      # a zero-length arrow keeps its shaft and loses its heads
      moved <- ok & (v[[1]] != v[[3]] | v[[2]] != v[[4]])
      sum(ok) + heads * sum(moved)
    },
    C_abline = {
      ab <- if (!is.null(a[[2]]) && length(a[[2]])) 1L else 0L
      ab + sum(fin(a[[4]] %||% numeric())) + sum(fin(a[[5]] %||% numeric()))
    },
    # circles, squares and rectangles: one element per finite symbol; the
    # other kinds draw several per symbol
    C_symbols = {
      kind <- a[[4]]
      d <- a[[5]]
      ok <- fin(a[[2]], a[[3]])
      if (kind %in% c(1, 2)) sum(ok & fin(d))
      else if (kind == 3 && is.matrix(d)) sum(ok & fin(d[, 1], d[, 2]))
      else NA
    },
    C_text = {
      lab <- a[[3]]
      # plotmath (an expression or call) draws an unknown number of pieces
      if (!is.atomic(lab) || anyNA(lab) || any(grepl("\n", as.character(lab), fixed = TRUE))) NA
      else max(length(a[[2]]$x), length(lab))
    },
    C_rect = max(lengths(a[2:5])),
    C_segments = max(lengths(a[2:5])),
    NA
  ), error = function(err) NA)
  if (length(out) != 1L) return(NA_integer_)
  as.integer(out)
}

# ---- self-check -------------------------------------------------------------

# Compare the captured page with the page drawn (ADR-0006 point 3). `drawn`
# and `captured` are page signatures; `redraw()` returns the signature of a
# plain redraw of the display list the capture wrapped.
page_verdict <- function(drawn, captured, redraw) {
  n <- length(drawn)
  if (identical(drawn, captured)) {
    return(list(verdict = "equal", differ = 0L, primitives = n))
  }
  differ <- signature_diff(drawn, captured)
  plain <- redraw()
  if (!identical(plain, drawn)) {
    if (identical(plain, captured) || !identical(redraw(), plain)) {
      return(list(verdict = "not_deterministic", differ = differ, primitives = n))
    }
  }
  cli::cli_abort(c(
    "Capture changed the figure: the captured page differs from the page drawn in {differ} primitive{?s}, while a plain redraw {if (identical(plain, drawn)) 'equals the page drawn' else 'is the same every time'}.",
    i = "gloss stops rather than hold another figure. This is a gloss defect; please report it with the figure's code."
  ))
}

# Primitives without a match in the other page, either way; a page with the
# same primitives in another order counts the positions that differ.
signature_diff <- function(a, b) {
  ta <- table(a)
  tb <- table(b)
  common <- intersect(names(ta), names(tb))
  d <- length(a) + length(b) - 2L * sum(pmin(ta[common], tb[common]))
  if (d == 0L && !identical(a, b)) d <- sum(a != b)
  as.integer(d)
}

# Every drawn primitive in document order, as libxml2 serialises it, with the
# clip regions in force for it: the geometry of every clipPath referenced by
# an ancestor group, outermost first (ids differ between drawings, geometry
# does not). Primitives under defs, clipPath, mask or pattern are not drawn
# and not listed, as in prim_xpath().
#
# svglite writes clip groups as siblings under its root group, so most
# primitives lie under one top-level child with at most one clip. Each such
# child is serialised once and its primitives read with one regular
# expression: per-node calls cost 2.5 s per page at 10^5 points, this about
# a tenth (dev_docs/research/capture-fidelity/p3-time.out). A child holding
# anything else (a nested clip group, defs, a pattern or mask) is read node by
# node through XPath instead.
page_signature <- function(doc) {
  ns <- svg_ns(doc)
  defs <- xml2::xml_find_all(doc, "//d1:clipPath", ns)
  geom <- vapply(defs, function(d) paste(as.character(xml2::xml_children(d)), collapse = ";"), "")
  names(geom) <- xml2::xml_attr(defs, "id")
  root <- xml2::xml_find_first(doc, "/d1:svg/d1:g[@class='svglite']", ns)
  if (inherits(root, "xml_missing")) return(signature_nodes(doc, geom))
  kids <- xml2::xml_children(root)
  tags <- xml2::xml_name(kids)
  out <- vector("list", length(kids))
  for (k in seq_along(kids)) {
    tag <- tags[k]
    if (tag %in% c("defs", "style")) next
    if (tag %in% prim_tags) {
      out[[k]] <- paste(as.character(kids[[k]]), "|clip:", "")
      next
    }
    txt <- as.character(kids[[k]])
    own <- xml2::xml_attr(kids[[k]], "clip-path")
    n_clip <- lengths(regmatches(txt, gregexpr("<g [^>]*clip-path=", txt)))
    plain <- identical(tag, "g") && n_clip <= 1L && (n_clip == 0L || !is.na(own)) &&
      !grepl("<(defs|clipPath|mask|pattern)[ >/]", txt)
    if (!plain) {
      out[[k]] <- signature_nodes(kids[[k]], geom, self = TRUE)
      next
    }
    prims <- regmatches(txt, gregexpr(prim_regex, txt, perl = TRUE))[[1]]
    if (!length(prims)) next
    clip <- if (is.na(own)) "" else unname(geom[sub("^url\\(#(.*)\\)$", "\\1", own)])
    out[[k]] <- paste(prims, "|clip:", clip)
  }
  unlist(out, use.names = FALSE) %||% character()
}

prim_regex <- paste0(
  "<(?:circle|rect|line|polyline|polygon|path|image)\\b[^>]*/>",
  "|<(circle|rect|line|polyline|polygon|path|image)\\b[^>]*>.*?</\\1>",
  "|<text\\b[^>]*/>|<text\\b[^>]*>[^<]*</text>"
)

# The same signature read node by node, under `x` (and `x` itself when it is
# a primitive and `self` is TRUE).
signature_nodes <- function(x, geom, self = FALSE) {
  ns <- c(d1 = "http://www.w3.org/2000/svg")
  xp <- prim_xpath(if (self) "descendant-or-self::" else "//")
  nodes <- xml2::xml_find_all(x, xp, ns)
  if (!length(nodes)) return(character())
  anc <- xml2::xml_find_all(nodes, "ancestor::d1:g[@clip-path]", ns, flatten = FALSE)
  chain <- vapply(anc, function(a) {
    if (!length(a)) return("")
    ids <- sub("^url\\(#(.*)\\)$", "\\1", xml2::xml_attr(a, "clip-path"))
    paste(geom[ids], collapse = " > ")
  }, "")
  paste(as.character(nodes), "|clip:", chain)
}

node_signatures <- function(nodes) {
  vapply(nodes, function(n) {
    a <- xml2::xml_attrs(n)
    a <- a[!startsWith(names(a), "data-gloss-")]
    paste(xml2::xml_name(n), paste(sprintf("%s=%s", names(a), a), collapse = " "), xml2::xml_text(n))
  }, "")
}

# ---- parsing ---------------------------------------------------------------

# Parse a page gloss drew itself (svglite's output, or gloss's scene made
# from it). libxml2 refuses a node over 10^7 bytes unless HUGE is set, and an
# embedded image is one attribute: bench tree-041's page stopped gloss with
# the parser's error (plan 2026-11-11-tree-binding, Task 1). The limit guards
# against hostile documents; these pages are not, so it is lifted here and
# only here. A document from outside (figure_from_plain_svg()) keeps it.
read_page <- function(svg) xml2::read_xml(svg, options = c("NOBLANKS", "HUGE"))

svg_ns <- function(doc) c(d1 = "http://www.w3.org/2000/svg")

prim_tags <- c("circle", "rect", "line", "polyline", "polygon", "path", "text", "image")

prim_xpath <- function(root = "//") {
  sel <- paste0("self::d1:", prim_tags, collapse = " or ")
  sprintf("%s*[(%s) and not(ancestor::d1:defs) and not(ancestor::d1:clipPath) and not(ancestor::d1:mask) and not(ancestor::d1:pattern)]", root, sel)
}

build_substrate <- function(cap, width, height, dense = Inf) {
  substrate_from_doc(inline_groups(cap), cap, width, height, dense)
}

# Parse the captured page and put each leaf's group in place of its <use>.
inline_groups <- function(cap) {
  doc <- read_page(cap$svg)
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
  doc
}

substrate_from_doc <- function(doc, cap, width, height, dense = Inf) {
  ns <- svg_ns(doc)
  leaves <- if (!is.null(cap$leaves_df)) cap$leaves_df else leaves_table(cap)
  elements <- elements_table(doc, ns)
  counts <- table(factor(elements$leaf, levels = leaves$id))
  leaves$n_drawn <- as.integer(counts[leaves$id])
  if (!is.null(cap$entry_counts) && !identical(leaves$n_drawn, unname(cap$entry_counts[leaves$id]))) {
    bad <- leaves$id[leaves$n_drawn != cap$entry_counts[leaves$id]]
    cli::cli_abort(c(
      "Capture integrity check failed: the scene attributes to {length(bad)} display-list entr{?y/ies} other counts than the device wrote while replaying ({.val {utils::head(bad, 3)}}).",
      i = "The page could not be split by entry; please report the figure."
    ))
  }
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
  # one row per element: x0, x1, y0, y1
  box <- matrix(NA_real_, nrow = length(nodes), ncol = 4L)
  i <- which(tag == "circle")
  if (length(i)) {
    cx <- num_attr(nodes[i], "cx")
    cy <- num_attr(nodes[i], "cy")
    r <- num_attr(nodes[i], "r")
    box[i, ] <- cbind(cx - r, cx + r, cy - r, cy + r)
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
    box[i, ] <- cbind(pmin(x, x + w), pmax(x, x + w), pmin(y, y + h), pmax(y, y + h))
  }
  i <- which(tag == "line")
  if (length(i)) {
    ax <- num_attr(nodes[i], "x1")
    ay <- num_attr(nodes[i], "y1")
    bx <- num_attr(nodes[i], "x2")
    by <- num_attr(nodes[i], "y2")
    box[i, ] <- cbind(pmin(ax, bx), pmax(ax, bx), pmin(ay, by), pmax(ay, by))
  }
  i <- which(tag %in% c("polyline", "polygon"))
  if (length(i)) {
    b <- pair_range(xml2::xml_attr(nodes[i], "points"))
    box[i, ] <- cbind(b[, 1], b[, 2], b[, 3], b[, 4])
  }
  i <- which(tag == "path")
  if (length(i)) {
    b <- pair_range(xml2::xml_attr(nodes[i], "d"))
    box[i, ] <- cbind(b[, 1], b[, 2], b[, 3], b[, 4])
  }
  i <- which(tag == "text")
  if (length(i)) {
    b <- text_boxes(nodes[i], style[i])
    box[i, ] <- cbind(b[, 1], b[, 2], b[, 3], b[, 4])
  }
  list(x0 = box[, 1L], x1 = box[, 2L], y0 = box[, 3L], y1 = box[, 4L])
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
# PNG device of the same size, from the wrapped display list. Everything else
# is replaced by nothing, so viewports and clipping are those of the captured
# page.
rasterize_leaves <- function(cap, ids, width, height, dpi = 144) {
  out <- list()
  for (id in ids) out[[id]] <- render_png(function() cap$draw_leaf(id), width, height, dpi)
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

render_png <- function(draw, width, height, dpi) {
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f), add = TRUE)
  if (has_pkg("ragg")) {
    ragg::agg_png(f, width = width, height = height, units = "in", res = dpi, background = "transparent")
  } else {
    grDevices::png(f, width = width, height = height, units = "in", res = dpi, bg = "transparent")
  }
  dev <- grDevices::dev.cur()
  tryCatch(draw(), finally = grDevices::dev.off(dev))
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
  pg <- m$page
  if (!is.null(pg$verdict)) {
    how <- switch(pg$verdict,
      equal = sprintf("captured page equal to the page drawn (%d primitives)", pg$primitives),
      not_deterministic = sprintf("not deterministic: drawn again, %d of %d primitives differ; the captured page is a redraw",
                                  pg$differ, pg$primitives),
      pg$verdict)
    cat(sprintf("  page: %s, drawn by %s; %s\n", pg$kind, pg$drawn_by, how))
    if (isTRUE(pg$pages > 1L)) cat(sprintf("  the input drew %d pages; the last is captured\n", pg$pages))
  }
  w <- x$status$withheld
  if (is.data.frame(w) && nrow(w)) {
    for (i in seq_len(nrow(w))) cat(sprintf("  withheld %s: %s\n", w$what[i], w$reason[i]))
  }
  rest <- x$status[setdiff(names(x$status), "withheld")]
  if (length(rest)) {
    for (nm in names(rest)) cat(sprintf("  status %s: %s\n", nm, paste(format(x$status[[nm]]), collapse = ", ")))
  }
  invisible(x)
}

# ---- regression signature -----------------------------------------------------

# Tag, attributes and text of every drawn primitive in document order, used
# to check that a captured scene draws exactly what plain svglite draws.
# Attributes added by gloss (data-gloss-*) are ignored.
scene_signatures <- function(svg) {
  doc <- read_page(svg)
  node_signatures(xml2::xml_find_all(doc, prim_xpath(), svg_ns(doc)))
}

plain_svg <- function(draw, width, height) {
  s <- svglite::svgstring(width = width, height = height, standalone = TRUE)
  dev <- grDevices::dev.cur()
  tryCatch(draw(), finally = grDevices::dev.off(dev))
  pages <- as.character(s())
  pages[length(pages)]
}
