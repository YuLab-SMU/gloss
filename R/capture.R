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
    ...) {

  size <- resolve_figure_size(width, height)
  if (!is.numeric(dense) || length(dense) != 1L || is.na(dense) || dense <= 0) {
    cli::cli_abort("{.arg dense} must be a single positive number (or {.code Inf}).")
  }

  candidates <- resolve_engine_candidates(x, engine = engine, error = TRUE)

  prev_dev <- grDevices::dev.cur()
  on.exit({
    if (prev_dev > 1L && prev_dev %in% grDevices::dev.list()) {
      grDevices::dev.set(prev_dev)
    }
  }, add = TRUE)

  dev <- open_capture_device(size$width, size$height)
  on.exit(close_capture_device(dev), add = TRUE)

  cand_kinds <- unique(vapply(candidates, function(s) s$page_kind, character(1L)))
  already_drawn <- FALSE
  draw_method <- NULL
  page_info <- NULL

  if (length(candidates) == 1L || length(cand_kinds) == 1L) {
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
      selected <- resolve_engine(x, engine = engine, page_kind = "mixed", error = FALSE)
      if (is.null(selected)) {
        cli::cli_abort(c(
          "The input mixed base graphics and grid graphics on the same page.",
          i = "Capture base and grid plots separately, or register a custom engine with {.code page_kind = \"any\"}."
        ))
      }
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
    page_info = page_info
  )

  result <- selected$capture_fn(x, ctx, ...)

  if (is_gloss_capture(result)) {
    return(result)
  }

  assemble_capture_result(result, ctx = ctx, sources = sources, input_obj = x)
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
    page_info = NULL) {

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

  ctx$ensure_device <- function() ensure_device_active(dev)
  ctx$detect_page <- function() detect_page_kind()
  ctx$draw_input <- function(obj) draw_input_object(obj)
  ctx$capture_grid <- function(draw_method = NULL) {
    capture_current_grid_page(
      dev = dev,
      width = width,
      height = height,
      dense = dense,
      draw_method = draw_method %||% ctx$draw_method %||% "grid.draw"
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

  page <- list(
    engine = result$page$engine %||% ctx$engine$name,
    engine_version = result$page$engine_version %||% engine_version_string(ctx$engine),
    draw_method = result$page$draw_method %||% sc$draw_method %||% ctx$draw_method %||% "unknown",
    device = result$page$device %||% device_str,
    width_in = result$page$width_in %||% ctx$width,
    height_in = result$page$height_in %||% ctx$height,
    width_pt = result$page$width_pt %||% round_pt(ctx$width * PT_PER_IN),
    height_pt = result$page$height_pt %||% round_pt(ctx$height * PT_PER_IN),
    pages = result$page$pages %||% sc$pages %||% 1L
  )

  sess_info <- result$session %||% collect_session_info(input_obj = input_obj)
  src_list <- result$sources %||% collect_sources_inventory(sources = sources, session = sess_info)

  new_gloss_capture(
    page = page,
    svg_original = sc$original_svg,
    svg_scene = sc$scene_svg,
    leaves = sc$leaves %||% empty_leaves_df(),
    elements = sc$elements %||% empty_elements_df(),
    dense_leaves = sc$dense_leaves %||% character(),
    rasters = sc$rasters %||% list(),
    ir = result$ir %||% list(),
    tables = result$tables %||% list(),
    lineage = result$lineage %||% empty_lineage_df(),
    sources = src_list,
    session = sess_info
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

capture_current_grid_page <- function(dev, width, height, dense = 10000, draw_method = "grid.draw") {
  ensure_device_active(dev)
  pages_before <- as.character(dev$read())
  n_orig_pages <- length(pages_before)
  if (n_orig_pages == 0L) {
    cli::cli_abort("The input did not draw any page on the graphics device.")
  }
  if (n_orig_pages > 1L) {
    cli::cli_warn("The input drew {n_orig_pages} pages; gloss captured the last page.")
  }

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
  original_svg <- all_pages[[n_orig_pages]]
  wrapped_svg <- all_pages[[length(all_pages)]]

  scene_doc <- inline_svg_groups(
    wrapped_svg,
    order = rec$order,
    leaves_meta = acc$leaves,
    fallback_svg = original_svg
  )
  svg_h_pt <- extract_svg_height_pt(wrapped_svg, fallback = height * PT_PER_IN)

  leaves_df <- build_leaves_df(acc$leaves, rec$probes, svg_height_pt = svg_h_pt)
  elements_df <- parse_svg_elements(scene_doc)

  if (nrow(leaves_df) > 0L) {
    counts <- table(factor(elements_df$leaf_id, levels = leaves_df$leaf_id))
    leaves_df$n_elements <- as.integer(counts[leaves_df$leaf_id])
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
    draw_method = draw_method,
    pages = as.integer(n_orig_pages)
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
  top_groups <- xml2::xml_find_all(
    doc,
    "//d1:defs[not(ancestor::d1:defs)]/d1:g[starts-with(@id, 'group-')]",
    ns
  )
  top_gids <- xml2::xml_attr(top_groups, "id")
  top_uses <- xml2::xml_find_all(doc, "//d1:use[not(ancestor::d1:defs)]", ns)
  top_hrefs <- extract_use_hrefs(top_uses)
  use_of <- match(top_gids, top_hrefs)

  if (length(top_gids) != n_probe || anyNA(use_of)) {
    cli::cli_warn(
      "Could not align {n_probe} draw-time probe{?s} with {length(top_gids)} top-level SVG group{?s}; falling back to untouched SVG without leaf misattribution."
    )
    return(if (!is.null(fallback_svg)) read_svg_doc(fallback_svg) else doc)
  }

  for (k in seq_len(n_probe)) {
    lid <- order[[k]]
    gnode <- top_groups[[k]]
    xml2::xml_replace(top_uses[[use_of[[k]]]], gnode, .copy = FALSE)
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
    slot_pos <- layout_idx[[length(layout_idx)]] + 1L
    if (slot_pos <= length(segs)) {
      return(sub("\\.[0-9]+-[0-9]+-[0-9]+-[0-9]+$", "", segs[[slot_pos]]))
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
    n_elements = integer(length(ids)),
    dense = rep(FALSE, length(ids)),
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

# Command-aware SVG path `d` bounding-box parser handling M/m, L/l, H/h, V/v,
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
      cx <- if (rel) cx + v[[6L]] else v[[6L]]
      cy <- if (rel) cy + v[[7L]] else v[[7L]]
      xs <- c(xs, cx)
      ys <- c(ys, cy)
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

estimate_text_boxes <- function(nodes, style) {
  fs <- suppressWarnings(as.numeric(sub("px$", "", svg_attr_or_style(nodes, style, "font-size"))))
  fs[is.na(fs)] <- 12.0
  w <- num_svg_attr(nodes, "textLength")
  txt <- xml2::xml_text(nodes)
  w[is.na(w)] <- 0.6 * fs[is.na(w)] * nchar(txt[is.na(w)])
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

  list(x0 = box[, 1L], x1 = box[, 2L], y0 = box[, 3L], y1 = box[, 4L])
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
  txt <- rep(NA_character_, n)
  is_text <- tag == "text"
  if (any(is_text)) {
    txt[is_text] <- xml2::xml_text(nodes[is_text])
  }

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
    fill = svg_attr_or_style(nodes, style, "fill"),
    stroke = svg_attr_or_style(nodes, style, "stroke"),
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
