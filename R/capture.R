# Device capture, grid graphics-group instrumentation, viewport probes,
# <defs>/<use> inlining, SVG element parsing, and dense-leaf rasterization.

#' Capture an R figure as a structured source map and asset store
#'
#' Draws `x` once on an `svglite` device, preserves the untouched device output
#' (`original.svg`), instruments the drawn display list with draw-time viewport
#' probes and deterministic leaf `<g id="L...">` groups (`scene.svg`), extracts
#' engine intermediate representation (IR), and builds neutral structural
#' lineage and runtime source metadata.
#'
#' Both `gl_asset_map()` and `gl_asset_bundle()` serialize directly from the
#' returned `gloss_capture` object without redrawing `x`.
#'
#' @param x A figure to capture: a `grid` grob/`gList`/`gtable`, a `ggplot`,
#'   `patchwork`, `ComplexHeatmap`, a `recordedplot`, a function that draws a
#'   plot, or an object handled by a custom engine registered via
#'   [gl_register_engine()].
#' @param sources Optional explicit source context (e.g., a character vector or
#'   named list of file paths to plotting scripts, raw data files, or
#'   documentation).
#' @param width,height Figure dimensions in inches. When `NULL`, uses the active
#'   `knitr` chunk `fig.width` / `fig.height` if available, otherwise defaults
#'   to `7` by `5` inches.
#' @param dense Positive numeric threshold of non-text elements above which a
#'   leaf is additionally rasterized into a PNG slice (`scene/rasters/`) and
#'   referenced via `<image>` in `scene.svg`. Set to `Inf` to keep every leaf
#'   as vector primitives. Defaults to `10000`.
#' @param engine Optional character name of a registered engine to force instead
#'   of class-based dispatch.
#' @param preview Logical; when `TRUE` (default), renders a pixel-aligned PNG
#'   overview (`assets/preview.png`) from the already-frozen graphics display
#'   list during capture without re-executing user code or RNG. Set to `FALSE`
#'   to skip preview rasterization.
#' @param preview_dpi Positive numeric resolution in DPI used when
#'   `preview = TRUE`. Defaults to `144`.
#' @param page Optional 1-based integer page index to select when `x` draws
#'   multiple pages. Defaults to `NULL` (selects the last drawn page).
#' @param parent Optional parent reference linking a recomputed capture to an
#'   earlier capture (`gloss_capture`, `capture_id` string, or path to an
#'   existing `.gloss/` bundle directory). Recorded as `parent_capture_id`.
#' @param ... Additional arguments forwarded to the engine's `capture_fn`.
#'
#' @return A `gloss_capture` S3 object.
#' @export
#' @examples
#' g <- grid::grobTree(
#'   grid::rectGrob(width = 0.6, height = 0.4, name = "box"),
#'   grid::textGrob("Hello gloss", name = "label")
#' )
#' cap <- gloss(g)
#' cap
gloss <- function(
    x,
    sources = NULL,
    width = NULL,
    height = NULL,
    dense = 10000,
    engine = NULL,
    preview = TRUE,
    preview_dpi = 144,
    page = NULL,
    parent = NULL,
    ...) {

  call_expr <- tryCatch({
    txt <- trimws(paste(deparse(substitute(x)), collapse = " "))
    if (nzchar(txt)) substr(txt, 1L, 500L) else NULL
  }, error = function(e) NULL)

  size <- resolve_figure_size(width, height)
  if (!is.numeric(dense) || length(dense) != 1L || is.na(dense) || dense <= 0) {
    cli::cli_abort("{.arg dense} must be a single positive number (or {.code Inf}).")
  }
  if (!is.logical(preview) || length(preview) != 1L || is.na(preview)) {
    cli::cli_abort("{.arg preview} must be TRUE or FALSE.")
  }
  if (!is.numeric(preview_dpi) || length(preview_dpi) != 1L || !is.finite(preview_dpi) || preview_dpi <= 0) {
    cli::cli_abort("{.arg preview_dpi} must be a single positive finite number.")
  }
  if (!is.null(page) && (!is.numeric(page) || length(page) != 1L || !is.finite(page) || page < 1)) {
    cli::cli_abort("{.arg page} must be NULL or a positive integer page index.")
  }
  page_idx <- if (is.null(page)) NULL else as.integer(page)
  parent_capture_id <- resolve_parent_capture_id(parent)

  candidates <- resolve_engine_candidates(x, engine = engine, error = !is.null(engine))

  prev_dev <- grDevices::dev.cur()
  on.exit({
    if (prev_dev > 1L && prev_dev %in% grDevices::dev.list()) {
      grDevices::dev.set(prev_dev)
    }
  }, add = TRUE)

  dev <- open_capture_device(size$width, size$height)
  on.exit(close_capture_device(dev), add = TRUE)

  cand_kinds <- if (length(candidates) > 0L) {
    unique(vapply(candidates, function(s) s$page_kind, character(1L)))
  } else {
    character()
  }
  already_drawn <- FALSE
  draw_method <- NULL
  page_info <- NULL

  if (length(candidates) == 0L) {
    # Generic printable-object fallback (e.g. ggsurvplot, pheatmap, trellis, ggExtraPlot)
    draw_method <- tryCatch(
      draw_generic_printable(x),
      error = function(e) NULL
    )
    ensure_device_active(dev)
    page_info <- detect_page_kind()
    if (identical(page_info$kind, "empty")) {
      cli::cli_abort(c(
        "No registered gloss engine handles object of class {.cls {class(x)}}.",
        i = "Attempted generic printing fallback, which produced no graphics output."
      ))
    }
    selected <- if (identical(page_info$kind, "mixed")) {
      make_mixed_fallback_engine()
    } else {
      get_engine(page_info$kind) %||% make_mixed_fallback_engine()
    }
    already_drawn <- TRUE
  } else if (length(candidates) == 1L || length(cand_kinds) == 1L) {
    selected <- candidates[[1L]]
  } else {
    # Generic input (e.g. function or recordedplot) with multiple candidate
    # page kinds: draw once, detect whether the page is grid or base, then
    # dispatch to the matching engine without redrawing.
    draw_method <- draw_input_object(x)
    ensure_device_active(dev)
    page_info <- detect_page_kind()
    if (identical(page_info$kind, "empty")) {
      cli::cli_abort("The input did not draw anything onto the graphics device.")
    }
    if (identical(page_info$kind, "mixed")) {
      selected <- resolve_engine(x, engine = engine, page_kind = "mixed", error = FALSE) %||%
        make_mixed_fallback_engine()
    } else {
      selected <- resolve_engine(x, engine = engine, page_kind = page_info$kind, error = TRUE)
    }
    already_drawn <- TRUE
  }

  ctx <- make_capture_context(
    dev = dev,
    width = size$width,
    height = size$height,
    dense = dense,
    sources = sources,
    engine = selected,
    already_drawn = already_drawn,
    draw_method = draw_method,
    page_info = page_info,
    preview = isTRUE(preview),
    preview_dpi = as.integer(round(preview_dpi)),
    page = page_idx,
    parent_capture_id = parent_capture_id,
    call_expr = call_expr
  )

  result <- selected$capture_fn(x, ctx, ...)

  if (is_gloss_capture(result)) {
    return(result)
  }

  assemble_capture_result(result, ctx = ctx, sources = sources, input_obj = x)
}

resolve_parent_capture_id <- function(parent) {
  if (is.null(parent)) return(NULL)
  if (is_gloss_capture(parent)) return(parent$capture_id)
  if (is.character(parent) && length(parent) == 1L && !is.na(parent) && nzchar(parent)) {
    if (dir.exists(parent)) {
      am <- file.path(parent, "asset-map.json")
      mf <- file.path(parent, "manifest.json")
      cand <- if (file.exists(am)) am else if (file.exists(mf)) mf else NULL
      if (!is.null(cand)) {
        doc <- tryCatch(jsonlite::read_json(cand, simplifyVector = TRUE), error = function(e) NULL)
        if (!is.null(doc$capture_id) && nzchar(doc$capture_id)) {
          return(as.character(doc$capture_id)[[1L]])
        }
      }
    }
    return(parent)
  }
  cli::cli_abort("{.arg parent} must be NULL, a {.cls gloss_capture}, a capture_id string, or a bundle directory path.")
}

draw_generic_printable <- function(x) {
  if (is.list(x) && inherits(x$gtable, "gtable")) {
    grid::grid.newpage()
    grid::grid.draw(x$gtable)
    return("gtable_slot")
  }
  if (methods::is(x, "S4") || isS4(x)) {
    utils::capture.output(methods::show(x))
    return("show")
  }
  utils::capture.output(print(x))
  "print"
}

make_mixed_fallback_engine <- function() {
  structure(
    list(
      name = "mixed",
      classes = character(),
      capture_fn = engine_mixed_capture,
      packages = character(),
      version = as.character(utils::packageVersion("gloss")),
      description = "Fallback engine for pages mixing base and grid graphics",
      priority = -100L,
      page_kind = "any",
      seq = 0L
    ),
    class = "gloss_engine"
  )
}

engine_mixed_capture <- function(x, ctx) {
  rp <- ctx$page_info$rp %||% tryCatch(grDevices::recordPlot(), error = function(e) NULL)
  close_capture_device(ctx$dev)
  all_orig_pages <- as.character(ctx$dev$read())
  n_orig_pages <- length(all_orig_pages)
  if (n_orig_pages == 0L) {
    cli::cli_abort("The input did not draw any page on the graphics device.")
  }
  sel_idx <- resolve_selected_page(ctx$page, n_orig_pages)
  original_svg <- all_orig_pages[[sel_idx]]

  doc <- read_svg_doc(original_svg)
  elements_df <- parse_svg_elements(doc)

  preview_png <- NULL
  if (isTRUE(ctx$preview) && !is.null(rp)) {
    preview_png <- tryCatch(
      render_preview_png(
        function() grDevices::replayPlot(rlang::duplicate(rp, shallow = FALSE)),
        width = ctx$width, height = ctx$height, dpi = ctx$preview_dpi
      ),
      error = function(e) NULL
    )
  }

  list(
    page = list(degraded = "mixed_graphics_systems"),
    scene = list(
      original_svg = original_svg,
      scene_svg = original_svg,
      leaves = empty_leaves_df(),
      elements = elements_df,
      dense_leaves = character(),
      rasters = list(),
      preview_png = preview_png,
      draw_method = ctx$draw_method %||% "mixed_fallback",
      pages = as.integer(n_orig_pages),
      selected_page = as.integer(sel_idx)
    ),
    ir = list(
      panels = list(),
      layers = list(),
      scales = list(),
      orders = stats::setNames(list(), character())
    ),
    tables = stats::setNames(list(), character()),
    lineage = empty_lineage_df()
  )
}

resolve_selected_page <- function(page, n_pages) {
  if (is.null(page)) {
    if (n_pages > 1L) {
      cli::cli_warn("The input drew {n_pages} pages; gloss captured page {n_pages} (last page).")
    }
    return(as.integer(n_pages))
  }
  p <- as.integer(page)
  if (p > n_pages) {
    cli::cli_warn("Requested page {p} exceeds {n_pages} drawn page{?s}; capturing page {n_pages}.")
    return(as.integer(n_pages))
  }
  p
}

# --- Figure sizing & device lifecycle ----------------------------------------

resolve_figure_size <- function(width = NULL, height = NULL) {
  basis <- "argument"
  if ((is.null(width) || is.null(height)) &&
      isTRUE(getOption("knitr.in.progress")) &&
      has_pkg("knitr")) {
    width <- width %||% knitr::opts_current$get("fig.width")
    height <- height %||% knitr::opts_current$get("fig.height")
    basis <- "knitr"
  }
  if (is.null(width) || is.null(height)) {
    basis <- "default"
  }
  w <- as.double(width %||% 7.0)
  h <- as.double(height %||% 5.0)
  if (!is.finite(w) || w <= 0 || !is.finite(h) || h <= 0) {
    cli::cli_abort("{.arg width} and {.arg height} must be positive finite numbers.")
  }
  list(width = w, height = h, basis = basis)
}

open_capture_device <- function(width, height) {
  reader <- svglite::svgstring(width = width, height = height, standalone = TRUE)
  dev_id <- grDevices::dev.cur()
  comp <- tryCatch(
    grDevices::dev.capabilities("compositing")$compositing,
    error = function(e) character()
  )
  if (!is.character(comp) || length(comp) == 0L) {
    grDevices::dev.off(dev_id)
    cli::cli_abort(
      "The capture device does not support graphics groups (requires R >= 4.2 and svglite >= 2.2.0)."
    )
  }
  grDevices::dev.control("enable")
  list(id = dev_id, read = reader, closed = FALSE)
}

close_capture_device <- function(dev) {
  if (!is.null(dev$id) && dev$id %in% grDevices::dev.list()) {
    grDevices::dev.off(dev$id)
  }
  invisible(NULL)
}

ensure_device_active <- function(dev) {
  if (!dev$id %in% grDevices::dev.list()) {
    cli::cli_abort(c(
      "The plotting code closed gloss's graphics device while drawing.",
      i = "Ensure the plot draws onto the active device rather than closing it."
    ))
  }
  if (grDevices::dev.cur() != dev$id) {
    grDevices::dev.set(dev$id)
  }
  invisible(NULL)
}

draw_input_object <- function(x) {
  if (inherits(x, "recordedplot")) {
    grDevices::replayPlot(rlang::duplicate(x, shallow = FALSE))
    return("replayPlot")
  }
  if (is.function(x)) {
    x()
    return("function")
  }
  if (inherits(x, c("grob", "gList"))) {
    grid::grid.newpage()
    grid::grid.draw(x)
    return("grid.draw")
  }
  if (methods::is(x, "S4") || isS4(x)) {
    methods::show(x)
    return("show")
  }
  print(x)
  "print"
}

dl_op_name <- function(el) {
  f <- tryCatch(el[[2L]][[1L]], error = function(e) NULL)
  if (is.list(f) && !is.null(f$name)) as.character(f$name)[[1L]] else "call"
}

detect_page_kind <- function() {
  rp <- tryCatch(grDevices::recordPlot(), error = function(e) NULL)
  ops <- if (is.null(rp)) character() else vapply(rp[[1L]], dl_op_name, character(1L))
  base_ops <- sum(startsWith(ops, "C_") & ops != "C_par")
  grid_ops <- sum(ops == "call" | startsWith(ops, "L_"))
  grobs <- length(grid::grid.ls(viewports = FALSE, recursive = FALSE, print = FALSE)$name)

  kind <- if (base_ops > 0L && grid_ops > 0L) {
    "mixed"
  } else if (base_ops > 0L) {
    "base"
  } else if (grobs > 0L) {
    "grid"
  } else {
    "empty"
  }

  list(
    kind = kind,
    base_ops = as.integer(base_ops),
    grid_ops = as.integer(grid_ops),
    grobs = as.integer(grobs),
    rp = rp
  )
}

# --- Capture context passed to engine capture_fn -----------------------------

make_capture_context <- function(
    dev,
    width,
    height,
    dense,
    sources,
    engine,
    already_drawn = FALSE,
    draw_method = NULL,
    page_info = NULL,
    preview = TRUE,
    preview_dpi = 144L,
    page = NULL,
    parent_capture_id = NULL,
    call_expr = NULL) {

  ctx <- new.env(parent = emptyenv())
  ctx$dev <- dev
  ctx$width <- width
  ctx$height <- height
  ctx$dense <- dense
  ctx$sources <- sources
  ctx$engine <- engine
  ctx$already_drawn <- already_drawn
  ctx$draw_method <- draw_method
  ctx$page_info <- page_info
  ctx$preview <- isTRUE(preview)
  ctx$preview_dpi <- as.integer(preview_dpi)
  ctx$page <- page
  ctx$parent_capture_id <- parent_capture_id
  ctx$call_expr <- call_expr

  ctx$ensure_device <- function() ensure_device_active(dev)
  ctx$detect_page <- function() detect_page_kind()
  ctx$draw_input <- function(obj) draw_input_object(obj)
  ctx$capture_grid <- function(draw_method = NULL) {
    capture_current_grid_page(
      dev = dev,
      width = width,
      height = height,
      dense = dense,
      draw_method = draw_method %||% ctx$draw_method %||% "grid.draw",
      preview = ctx$preview,
      preview_dpi = ctx$preview_dpi,
      page = ctx$page
    )
  }

  ctx
}

assemble_capture_result <- function(result, ctx, sources = NULL, input_obj = NULL) {
  if (!is.list(result) || is.null(result$scene)) {
    cli::cli_abort(
      "Engine {.val {ctx$engine$name}} {.fn capture_fn} must return a {.cls gloss_capture} or a list containing {.field scene}."
    )
  }

  sc <- result$scene
  device_str <- paste0("svglite ", as.character(utils::packageVersion("svglite")))
  n_pages <- result$page$pages %||% sc$pages %||% 1L
  sel_page <- result$page$selected_page %||% sc$selected_page %||% n_pages

  page <- list(
    engine = result$page$engine %||% ctx$engine$name,
    engine_version = result$page$engine_version %||% engine_version_string(ctx$engine),
    draw_method = result$page$draw_method %||% sc$draw_method %||% ctx$draw_method %||% "unknown",
    device = result$page$device %||% device_str,
    width_in = result$page$width_in %||% ctx$width,
    height_in = result$page$height_in %||% ctx$height,
    width_pt = result$page$width_pt %||% round_pt(ctx$width * PT_PER_IN),
    height_pt = result$page$height_pt %||% round_pt(ctx$height * PT_PER_IN),
    pages = as.integer(n_pages),
    selected_page = as.integer(sel_page)
  )
  if (!is.null(sc$preview_png)) {
    page$preview_dpi <- as.integer(ctx$preview_dpi %||% 144L)
  }
  if (!is.null(result$page$degraded)) {
    page$degraded <- result$page$degraded
  }

  ir <- result$ir %||% list()
  leaves <- sc$leaves %||% empty_leaves_df()
  elements <- sc$elements %||% empty_elements_df()
  lineage <- result$lineage %||% empty_lineage_df()

  sem_done <- finalize_scene_semantics(
    leaves = leaves,
    elements = elements,
    lineage = lineage,
    layers = ir$layers %||% list(),
    draw_method = page$draw_method
  )
  leaves <- sem_done$leaves
  lineage <- sem_done$lineage

  label_links <- result$label_links %||% sc$label_links %||% extract_repel_label_links(leaves, elements, lineage)

  sess_info <- result$session %||% collect_session_info(input_obj = input_obj, call_expr = ctx$call_expr)
  src_list <- result$sources %||% collect_sources_inventory(sources = sources, session = sess_info)

  new_gloss_capture(
    page = page,
    svg_original = sc$original_svg,
    svg_scene = sc$scene_svg,
    leaves = leaves,
    elements = elements,
    dense_leaves = sc$dense_leaves %||% character(),
    rasters = sc$rasters %||% list(),
    ir = ir,
    tables = result$tables %||% list(),
    lineage = lineage,
    sources = src_list,
    session = sess_info,
    preview_png = sc$preview_png,
    label_links = label_links,
    parent_capture_id = ctx$parent_capture_id
  )
}

# --- Draw-time viewport probe grob -------------------------------------------

probe_grob <- function(id, rec) {
  grid::gTree(
    name = paste0("gloss.probe.", id),
    cl = "gloss_probe",
    id = id,
    rec = rec
  )
}

#' @exportS3Method grid::drawDetails
drawDetails.gloss_probe <- function(x, recording) {
  rec <- x$rec
  corners <- grid::deviceLoc(
    grid::unit(c(0, 1, 1, 0), "npc"),
    grid::unit(c(0, 0, 1, 1), "npc")
  )
  xs <- grid::convertX(corners$x, "in", valueOnly = TRUE)
  ys <- grid::convertY(corners$y, "in", valueOnly = TRUE)
  vp <- grid::current.viewport()
  vp_path <- grid::current.vpPath()

  rec$n <- rec$n + 1L
  rec$order[rec$n] <- x$id
  rec$probes[[x$id]] <- list(
    vp = if (is.null(vp_path)) "ROOT" else as.character(vp_path),
    x = xs,
    y = ys,
    xscale = as.double(vp$xscale),
    yscale = as.double(vp$yscale)
  )
  invisible(NULL)
}

# --- Grid display-list leaf wrapping -----------------------------------------

normalize_grob_names <- function(g) {
  if (length(g$name) != 1L) {
    g$name <- as.character(g$name)[[1L]]
  }
  if (inherits(g, "gTree") && length(g$children) > 0L) {
    nms <- names(g$children)
    kids <- lapply(nms, function(nm) normalize_grob_names(g$children[[nm]]))
    new_kids <- do.call(grid::gList, kids)
    names(new_kids) <- nms
    g$children <- new_kids
  }
  g
}

wrap_grid_leaves <- function(g, parent_path, acc) {
  cur_path <- c(parent_path, g$name)
  # GridGroup (from grid::groupGrob) inherits gTree but holds its payload in `src`
  # rather than `children`; treat it as an atomic leaf so probes stay aligned.
  if (inherits(g, "gTree") && !inherits(g, "GridGroup")) {
    kids <- g$children
    if (length(kids) > 0L) {
      nms <- names(kids)
      wrapped <- lapply(nms, function(nm) wrap_grid_leaves(kids[[nm]], cur_path, acc))
      new_kids <- do.call(grid::gList, wrapped)
      names(new_kids) <- nms
      g$children <- new_kids
    }
    return(g)
  }

  # Non-drawing grobs or clipGrobs must stay unwrapped so clipping scope is preserved
  if (inherits(g, c("zeroGrob", "null", "clip"))) {
    return(g)
  }

  acc$k <- acc$k + 1L
  id <- sprintf("L%03d", acc$k)
  acc$leaves[[id]] <- list(
    leaf_id = id,
    grob_name = g$name %||% id,
    grob_path = paste(cur_path, collapse = "/"),
    grob_class = class(g)[[1L]]
  )

  leaf_vp <- g$vp
  g$vp <- NULL
  acc$grobs[[id]] <- g

  grid::gTree(
    children = grid::gList(
      probe_grob(id, acc$rec),
      grid::groupGrob(g)
    ),
    vp = leaf_vp,
    name = g$name,
    cl = "gloss_wrap",
    id = id
  )
}

# --- Grid page capture (dual SVG from single draw) ---------------------------

capture_current_grid_page <- function(
    dev,
    width,
    height,
    dense = 10000,
    draw_method = "grid.draw",
    preview = TRUE,
    preview_dpi = 144L,
    page = NULL) {
  ensure_device_active(dev)
  pages_before <- as.character(dev$read())
  n_orig_pages <- length(pages_before)
  if (n_orig_pages == 0L) {
    cli::cli_abort("The input did not draw any page on the graphics device.")
  }
  sel_idx <- resolve_selected_page(page, n_orig_pages)

  rec <- new.env(parent = emptyenv())
  rec$n <- 0L
  rec$order <- character()
  rec$probes <- list()

  acc <- new.env(parent = emptyenv())
  acc$k <- 0L
  acc$leaves <- list()
  acc$grobs <- list()
  acc$dl <- list()
  acc$rec <- rec

  grid::grid.force()
  grid::grid.DLapply(function(elt) {
    idx <- length(acc$dl) + 1L
    wrapped <- if (inherits(elt, "grob")) {
      wrap_grid_leaves(normalize_grob_names(elt), character(), acc)
    } else {
      elt
    }
    acc$dl[[idx]] <- wrapped
    wrapped
  })

  # Redraw the frozen, wrapped display list as a second page on the same device
  # so user code / RNG is never re-executed, then close the device so svglite
  # flushes closing </g></svg> tags for the final page.
  grid::grid.refresh()
  close_capture_device(dev)

  all_pages <- as.character(dev$read())
  # Original page is finalized once grid.refresh() opens the wrapped page
  original_svg <- all_pages[[sel_idx]]
  wrapped_svg <- all_pages[[length(all_pages)]]

  scene_doc <- if (sel_idx < n_orig_pages) {
    # grid.DLapply only holds the last drawn page's display list
    read_svg_doc(original_svg)
  } else {
    inline_svg_groups(
      wrapped_svg,
      order = rec$order,
      leaves_meta = acc$leaves,
      fallback_svg = original_svg
    )
  }
  svg_h_pt <- extract_svg_height_pt(wrapped_svg, fallback = height * PT_PER_IN)

  leaves_df <- if (sel_idx < n_orig_pages) {
    empty_leaves_df()
  } else {
    build_leaves_df(acc$leaves, rec$probes, svg_height_pt = svg_h_pt)
  }
  leaves_df <- attach_leaf_clips(leaves_df, scene_doc)
  elements_df <- parse_svg_elements(scene_doc)

  if (nrow(leaves_df) > 0L) {
    counts <- table(factor(elements_df$leaf_id, levels = leaves_df$leaf_id))
    leaves_df$n_elements <- as.integer(counts[leaves_df$leaf_id])
  }

  # Optional preview PNG rendered from the already-frozen display list (zero re-execution)
  preview_png <- NULL
  if (isTRUE(preview) && sel_idx == n_orig_pages && length(acc$dl) > 0L) {
    unwrapped_dl <- lapply(acc$dl, function(elt) {
      if (inherits(elt, "grob")) unwrap_gloss_wraps(elt, acc$grobs) else elt
    })
    preview_png <- tryCatch(
      render_preview_png(
        function() draw_grid_dl(unwrapped_dl),
        width = width, height = height, dpi = preview_dpi
      ),
      error = function(e) NULL
    )
  }

  # Optional dense-leaf rasterization (non-text leaves exceeding `dense`)
  dense_ids <- character()
  rasters <- list()
  if (is.finite(dense) && nrow(leaves_df) > 0L) {
    text_leaves <- unique(elements_df$leaf_id[!is.na(elements_df$leaf_id) & elements_df$tag == "text"])
    dense_ids <- leaves_df$leaf_id[
      leaves_df$n_elements >= dense & !(leaves_df$leaf_id %in% text_leaves)
    ]
    if (length(dense_ids) > 0L) {
      rasters <- rasterize_dense_grid_leaves(
        dl = acc$dl,
        grobs = acc$grobs,
        leaf_ids = dense_ids,
        width = width,
        height = height
      )
      ns <- svg_ns()
      w_pt <- round_pt(width * PT_PER_IN)
      h_pt <- round_pt(height * PT_PER_IN)
      for (lid in names(rasters)) {
        gnode <- xml2::xml_find_first(scene_doc, sprintf("//d1:g[@data-gloss-leaf='%s']", lid), ns)
        if (!inherits(gnode, "xml_missing")) {
          xml2::xml_remove(xml2::xml_children(gnode))
          xml2::xml_set_attr(gnode, "data-gloss-raster", "true")
          xml2::xml_add_child(
            gnode,
            "image",
            x = "0",
            y = "0",
            width = sprintf("%.2f", w_pt),
            height = sprintf("%.2f", h_pt),
            preserveAspectRatio = "none",
            href = paste0("rasters/", lid, ".png")
          )
        }
      }
      dense_ids <- names(rasters)
      leaves_df$dense <- leaves_df$leaf_id %in% dense_ids
    }
  }

  list(
    original_svg = original_svg,
    scene_svg = as.character(scene_doc),
    leaves = leaves_df,
    elements = elements_df,
    dense_leaves = dense_ids,
    rasters = rasters,
    preview_png = preview_png,
    draw_method = draw_method,
    pages = as.integer(n_orig_pages),
    selected_page = as.integer(sel_idx)
  )
}

# --- SVG <defs>/<use> inlining & xml2 parsing --------------------------------

svg_ns <- function() {
  c(d1 = "http://www.w3.org/2000/svg")
}

read_svg_doc <- function(svg_text) {
  xml2::read_xml(svg_text, options = c("NOBLANKS", "HUGE"))
}

extract_svg_height_pt <- function(svg_text, fallback = 360.0) {
  m <- regmatches(svg_text, regexpr("viewBox=['\"][^'\"]*['\"]", svg_text))
  if (length(m) == 0L || !nzchar(m)) {
    return(as.double(fallback))
  }
  inner <- sub("^viewBox=['\"]([^'\"]*)['\"]$", "\\1", m)
  parts <- suppressWarnings(as.numeric(strsplit(trimws(inner), "\\s+")[[1L]]))
  if (length(parts) >= 4L && is.finite(parts[[4L]])) {
    return(parts[[4L]])
  }
  as.double(fallback)
}

extract_use_hrefs <- function(uses) {
  if (length(uses) == 0L) return(character())
  hrefs <- xml2::xml_attr(uses, "href")
  if (anyNA(hrefs)) {
    xlink_hrefs <- xml2::xml_attr(uses, "xlink:href")
    hrefs[is.na(hrefs)] <- xlink_hrefs[is.na(hrefs)]
  }
  sub("^#", "", hrefs)
}

inline_nested_svg_groups <- function(doc, ns) {
  # Inline any user-authored nested <defs><g id="group-..."> + <use> pairs so
  # primitives drawn inside a user groupGrob remain directly addressable.
  repeat {
    nested_groups <- xml2::xml_find_all(doc, "//d1:defs/d1:g[starts-with(@id, 'group-')]", ns)
    if (length(nested_groups) == 0L) break
    gids <- xml2::xml_attr(nested_groups, "id")
    uses <- xml2::xml_find_all(doc, "//d1:use", ns)
    hrefs <- extract_use_hrefs(uses)

    replaced_any <- FALSE
    for (i in seq_along(nested_groups)) {
      ui <- match(gids[[i]], hrefs)
      if (is.na(ui)) next
      gnode <- nested_groups[[i]]
      xml2::xml_replace(uses[[ui]], gnode, .copy = FALSE)
      xml2::xml_set_attr(gnode, "id", NULL)
      replaced_any <- TRUE
    }
    if (!replaced_any) break
  }
  invisible(doc)
}

inline_svg_groups <- function(wrapped_svg, order, leaves_meta, fallback_svg = NULL) {
  doc <- read_svg_doc(wrapped_svg)
  ns <- svg_ns()
  n_probe <- length(order)
  if (n_probe == 0L) {
    return(doc)
  }

  # Top-level wrapper groups defined directly under svglite's root <g> (not nested
  # inside another <defs>) correspond 1-to-1 in draw order with our leaf probes.
  # Filter to groups actually referenced by a top-level <use> so an unreferenced
  # orphan <defs> never breaks whole-page alignment.
  top_groups <- xml2::xml_find_all(
    doc,
    "//d1:defs[not(ancestor::d1:defs)]/d1:g[starts-with(@id, 'group-')]",
    ns
  )
  top_gids <- xml2::xml_attr(top_groups, "id")
  top_uses <- xml2::xml_find_all(doc, "//d1:use[not(ancestor::d1:defs)]", ns)
  top_hrefs <- extract_use_hrefs(top_uses)

  # Match in draw (<use>) order
  grp_idx_for_use <- match(top_hrefs, top_gids)
  valid_use <- which(!is.na(grp_idx_for_use))

  if (length(valid_use) != n_probe) {
    cli::cli_warn(
      "Could not align {n_probe} draw-time probe{?s} with {length(valid_use)} top-level SVG group{?s}; falling back to untouched SVG without leaf misattribution."
    )
    return(if (!is.null(fallback_svg)) read_svg_doc(fallback_svg) else doc)
  }

  for (k in seq_len(n_probe)) {
    lid <- order[[k]]
    ui <- valid_use[[k]]
    gnode <- top_groups[[grp_idx_for_use[[ui]]]]
    xml2::xml_replace(top_uses[[ui]], gnode, .copy = FALSE)
    xml2::xml_set_attr(gnode, "id", lid)
    xml2::xml_set_attr(gnode, "data-gloss-leaf", lid)
    meta <- leaves_meta[[lid]]
    if (!is.null(meta$grob_name) && nzchar(meta$grob_name)) {
      xml2::xml_set_attr(gnode, "data-grob-name", meta$grob_name)
    }
  }

  # Inline any inner nested user groupGrobs now sitting inside <g id="L...">
  inline_nested_svg_groups(doc, ns)

  empty_defs <- xml2::xml_find_all(doc, "//d1:defs[not(*)]", ns)
  if (length(empty_defs) > 0L) {
    xml2::xml_remove(empty_defs)
  }

  doc
}

extract_layout_slot <- function(vp_path) {
  if (is.na(vp_path) || !nzchar(vp_path) || identical(vp_path, "ROOT")) {
    return("ROOT")
  }
  segs <- strsplit(vp_path, "::", fixed = TRUE)[[1L]]
  layout_idx <- which(segs == "layout")
  if (length(layout_idx) > 0L) {
    slots <- character()
    for (idx in layout_idx) {
      slot_pos <- idx + 1L
      if (slot_pos <= length(segs)) {
        slots <- c(slots, sub("\\.[0-9]+-[0-9]+-[0-9]+-[0-9]+$", "", segs[[slot_pos]]))
      }
    }
    if (length(slots) > 0L) {
      # Preserve outer guide-box* container identity so inner legend background/title
      # grobs are not misclassified as plot-level background or title slots.
      gb <- grep("^guide-box", slots, value = TRUE)
      if (length(gb) > 0L) {
        return(gb[[1L]])
      }
      return(slots[[length(slots)]])
    }
  }
  # Fall back to the deepest non-synthetic viewport name
  named <- segs[!grepl("^GRID\\.VP\\.[0-9]+$", segs)]
  target <- if (length(named) > 0L) named[[length(named)]] else segs[[length(segs)]]
  sub("\\.[0-9]+-[0-9]+-[0-9]+-[0-9]+$", "", target)
}

build_leaves_df <- function(leaves_meta, probes, svg_height_pt) {
  ids <- names(leaves_meta)
  if (length(ids) == 0L) {
    return(empty_leaves_df())
  }

  box_mat <- t(vapply(ids, function(id) {
    p <- probes[[id]]
    if (is.null(p)) return(rep(NA_real_, 4L))
    c(min(p$x), max(p$x), min(p$y), max(p$y))
  }, numeric(4L)))

  get_scale <- function(id, field, idx) {
    p <- probes[[id]]
    if (is.null(p) || length(p[[field]]) < idx) return(NA_real_)
    as.double(p[[field]][[idx]])
  }

  vp_paths <- vapply(ids, function(id) {
    p <- probes[[id]]
    if (is.null(p)) NA_character_ else as.character(p$vp)[[1L]]
  }, character(1L))

  n_ids <- length(ids)
  data.frame(
    leaf_id = ids,
    grob_name = vapply(leaves_meta, function(m) as.character(m$grob_name)[[1L]], character(1L)),
    grob_path = vapply(leaves_meta, function(m) as.character(m$grob_path)[[1L]], character(1L)),
    grob_class = vapply(leaves_meta, function(m) as.character(m$grob_class)[[1L]], character(1L)),
    vp_path = vp_paths,
    layout_slot = vapply(vp_paths, extract_layout_slot, character(1L)),
    bbox_x0 = round_pt(box_mat[, 1L] * PT_PER_IN),
    bbox_y0 = round_pt(svg_height_pt - box_mat[, 4L] * PT_PER_IN),
    bbox_x1 = round_pt(box_mat[, 2L] * PT_PER_IN),
    bbox_y1 = round_pt(svg_height_pt - box_mat[, 3L] * PT_PER_IN),
    xscale0 = vapply(ids, get_scale, numeric(1L), field = "xscale", idx = 1L),
    xscale1 = vapply(ids, get_scale, numeric(1L), field = "xscale", idx = 2L),
    yscale0 = vapply(ids, get_scale, numeric(1L), field = "yscale", idx = 1L),
    yscale1 = vapply(ids, get_scale, numeric(1L), field = "yscale", idx = 2L),
    n_elements = integer(n_ids),
    dense = rep(FALSE, n_ids),
    clip_id = rep(NA_character_, n_ids),
    clip_x0 = rep(NA_real_, n_ids),
    clip_y0 = rep(NA_real_, n_ids),
    clip_x1 = rep(NA_real_, n_ids),
    clip_y1 = rep(NA_real_, n_ids),
    z_index = seq_len(n_ids),
    semantic_role = rep(NA_character_, n_ids),
    edit_policy = rep(NA_character_, n_ids),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

# --- SVG element extraction --------------------------------------------------

SVG_PRIM_TAGS <- c("circle", "rect", "line", "polyline", "polygon", "path", "text", "image")

prim_xpath <- function() {
  sel <- paste0("self::d1:", SVG_PRIM_TAGS, collapse = " or ")
  sprintf(
    "//*[(%s) and not(ancestor::d1:defs) and not(ancestor::d1:clipPath) and not(ancestor::d1:mask) and not(ancestor::d1:pattern)]",
    sel
  )
}

num_svg_attr <- function(nodes, attr_name) {
  suppressWarnings(as.numeric(sub("px$", "", xml2::xml_attr(nodes, attr_name))))
}

css_style_value <- function(style, prop) {
  u <- unique(style)
  pat <- paste0("(?:^|;)\\s*", prop, ":\\s*([^;]+)")
  has <- grepl(pat, u, perl = TRUE)
  val <- rep(NA_character_, length(u))
  val[has] <- trimws(sub(paste0("^.*?", pat, ".*$"), "\\1", u[has], perl = TRUE))
  val[match(style, u)]
}

svg_attr_or_style <- function(nodes, style, prop) {
  val <- css_style_value(style, prop)
  missing_val <- is.na(val)
  if (any(missing_val)) {
    attr_val <- xml2::xml_attr(nodes[missing_val], prop)
    val[missing_val] <- attr_val
  }
  val
}

seq_within_group <- function(owner) {
  out <- rep(NA_integer_, length(owner))
  ok <- !is.na(owner)
  if (!any(ok)) return(out)
  g <- owner[ok]
  idx <- seq_along(g)
  ord <- order(match(g, unique(g)), idx)
  runs <- rle(g[ord])
  seqs <- sequence(runs$lengths)
  res <- integer(length(g))
  res[ord] <- seqs
  out[ok] <- as.integer(res)
  out
}

pair_coord_range <- function(s) {
  nums <- regmatches(s, gregexpr("-?[0-9]*\\.?[0-9]+(?:[eE][-+]?[0-9]+)?", s, perl = TRUE))
  t(vapply(nums, function(v) {
    v <- as.numeric(v)
    if (length(v) < 2L) return(rep(NA_real_, 4L))
    xs <- v[c(TRUE, FALSE)]
    ys <- v[c(FALSE, TRUE)]
    c(min(xs), max(xs), min(ys), max(ys))
  }, numeric(4L)))
}

# Compute exact extrema points along an SVG elliptical arc (SVG 1.1 F.6.5)
svg_arc_extrema <- function(x1, y1, rx, ry, phi_deg, large_arc, sweep, x2, y2) {
  rx <- abs(rx)
  ry <- abs(ry)
  if (!is.finite(rx) || !is.finite(ry) || rx == 0 || ry == 0 || (x1 == x2 && y1 == y2)) {
    return(list(x = c(x1, x2), y = c(y1, y2)))
  }
  phi <- phi_deg * pi / 180
  cphi <- cos(phi)
  sphi <- sin(phi)

  dx2 <- (x1 - x2) / 2
  dy2 <- (y1 - y2) / 2
  x1p <- cphi * dx2 + sphi * dy2
  y1p <- -sphi * dx2 + cphi * dy2

  # Scale radii up if endpoints are too far apart
  lam <- (x1p^2) / (rx^2) + (y1p^2) / (ry^2)
  if (lam > 1) {
    s <- sqrt(lam)
    rx <- rx * s
    ry <- ry * s
  }

  num <- max(0, rx^2 * ry^2 - rx^2 * y1p^2 - ry^2 * x1p^2)
  den <- rx^2 * y1p^2 + ry^2 * x1p^2
  coef <- if (den > 0) sqrt(num / den) else 0
  if (identical(as.integer(large_arc != 0), as.integer(sweep != 0))) {
    coef <- -coef
  }

  cxp <- coef * (rx * y1p / ry)
  cyp <- coef * (-ry * x1p / rx)
  cx <- cphi * cxp - sphi * cyp + (x1 + x2) / 2
  cy <- sphi * cxp + cphi * cyp + (y1 + y2) / 2

  vec_angle <- function(ux, uy, vx, vy) {
    dot <- ux * vx + uy * vy
    mag <- sqrt((ux^2 + uy^2) * (vx^2 + vy^2))
    if (mag == 0) return(0)
    ang <- acos(max(-1, min(1, dot / mag)))
    if (ux * vy - uy * vx < 0) -ang else ang
  }

  t1 <- vec_angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
  dt <- vec_angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
  if (sweep == 0 && dt > 0) dt <- dt - 2 * pi
  if (sweep != 0 && dt < 0) dt <- dt + 2 * pi

  # Sample extrema candidates analytically + 8-point arc guard for rotated ellipses
  t_cand <- c(t1, t1 + dt)
  tx <- atan2(-ry * sphi, rx * cphi)
  ty <- atan2(ry * cphi, rx * sphi)
  crit <- c(tx, tx + pi, ty, ty + pi)
  t_lo <- min(t1, t1 + dt)
  t_hi <- max(t1, t1 + dt)
  for (tc in crit) {
    for (k in -2:2) {
      ang <- tc + k * 2 * pi
      if (ang >= t_lo && ang <= t_hi) {
        t_cand <- c(t_cand, ang)
      }
    }
  }

  xs <- cx + rx * cos(t_cand) * cphi - ry * sin(t_cand) * sphi
  ys <- cy + rx * cos(t_cand) * sphi + ry * sin(t_cand) * cphi
  list(x = c(x1, x2, xs), y = c(y1, y2, ys))
}
# C/c, S/s, Q/q, T/t, A/a, and Z/z without confusing single-axis or arc args.
parse_single_path_bbox <- function(d) {
  if (is.na(d) || !nzchar(d)) return(rep(NA_real_, 4L))
  toks <- regmatches(
    d,
    gregexpr("[A-Za-z]|[-+]?(?:[0-9]*\\.[0-9]+|[0-9]+\\.?)(?:[eE][-+]?[0-9]+)?", d, perl = TRUE)
  )[[1L]]
  n_tok <- length(toks)
  if (n_tok == 0L) return(rep(NA_real_, 4L))

  is_cmd <- grepl("^[A-Za-z]$", toks)
  cx <- 0
  cy <- 0
  sx <- 0
  sy <- 0
  xs <- numeric()
  ys <- numeric()
  cmd <- ""
  i <- 1L

  take_nums <- function(k) {
    if (i + k - 1L > n_tok || any(is_cmd[i:(i + k - 1L)])) return(NULL)
    vals <- as.numeric(toks[i:(i + k - 1L)])
    vals
  }

  while (i <= n_tok) {
    if (is_cmd[[i]]) {
      cmd <- toks[[i]]
      i <- i + 1L
      if (cmd %in% c("Z", "z")) {
        cx <- sx
        cy <- sy
        next
      }
    }
    if (!nzchar(cmd) || i > n_tok || is_cmd[[i]]) next

    up <- toupper(cmd)
    rel <- !identical(cmd, up)

    if (up %in% c("M", "L", "T")) {
      v <- take_nums(2L)
      if (is.null(v)) break
      i <- i + 2L
      nx <- if (rel) cx + v[[1L]] else v[[1L]]
      ny <- if (rel) cy + v[[2L]] else v[[2L]]
      cx <- nx
      cy <- ny
      xs <- c(xs, cx)
      ys <- c(ys, cy)
      if (up == "M") {
        sx <- cx
        sy <- cy
        # Subsequent coordinate pairs after M/m are implicit L/l commands
        cmd <- if (rel) "l" else "L"
      }
    } else if (up == "H") {
      v <- take_nums(1L)
      if (is.null(v)) break
      i <- i + 1L
      cx <- if (rel) cx + v[[1L]] else v[[1L]]
      xs <- c(xs, cx)
      ys <- c(ys, cy)
    } else if (up == "V") {
      v <- take_nums(1L)
      if (is.null(v)) break
      i <- i + 1L
      cy <- if (rel) cy + v[[1L]] else v[[1L]]
      xs <- c(xs, cx)
      ys <- c(ys, cy)
    } else if (up == "C") {
      v <- take_nums(6L)
      if (is.null(v)) break
      i <- i + 6L
      pts_x <- if (rel) cx + v[c(1L, 3L, 5L)] else v[c(1L, 3L, 5L)]
      pts_y <- if (rel) cy + v[c(2L, 4L, 6L)] else v[c(2L, 4L, 6L)]
      xs <- c(xs, pts_x)
      ys <- c(ys, pts_y)
      cx <- pts_x[[3L]]
      cy <- pts_y[[3L]]
    } else if (up %in% c("S", "Q")) {
      v <- take_nums(4L)
      if (is.null(v)) break
      i <- i + 4L
      pts_x <- if (rel) cx + v[c(1L, 3L)] else v[c(1L, 3L)]
      pts_y <- if (rel) cy + v[c(2L, 4L)] else v[c(2L, 4L)]
      xs <- c(xs, pts_x)
      ys <- c(ys, pts_y)
      cx <- pts_x[[2L]]
      cy <- pts_y[[2L]]
    } else if (up == "A") {
      v <- take_nums(7L)
      if (is.null(v)) break
      i <- i + 7L
      nx <- if (rel) cx + v[[6L]] else v[[6L]]
      ny <- if (rel) cy + v[[7L]] else v[[7L]]
      ext <- svg_arc_extrema(cx, cy, v[[1L]], v[[2L]], v[[3L]], v[[4L]], v[[5L]], nx, ny)
      cx <- nx
      cy <- ny
      xs <- c(xs, ext$x)
      ys <- c(ys, ext$y)
    } else {
      i <- i + 1L
    }
  }

  if (length(xs) == 0L || length(ys) == 0L) return(rep(NA_real_, 4L))
  c(min(xs), max(xs), min(ys), max(ys))
}

path_coord_range <- function(d_vec) {
  if (length(d_vec) == 0L) return(matrix(numeric(), 0L, 4L))
  t(vapply(d_vec, parse_single_path_bbox, numeric(4L)))
}

estimate_text_width_units <- function(txt_vec) {
  vapply(txt_vec, function(s) {
    if (is.na(s) || !nzchar(s)) return(0.0)
    cps <- utf8ToInt(enc2utf8(s))
    if (length(cps) == 0L) return(0.0)
    # CJK / Hangul / Kana / fullwidth glyphs (~1.0 em) vs Latin/ASCII (~0.6 em)
    is_wide <- cps >= 0x1100L
    sum(ifelse(is_wide, 1.0, 0.6))
  }, numeric(1L))
}

estimate_text_boxes <- function(nodes, style) {
  fs <- suppressWarnings(as.numeric(sub("px$", "", svg_attr_or_style(nodes, style, "font-size"))))
  fs[is.na(fs)] <- 12.0
  w <- num_svg_attr(nodes, "textLength")
  txt <- xml2::xml_text(nodes)
  miss_w <- is.na(w)
  if (any(miss_w)) {
    w[miss_w] <- fs[miss_w] * estimate_text_width_units(txt[miss_w])
  }
  anchor <- xml2::xml_attr(nodes, "text-anchor")
  anchor[is.na(anchor)] <- "start"
  lx0 <- ifelse(anchor == "middle", -w / 2, ifelse(anchor == "end", -w, 0))
  lx1 <- lx0 + w
  ly0 <- -0.8 * fs
  ly1 <- 0.2 * fs

  tr <- xml2::xml_attr(nodes, "transform")
  x <- num_svg_attr(nodes, "x")
  y <- num_svg_attr(nodes, "y")
  tx <- ifelse(is.na(x), 0, x)
  ty <- ifelse(is.na(y), 0, y)
  ang <- rep(0, length(nodes))

  has_tr <- !is.na(tr)
  if (any(has_tr)) {
    tt <- regmatches(tr[has_tr], regexec("translate\\(\\s*([-0-9.eE]+)[ ,]+([-0-9.eE]+)\\s*\\)", tr[has_tr]))
    rr <- regmatches(tr[has_tr], regexec("rotate\\(\\s*([-0-9.eE]+)", tr[has_tr]))
    tx[has_tr] <- tx[has_tr] + vapply(tt, function(v) if (length(v) == 3L) as.numeric(v[[2L]]) else 0, numeric(1L))
    ty[has_tr] <- ty[has_tr] + vapply(tt, function(v) if (length(v) == 3L) as.numeric(v[[3L]]) else 0, numeric(1L))
    ang[has_tr] <- vapply(rr, function(v) if (length(v) == 2L) as.numeric(v[[2L]]) else 0, numeric(1L))
  }

  th <- ang * pi / 180
  cx <- cbind(lx0, lx1, lx1, lx0)
  cy <- cbind(ly0, ly0, ly1, ly1)
  rx <- cos(th) * cx - sin(th) * cy + tx
  ry <- sin(th) * cx + cos(th) * cy + ty
  cbind(apply(rx, 1L, min), apply(rx, 1L, max), apply(ry, 1L, min), apply(ry, 1L, max))
}

compose_affine2d <- function(m1, m2) {
  c(
    m1[[1L]] * m2[[1L]] + m1[[3L]] * m2[[2L]],
    m1[[2L]] * m2[[1L]] + m1[[4L]] * m2[[2L]],
    m1[[1L]] * m2[[3L]] + m1[[3L]] * m2[[4L]],
    m1[[2L]] * m2[[3L]] + m1[[4L]] * m2[[4L]],
    m1[[1L]] * m2[[5L]] + m1[[3L]] * m2[[6L]] + m1[[5L]],
    m1[[2L]] * m2[[5L]] + m1[[4L]] * m2[[6L]] + m1[[6L]]
  )
}

parse_svg_transform_matrix <- function(tr_str) {
  cur <- c(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
  if (is.na(tr_str) || !nzchar(tr_str)) return(cur)
  ops <- regmatches(tr_str, gregexpr("(matrix|translate|scale|rotate)\\s*\\([^)]*\\)", tr_str, perl = TRUE))[[1L]]
  for (op in ops) {
    kind <- sub("^([a-z]+).*$", "\\1", op)
    nums <- suppressWarnings(as.numeric(
      regmatches(op, gregexpr("[-+]?(?:[0-9]*\\.[0-9]+|[0-9]+\\.?)(?:[eE][-+]?[0-9]+)?", op, perl = TRUE))[[1L]]
    ))
    if (identical(kind, "matrix") && length(nums) == 6L) {
      cur <- compose_affine2d(cur, nums)
    } else if (identical(kind, "translate") && length(nums) >= 1L) {
      ty <- if (length(nums) >= 2L) nums[[2L]] else 0.0
      cur <- compose_affine2d(cur, c(1, 0, 0, 1, nums[[1L]], ty))
    } else if (identical(kind, "scale") && length(nums) >= 1L) {
      sy <- if (length(nums) >= 2L) nums[[2L]] else nums[[1L]]
      cur <- compose_affine2d(cur, c(nums[[1L]], 0, 0, sy, 0, 0))
    } else if (identical(kind, "rotate") && length(nums) >= 1L) {
      rad <- nums[[1L]] * pi / 180
      cs <- cos(rad)
      sn <- sin(rad)
      if (length(nums) >= 3L) {
        cur <- compose_affine2d(cur, c(1, 0, 0, 1, nums[[2L]], nums[[3L]]))
        cur <- compose_affine2d(cur, c(cs, sn, -sn, cs, 0, 0))
        cur <- compose_affine2d(cur, c(1, 0, 0, 1, -nums[[2L]], -nums[[3L]]))
      } else {
        cur <- compose_affine2d(cur, c(cs, sn, -sn, cs, 0, 0))
      }
    }
  }
  cur
}

apply_ancestor_group_transforms <- function(nodes, tag, box, ns = svg_ns()) {
  if (length(nodes) == 0L) return(box)
  root <- xml2::xml_root(nodes[[1L]])
  if (length(xml2::xml_find_all(root, "//d1:g[@transform]", ns)) == 0L) {
    return(box)
  }
  # Cascade ancestor <g transform="..."> matrices (and self transform for non-text shapes)
  for (idx in seq_along(nodes)) {
    if (any(!is.finite(box[idx, ]))) next
    ancs <- xml2::xml_find_all(nodes[[idx]], "ancestor::d1:g[@transform]", ns)
    trs <- if (length(ancs) > 0L) xml2::xml_attr(ancs, "transform") else character()
    if (!identical(tag[[idx]], "text")) {
      self_tr <- xml2::xml_attr(nodes[[idx]], "transform")
      if (!is.na(self_tr) && nzchar(self_tr)) {
        trs <- c(trs, self_tr)
      }
    }
    if (length(trs) == 0L) next
    mat <- c(1, 0, 0, 1, 0, 0)
    for (tstr in trs) {
      mat <- compose_affine2d(mat, parse_svg_transform_matrix(tstr))
    }
    xs <- c(box[idx, 1L], box[idx, 2L], box[idx, 2L], box[idx, 1L])
    ys <- c(box[idx, 3L], box[idx, 3L], box[idx, 4L], box[idx, 4L])
    tx <- mat[[1L]] * xs + mat[[3L]] * ys + mat[[5L]]
    ty <- mat[[2L]] * xs + mat[[4L]] * ys + mat[[6L]]
    box[idx, ] <- c(min(tx), max(tx), min(ty), max(ty))
  }
  box
}

compute_element_boxes <- function(nodes, tag, style) {
  box <- matrix(NA_real_, nrow = length(nodes), ncol = 4L)

  i <- which(tag == "circle")
  if (length(i) > 0L) {
    cx <- num_svg_attr(nodes[i], "cx")
    cy <- num_svg_attr(nodes[i], "cy")
    r <- num_svg_attr(nodes[i], "r")
    box[i, ] <- cbind(cx - r, cx + r, cy - r, cy + r)
  }

  i <- which(tag %in% c("rect", "image"))
  if (length(i) > 0L) {
    x <- num_svg_attr(nodes[i], "x")
    y <- num_svg_attr(nodes[i], "y")
    w <- num_svg_attr(nodes[i], "width")
    h <- num_svg_attr(nodes[i], "height")
    x[is.na(x)] <- 0
    y[is.na(y)] <- 0
    pct <- grepl("%", xml2::xml_attr(nodes[i], "width"))
    if (any(pct)) {
      root <- xml2::xml_root(nodes[[1L]])
      vb <- as.numeric(strsplit(trimws(xml2::xml_attr(root, "viewBox")), "\\s+")[[1L]])
      w[pct] <- vb[[3L]]
      h[pct] <- vb[[4L]]
    }
    box[i, ] <- cbind(pmin(x, x + w), pmax(x, x + w), pmin(y, y + h), pmax(y, y + h))
  }

  i <- which(tag == "line")
  if (length(i) > 0L) {
    ax <- num_svg_attr(nodes[i], "x1")
    ay <- num_svg_attr(nodes[i], "y1")
    bx <- num_svg_attr(nodes[i], "x2")
    by <- num_svg_attr(nodes[i], "y2")
    box[i, ] <- cbind(pmin(ax, bx), pmax(ax, bx), pmin(ay, by), pmax(ay, by))
  }

  i <- which(tag %in% c("polyline", "polygon"))
  if (length(i) > 0L) {
    b <- pair_coord_range(xml2::xml_attr(nodes[i], "points"))
    box[i, ] <- cbind(b[, 1L], b[, 2L], b[, 3L], b[, 4L])
  }

  i <- which(tag == "path")
  if (length(i) > 0L) {
    b <- path_coord_range(xml2::xml_attr(nodes[i], "d"))
    box[i, ] <- cbind(b[, 1L], b[, 2L], b[, 3L], b[, 4L])
  }

  i <- which(tag == "text")
  if (length(i) > 0L) {
    b <- estimate_text_boxes(nodes[i], style[i])
    box[i, ] <- cbind(b[, 1L], b[, 2L], b[, 3L], b[, 4L])
  }

  box <- apply_ancestor_group_transforms(nodes, tag, box)
  list(x0 = box[, 1L], x1 = box[, 2L], y0 = box[, 3L], y1 = box[, 4L])
}

parse_clip_url_ids <- function(val) {
  if (length(val) == 0L) return(character())
  out <- rep(NA_character_, length(val))
  ok <- !is.na(val) & grepl("url\\(", val)
  if (any(ok)) {
    out[ok] <- sub("^.*url\\(['\"]?#([^'\")]+)['\"]?\\).*$", "\\1", val[ok], perl = TRUE)
  }
  out
}

extract_clip_defs <- function(doc, ns = svg_ns()) {
  cp_nodes <- xml2::xml_find_all(doc, "//d1:clipPath[@id]", ns)
  clip_map <- list()
  for (cp in cp_nodes) {
    cid <- xml2::xml_attr(cp, "id")
    if (is.na(cid) || !nzchar(cid)) next
    kids <- xml2::xml_find_all(
      cp,
      "*[(self::d1:rect or self::d1:path or self::d1:polygon or self::d1:polyline or self::d1:circle)]",
      ns
    )
    if (length(kids) == 0L) next
    ktags <- xml2::xml_name(kids)
    kstyle <- xml2::xml_attr(kids, "style")
    kstyle[is.na(kstyle)] <- ""
    kb <- compute_element_boxes(kids, ktags, kstyle)
    if (any(is.finite(kb$x0)) && any(is.finite(kb$y0))) {
      clip_map[[cid]] <- c(
        min(kb$x0, na.rm = TRUE),
        min(kb$y0, na.rm = TRUE),
        max(kb$x1, na.rm = TRUE),
        max(kb$y1, na.rm = TRUE)
      )
    }
  }
  has_nested <- length(xml2::xml_find_all(doc, "//*[@clip-path and ancestor::*[@clip-path]]", ns)) > 0L
  list(map = clip_map, has_nested = has_nested)
}

resolve_node_clips <- function(nodes, clip_info, ns = svg_ns()) {
  n <- length(nodes)
  cids <- rep(NA_character_, n)
  cx0 <- rep(NA_real_, n)
  cy0 <- rep(NA_real_, n)
  cx1 <- rep(NA_real_, n)
  cy1 <- rep(NA_real_, n)
  if (n == 0L) {
    return(list(clip_id = cids, clip_x0 = cx0, clip_y0 = cy0, clip_x1 = cx1, clip_y1 = cy1))
  }

  cmap <- clip_info$map
  if (!isTRUE(clip_info$has_nested)) {
    anc <- xml2::xml_find_first(nodes, "ancestor-or-self::*[@clip-path][1]", ns)
    cids <- parse_clip_url_ids(xml2::xml_attr(anc, "clip-path"))
    known <- which(!is.na(cids) & cids %in% names(cmap))
    if (length(known) > 0L) {
      mat <- do.call(rbind, cmap[cids[known]])
      cx0[known] <- round_pt(mat[, 1L])
      cy0[known] <- round_pt(mat[, 2L])
      cx1[known] <- round_pt(mat[, 3L])
      cy1[known] <- round_pt(mat[, 4L])
    }
  } else {
    for (i in seq_len(n)) {
      ancs <- xml2::xml_find_all(nodes[[i]], "ancestor-or-self::*[@clip-path]", ns)
      if (length(ancs) == 0L) next
      ids <- parse_clip_url_ids(xml2::xml_attr(ancs, "clip-path"))
      ids <- ids[!is.na(ids)]
      if (length(ids) == 0L) next
      cids[[i]] <- ids[[length(ids)]]
      boxes <- cmap[intersect(ids, names(cmap))]
      if (length(boxes) > 0L) {
        mat <- do.call(rbind, boxes)
        cx0[[i]] <- round_pt(max(mat[, 1L]))
        cy0[[i]] <- round_pt(max(mat[, 2L]))
        cx1[[i]] <- round_pt(min(mat[, 3L]))
        cy1[[i]] <- round_pt(min(mat[, 4L]))
      }
    }
  }

  list(clip_id = cids, clip_x0 = cx0, clip_y0 = cy0, clip_x1 = cx1, clip_y1 = cy1)
}

attach_leaf_clips <- function(leaves_df, doc) {
  if (!is.data.frame(leaves_df) || nrow(leaves_df) == 0L) {
    return(leaves_df)
  }
  ns <- svg_ns()
  gnodes <- xml2::xml_find_all(doc, "//d1:g[@data-gloss-leaf]", ns)
  if (length(gnodes) == 0L) {
    return(leaves_df)
  }
  glids <- xml2::xml_attr(gnodes, "data-gloss-leaf")
  idx <- match(leaves_df$leaf_id, glids)
  ok <- which(!is.na(idx))
  if (length(ok) == 0L) {
    return(leaves_df)
  }
  clip_info <- extract_clip_defs(doc, ns)
  resolved <- resolve_node_clips(gnodes[idx[ok]], clip_info, ns)
  leaves_df$clip_id[ok] <- resolved$clip_id
  leaves_df$clip_x0[ok] <- resolved$clip_x0
  leaves_df$clip_y0[ok] <- resolved$clip_y0
  leaves_df$clip_x1[ok] <- resolved$clip_x1
  leaves_df$clip_y1[ok] <- resolved$clip_y1
  leaves_df
}

extract_rotation_deg <- function(tr_vec) {
  out <- rep(NA_real_, length(tr_vec))
  has_rot <- !is.na(tr_vec) & grepl("rotate\\(", tr_vec)
  if (any(has_rot)) {
    m <- regmatches(tr_vec[has_rot], regexec("rotate\\(\\s*([-+0-9.eE]+)", tr_vec[has_rot]))
    out[has_rot] <- vapply(
      m,
      function(v) if (length(v) >= 2L) suppressWarnings(as.numeric(v[[2L]])) else NA_real_,
      numeric(1L)
    )
  }
  out
}

parse_svg_elements <- function(doc) {
  ns <- svg_ns()
  nodes <- xml2::xml_find_all(doc, prim_xpath(), ns)
  n <- length(nodes)
  if (n == 0L) {
    return(empty_elements_df())
  }

  tag <- xml2::xml_name(nodes)
  owner_nodes <- xml2::xml_find_first(nodes, "ancestor::d1:g[@data-gloss-leaf][1]", ns)
  owner <- xml2::xml_attr(owner_nodes, "data-gloss-leaf")
  style <- xml2::xml_attr(nodes, "style")
  style[is.na(style)] <- ""

  box <- compute_element_boxes(nodes, tag, style)
  fill_val <- svg_attr_or_style(nodes, style, "fill")
  stroke_val <- svg_attr_or_style(nodes, style, "stroke")
  stroke_width <- round_pt(suppressWarnings(as.numeric(sub("px$", "", svg_attr_or_style(nodes, style, "stroke-width")))))

  op_raw <- suppressWarnings(as.numeric(svg_attr_or_style(nodes, style, "opacity")))
  fop <- suppressWarnings(as.numeric(svg_attr_or_style(nodes, style, "fill-opacity")))
  sop <- suppressWarnings(as.numeric(svg_attr_or_style(nodes, style, "stroke-opacity")))
  sub_op <- rep(1.0, n)
  use_sop <- !is.na(sop) & (is.na(stroke_val) | stroke_val != "none")
  sub_op[use_sop] <- sop[use_sop]
  use_fop <- !is.na(fop) & (is.na(fill_val) | fill_val != "none")
  sub_op[use_fop] <- fop[use_fop]
  opacity <- round_pt(ifelse(is.na(op_raw), 1.0, op_raw) * sub_op)

  txt <- rep(NA_character_, n)
  font_size <- rep(NA_real_, n)
  font_family <- rep(NA_character_, n)
  text_anchor <- rep(NA_character_, n)
  rotation <- extract_rotation_deg(xml2::xml_attr(nodes, "transform"))

  is_text <- tag == "text"
  if (any(is_text)) {
    tnodes <- nodes[is_text]
    tstyle <- style[is_text]
    txt[is_text] <- xml2::xml_text(tnodes)

    fs <- suppressWarnings(as.numeric(sub("px$", "", svg_attr_or_style(tnodes, tstyle, "font-size"))))
    fs[is.na(fs)] <- 12.0
    font_size[is_text] <- round_pt(fs)

    ff <- svg_attr_or_style(tnodes, tstyle, "font-family")
    ff <- ifelse(is.na(ff), NA_character_, trimws(gsub("^['\"]+|['\"]+$", "", ff)))
    ff[!is.na(ff) & !nzchar(ff)] <- NA_character_
    font_family[is_text] <- ff

    ta <- svg_attr_or_style(tnodes, tstyle, "text-anchor")
    ta[is.na(ta) | !nzchar(ta)] <- "start"
    text_anchor[is_text] <- ta

    trot <- rotation[is_text]
    miss_rot <- is.na(trot)
    if (any(miss_rot)) {
      ptr <- xml2::xml_attr(xml2::xml_find_first(tnodes[miss_rot], "parent::*", ns), "transform")
      prot <- extract_rotation_deg(ptr)
      prot[is.na(prot)] <- 0.0
      trot[miss_rot] <- prot
    }
    rotation[is_text] <- round_pt(trot)
  }

  clip_info <- extract_clip_defs(doc, ns)
  clips <- resolve_node_clips(nodes, clip_info, ns)

  data.frame(
    element_id = paste0("E", sprintf("%04d", seq_len(n))),
    leaf_id = owner,
    ordinal = seq_within_group(owner),
    tag = tag,
    text = txt,
    bbox_x0 = round_pt(box$x0),
    bbox_y0 = round_pt(box$y0),
    bbox_x1 = round_pt(box$x1),
    bbox_y1 = round_pt(box$y1),
    fill = fill_val,
    stroke = stroke_val,
    stroke_width = stroke_width,
    opacity = opacity,
    font_size = font_size,
    font_family = font_family,
    text_anchor = text_anchor,
    rotation = rotation,
    clip_id = clips$clip_id,
    clip_x0 = clips$clip_x0,
    clip_y0 = clips$clip_y0,
    clip_x1 = clips$clip_x1,
    clip_y1 = clips$clip_y1,
    built_row_id = rep(NA_integer_, n),
    group_id = rep(NA_character_, n),
    part_role = rep(NA_character_, n),
    stringsAsFactors = FALSE
  )
}

# --- Dense-leaf PNG rasterization --------------------------------------------

keep_only_wrapped_leaf <- function(g, leaf_id, grobs) {
  if (inherits(g, "gloss_wrap")) {
    if (identical(g$id, leaf_id)) {
      return(grid::gTree(
        children = grid::gList(grobs[[leaf_id]]),
        vp = g$vp,
        name = g$name
      ))
    }
    return(grid::nullGrob(name = g$name))
  }
  if (inherits(g, "gTree") && length(g$children) > 0L) {
    nms <- names(g$children)
    kids <- lapply(nms, function(nm) keep_only_wrapped_leaf(g$children[[nm]], leaf_id, grobs))
    new_kids <- do.call(grid::gList, kids)
    names(new_kids) <- nms
    g$children <- new_kids
  }
  g
}

draw_grid_dl <- function(dl) {
  grid::grid.newpage()
  for (elt in dl) {
    if (!is.null(elt)) {
      grid::grid.draw(elt, recording = FALSE)
    }
  }
  invisible(NULL)
}

render_leaf_png <- function(draw_fn, width, height, dpi = 144) {
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)

  prev <- grDevices::dev.cur()
  on.exit({
    if (prev > 1L && prev %in% grDevices::dev.list()) {
      grDevices::dev.set(prev)
    }
  }, add = TRUE)

  grDevices::png(tmp, width = width, height = height, units = "in", res = dpi, bg = "transparent")
  dev_id <- grDevices::dev.cur()
  tryCatch(
    draw_fn(),
    finally = {
      if (dev_id %in% grDevices::dev.list()) {
        grDevices::dev.off(dev_id)
      }
    }
  )

  if (!file.exists(tmp) || file.info(tmp)$size <= 0) {
    return(NULL)
  }
  readBin(tmp, what = "raw", n = file.info(tmp)$size)
}

unwrap_gloss_wraps <- function(g, grobs) {
  if (inherits(g, "gloss_wrap")) {
    orig <- grobs[[g$id]]
    if (is.null(orig)) return(grid::nullGrob(name = g$name))
    orig$vp <- g$vp
    return(orig)
  }
  if (inherits(g, "gTree") && length(g$children) > 0L) {
    nms <- names(g$children)
    kids <- lapply(nms, function(nm) unwrap_gloss_wraps(g$children[[nm]], grobs))
    new_kids <- do.call(grid::gList, kids)
    names(new_kids) <- nms
    g$children <- new_kids
  }
  g
}

render_preview_png <- function(draw_fn, width, height, dpi = 144L) {
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp), add = TRUE)

  prev <- grDevices::dev.cur()
  on.exit({
    if (prev > 1L && prev %in% grDevices::dev.list()) {
      grDevices::dev.set(prev)
    }
  }, add = TRUE)

  grDevices::png(tmp, width = width, height = height, units = "in", res = dpi, bg = "white")
  dev_id <- grDevices::dev.cur()
  tryCatch(
    draw_fn(),
    finally = {
      if (dev_id %in% grDevices::dev.list()) {
        grDevices::dev.off(dev_id)
      }
    }
  )

  if (!file.exists(tmp) || file.info(tmp)$size <= 0) {
    return(NULL)
  }
  readBin(tmp, what = "raw", n = file.info(tmp)$size)
}

# Pair ggrepel / leader-line labels with their matching box & leader segment
extract_repel_label_links <- function(leaves, elements, lineage) {
  if (!is.data.frame(leaves) || nrow(leaves) == 0L ||
      !is.data.frame(elements) || nrow(elements) == 0L ||
      !is.data.frame(lineage) || nrow(lineage) == 0L) {
    return(list())
  }

  repel_lids <- leaves$leaf_id[
    grepl("repel", paste(leaves$grob_name, leaves$grob_path), ignore.case = TRUE)
  ]
  if (length(repel_lids) == 0L) {
    return(list())
  }

  lin_by_lid <- stats::setNames(seq_len(nrow(lineage)), lineage$leaf_id)
  # Group repel leaves by (panel_id, layer_id)
  keys <- vapply(repel_lids, function(lid) {
    li <- lin_by_lid[[lid]]
    if (is.na(li)) return("NA::NA")
    paste0(lineage$panel_id[[li]] %||% "NA", "::", lineage$layer_id[[li]] %||% "NA")
  }, character(1L))

  links <- list()
  for (gk in unique(keys)) {
    grp_lids <- repel_lids[keys == gk]
    sub_els <- elements[!is.na(elements$leaf_id) & elements$leaf_id %in% grp_lids, , drop = FALSE]
    if (nrow(sub_els) == 0L) next

    txts <- sub_els[sub_els$tag == "text", , drop = FALSE]
    segs <- sub_els[sub_els$tag %in% c("line", "polyline", "path"), , drop = FALSE]
    boxes <- sub_els[sub_els$tag %in% c("rect", "polygon"), , drop = FALSE]
    if (nrow(txts) == 0L || nrow(segs) == 0L) next

    used_seg <- logical(nrow(segs))
    used_box <- logical(nrow(boxes))

    point_to_box_dist <- function(px, py, b) {
      dx <- max(b$bbox_x0 - px, 0, px - b$bbox_x1)
      dy <- max(b$bbox_y0 - py, 0, py - b$bbox_y1)
      sqrt(dx^2 + dy^2)
    }

    for (ti in seq_len(nrow(txts))) {
      tr <- txts[ti, , drop = FALSE]
      t_cx <- 0.5 * (tr$bbox_x0 + tr$bbox_x1)
      t_cy <- 0.5 * (tr$bbox_y0 + tr$bbox_y1)

      # Optional enclosing label box (geom_label_repel)
      box_id <- NULL
      if (nrow(boxes) > 0L) {
        avail_b <- which(!used_box)
        if (length(avail_b) > 0L) {
          b_d <- vapply(avail_b, function(bi) {
            point_to_box_dist(t_cx, t_cy, boxes[bi, , drop = FALSE])
          }, numeric(1L))
          best_bi <- avail_b[[which.min(b_d)]]
          if (b_d[[which.min(b_d)]] <= 2.0) {
            box_id <- boxes$element_id[[best_bi]]
            used_box[[best_bi]] <- TRUE
          }
        }
      }

      # Match nearest leader line segment whose one endpoint touches the text/label box
      avail_s <- which(!used_seg)
      if (length(avail_s) == 0L) next
      ref_box <- if (!is.null(box_id)) boxes[boxes$element_id == box_id, , drop = FALSE] else tr

      best_dist <- Inf
      best_si <- NA_integer_
      best_anchor <- NULL
      for (si in avail_s) {
        sr <- segs[si, , drop = FALSE]
        # Candidate endpoints are opposite corners of the segment bbox
        ep1 <- c(sr$bbox_x0, sr$bbox_y0)
        ep2 <- c(sr$bbox_x1, sr$bbox_y1)
        ep3 <- c(sr$bbox_x0, sr$bbox_y1)
        ep4 <- c(sr$bbox_x1, sr$bbox_y0)
        d1 <- point_to_box_dist(ep1[[1L]], ep1[[2L]], ref_box)
        d2 <- point_to_box_dist(ep2[[1L]], ep2[[2L]], ref_box)
        d3 <- point_to_box_dist(ep3[[1L]], ep3[[2L]], ref_box)
        d4 <- point_to_box_dist(ep4[[1L]], ep4[[2L]], ref_box)
        d_pair1 <- min(d1, d2)
        d_pair2 <- min(d3, d4)
        dmin <- min(d_pair1, d_pair2)
        if (dmin < best_dist) {
          best_dist <- dmin
          best_si <- si
          if (d_pair1 <= d_pair2) {
            best_anchor <- if (d1 <= d2) ep2 else ep1
          } else {
            best_anchor <- if (d3 <= d4) ep4 else ep3
          }
        }
      }

      if (!is.na(best_si) && best_dist <= 12.0) {
        used_seg[[best_si]] <- TRUE
        entry <- list(
          label_element_id = tr$element_id[[1L]],
          leader_element_id = segs$element_id[[best_si]],
          anchor_pt = json_array(round_pt(best_anchor))
        )
        if (!is.null(box_id)) {
          entry$box_element_id <- box_id
        }
        if (!is.na(tr$built_row_id[[1L]])) {
          entry$built_row_id <- as.integer(tr$built_row_id[[1L]])
        }
        links[[length(links) + 1L]] <- entry
      }
    }
  }

  links
}

rasterize_dense_grid_leaves <- function(dl, grobs, leaf_ids, width, height, dpi = 144) {
  out <- list()
  for (lid in leaf_ids) {
    filtered_dl <- lapply(dl, function(elt) {
      if (inherits(elt, "grob")) keep_only_wrapped_leaf(elt, lid, grobs) else elt
    })
    png_bytes <- tryCatch(
      render_leaf_png(function() draw_grid_dl(filtered_dl), width = width, height = height, dpi = dpi),
      error = function(e) {
        cli::cli_warn("Could not rasterize dense leaf {.val {lid}}: {conditionMessage(e)}")
        NULL
      }
    )
    if (!is.null(png_bytes)) {
      out[[lid]] <- png_bytes
    }
  }
  out
}
