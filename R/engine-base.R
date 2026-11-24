# Built-in base graphics plotting engine (Imports: grDevices, graphics).
#
# Replays the recorded display list one entry at a time on an always-valid
# svglite file device so each drawing call is isolated into a deterministic
# <g id="L..."> leaf while capturing par("usr"), par("xlog"/"ylog"), and
# figure plot regions across single and multi-panel (par(mfrow)/layout) pages.

register_engine_base <- function() {
  gl_register_engine(
    name = "base",
    classes = c("function", "recordedplot"),
    capture_fn = engine_base_capture,
    packages = c("grDevices", "graphics"),
    description = "Base R graphics: display-list step replay, plot region domains, and extracted call tables",
    priority = -10L,
    page_kind = "base",
    overwrite = TRUE
  )
}

engine_base_capture <- function(x, ctx) {
  draw_method <- ctx$draw_method
  page_info <- ctx$page_info

  if (!isTRUE(ctx$already_drawn)) {
    draw_method <- ctx$draw_input(x)
    ctx$ensure_device()
    page_info <- ctx$detect_page()
  }

  rp <- page_info$rp %||% tryCatch(grDevices::recordPlot(), error = function(e) NULL)
  if (is.null(rp) || length(rp[[1L]]) == 0L) {
    cli::cli_abort("Could not record base graphics display list from the drawn page.")
  }

  # Finalize the initial svglite device to preserve the untouched original.svg
  close_capture_device(ctx$dev)
  all_orig_pages <- as.character(ctx$dev$read())
  n_orig_pages <- length(all_orig_pages)
  if (n_orig_pages == 0L) {
    cli::cli_abort("The base graphics input did not draw any page.")
  }
  sel_idx <- resolve_selected_page(ctx$page, n_orig_pages)
  original_svg <- all_orig_pages[[sel_idx]]

  replay <- replay_base_display_list(
    rp = rp,
    width = ctx$width,
    height = ctx$height,
    dense = ctx$dense
  )

  # Optional preview PNG rendered from the already-recorded snapshot (zero re-execution)
  preview_png <- NULL
  if (isTRUE(ctx$preview)) {
    preview_png <- tryCatch(
      render_preview_png(
        function() grDevices::replayPlot(rlang::duplicate(rp, shallow = FALSE)),
        width = ctx$width, height = ctx$height, dpi = ctx$preview_dpi
      ),
      error = function(e) NULL
    )
  }

  scene_payload <- list(
    original_svg = original_svg,
    scene_svg = replay$scene_svg,
    leaves = replay$leaves,
    elements = replay$elements,
    dense_leaves = replay$dense_leaves,
    rasters = replay$rasters,
    preview_png = preview_png,
    draw_method = draw_method %||% "base_replay",
    pages = as.integer(n_orig_pages),
    selected_page = as.integer(sel_idx)
  )

  list(
    scene = scene_payload,
    ir = replay$ir,
    tables = replay$tables,
    lineage = replay$lineage
  )
}

# --- Step-by-step base display-list replay -----------------------------------

raw_to_utf8 <- function(bytes) {
  if (length(bytes) == 0L) return("")
  txt <- rawToChar(bytes)
  Encoding(txt) <- "UTF-8"
  txt
}

base_prim_line_mask <- function(lines) {
  pat <- "^\\s*<(circle|rect|line|polyline|polygon|path|text|image)[ />]"
  n <- length(lines)
  if (n == 0L) return(logical())
  in_defs <- FALSE
  in_clip <- FALSE
  out <- logical(n)
  for (i in seq_len(n)) {
    ln <- lines[[i]]
    if (grepl("<defs[ >]", ln, perl = TRUE)) in_defs <- TRUE
    if (grepl("<clipPath[ >]", ln, perl = TRUE)) in_clip <- TRUE
    if (!in_defs && !in_clip) {
      out[[i]] <- grepl(pat, ln, perl = TRUE) &&
        !grepl("^\\s*<rect\\s+width=['\"]100%['\"]\\s+height=['\"]100%['\"]", ln, perl = TRUE)
    }
    if (grepl("</clipPath>", ln, fixed = TRUE)) in_clip <- FALSE
    if (grepl("</defs>", ln, fixed = TRUE)) in_defs <- FALSE
  }
  out
}

wrap_base_entry_chunk <- function(chunk, leaf_id, grob_name) {
  lines <- strsplit(chunk, "\n", fixed = TRUE)[[1L]]
  prim <- base_prim_line_mask(lines)
  n_prim <- sum(prim)
  if (n_prim == 0L) {
    return(list(text = chunk, n = 0L, lines = lines, prim = prim))
  }

  out <- character()
  in_group <- FALSE
  run_idx <- 0L
  safe_grob <- gsub("['\"<>]", "", grob_name)
  for (i in seq_along(lines)) {
    if (prim[[i]]) {
      if (!in_group) {
        run_idx <- run_idx + 1L
        # Emit XML id only on the first run so multi-clip entries never create duplicate SVG ids
        open_tag <- if (run_idx == 1L) {
          sprintf("<g id='%s' data-gloss-leaf='%s' data-grob-name='%s'>", leaf_id, leaf_id, safe_grob)
        } else {
          sprintf("<g data-gloss-leaf='%s' data-grob-name='%s'>", leaf_id, safe_grob)
        }
        out <- c(out, open_tag)
        in_group <- TRUE
      }
      out <- c(out, lines[[i]])
    } else {
      if (in_group) {
        out <- c(out, "</g>")
        in_group <- FALSE
      }
      out <- c(out, lines[[i]])
    }
  }
  if (in_group) {
    out <- c(out, "</g>")
  }
  trail <- if (endsWith(chunk, "\n")) "\n" else ""
  list(text = paste0(paste(out, collapse = "\n"), trail), n = as.integer(n_prim), lines = lines, prim = prim)
}

base_plot_region_state <- function(width, height) {
  tryCatch({
    x <- graphics::grconvertX(c(0, 1), from = "npc", to = "ndc") * width * PT_PER_IN
    y <- (1 - graphics::grconvertY(c(1, 0), from = "npc", to = "ndc")) * height * PT_PER_IN
    usr <- graphics::par("usr")
    xlog <- isTRUE(graphics::par("xlog"))
    ylog <- isTRUE(graphics::par("ylog"))
    list(
      bbox = c(x[[1L]], y[[1L]], x[[2L]], y[[2L]]),
      usr = as.double(usr),
      xlog = xlog,
      ylog = ylog
    )
  }, error = function(e) {
    list(
      bbox = rep(NA_real_, 4L),
      usr = rep(NA_real_, 4L),
      xlog = FALSE,
      ylog = FALSE
    )
  })
}

make_base_clip_tracker <- function(head_text) {
  st <- new.env(parent = emptyenv())
  st$geom <- list()
  st$current <- NULL
  st$pending <- NULL

  feed <- function(lines) {
    interesting <- lines[grep("<clipPath\\s+id=|^\\s*<rect\\s+x=|^\\s*<g\\s+clip-path=|^\\s*</g>\\s*$", lines, perl = TRUE)]
    for (ln in interesting) {
      tr <- trimws(ln)
      if (grepl("<clipPath\\s+id=", tr, perl = TRUE)) {
        st$pending <- sub("^.*<clipPath\\s+id=['\"]([^'\"]+)['\"].*$", "\\1", tr, perl = TRUE)
      } else if (grepl("^<g\\s+clip-path=", tr, perl = TRUE)) {
        cid <- sub("^<g\\s+clip-path=['\"]url\\(#([^)]+)\\)['\"].*$", "\\1", tr, perl = TRUE)
        st$current <- st$geom[[cid]]
      } else if (identical(tr, "</g>")) {
        st$current <- NULL
      } else if (!is.null(st$pending)) {
        nums <- as.numeric(regmatches(tr, gregexpr("-?[0-9.]+", tr))[[1L]])
        if (length(nums) >= 4L) {
          st$geom[[st$pending]] <- c(nums[[1L]], nums[[2L]], nums[[1L]] + nums[[3L]], nums[[2L]] + nums[[4L]])
        }
        st$pending <- NULL
      }
    }
    st$current
  }

  feed(strsplit(head_text, "\n", fixed = TRUE)[[1L]])
  list(feed = feed)
}

replay_base_display_list <- function(rp, width, height, dense = 10000) {
  dl <- as.list(rp[[1L]])
  n_dl <- length(dl)
  ops <- vapply(dl, dl_op_name, character(1L))

  svg_file <- tempfile(fileext = ".svg")
  on.exit(unlink(svg_file), add = TRUE)

  prev <- grDevices::dev.cur()
  on.exit({
    if (prev > 1L && prev %in% grDevices::dev.list()) {
      grDevices::dev.set(prev)
    }
  }, add = TRUE)

  svglite::svglite(svg_file, width = width, height = height, standalone = TRUE, always_valid = TRUE)
  dev_id <- grDevices::dev.cur()
  on.exit({
    if (dev_id %in% grDevices::dev.list()) grDevices::dev.off(dev_id)
  }, add = TRUE)

  read_slice <- function(from, len) {
    if (len <= 0L) return(raw(0L))
    con <- file(svg_file, open = "rb")
    on.exit(close(con), add = TRUE)
    seek(con, from)
    readBin(con, what = "raw", n = len)
  }

  # Replay the empty recorded stub (sets element 1 to NULL pairlist, preserving
  # recorded graphics state without triggering C_playSnapshot VECSXP mismatch)
  grDevices::dev.control("enable")
  stub <- rp
  stub[1L] <- list(NULL)
  grDevices::replayPlot(stub)

  cursor <- new.env(parent = emptyenv())
  cursor$pos <- 0L
  read_incremental <- function() {
    sz <- file.info(svg_file)$size
    if (is.na(sz) || sz <= cursor$pos) return("")
    bytes <- read_slice(cursor$pos, sz - cursor$pos)
    txt <- raw_to_utf8(bytes)
    closing <- regmatches(txt, regexpr("(\\s*</g>)*\\s*</svg>\\s*$", txt, perl = TRUE))
    keep <- length(bytes) - if (length(closing) > 0L) nchar(closing, type = "bytes") else 0L
    cursor$pos <- cursor$pos + keep
    if (keep <= 0L) "" else raw_to_utf8(bytes[seq_len(keep)])
  }

  head_text <- read_incremental()
  chunks <- character(n_dl)
  regions <- vector("list", n_dl)

  for (k in seq_len(n_dl)) {
    entry <- dl[[k]]
    tryCatch(
      do.call(entry[[1L]], as.list(entry[[2L]]), quote = TRUE),
      error = function(e) {
        cli::cli_warn("Base display-list entry {k} ({ops[[k]]}) replay warning: {conditionMessage(e)}")
      }
    )
    chunks[[k]] <- read_incremental()
    regions[[k]] <- base_plot_region_state(width, height)
  }

  grDevices::dev.off(dev_id)
  tail_sz <- file.info(svg_file)$size - cursor$pos
  tail_text <- if (!is.na(tail_sz) && tail_sz > 0L) raw_to_utf8(read_slice(cursor$pos, tail_sz)) else "</g>\n</svg>\n"

  clip_trk <- make_base_clip_tracker(head_text)
  wrapped_chunks <- chunks
  fig_idx <- pmax(1L, cumsum(ops == "C_plot_new"))

  leaf_rows <- list()
  leaf_dl_idx <- stats::setNames(integer(), character())
  drew_mask <- logical(n_dl)
  k_leaf <- 0L

  for (k in seq_len(n_dl)) {
    op_clean <- sub("^C_", "", ops[[k]])
    lines <- strsplit(chunks[[k]], "\n", fixed = TRUE)[[1L]]
    prim <- base_prim_line_mask(lines)
    if (any(prim)) {
      first_p <- which(prim)[[1L]]
      active_clip <- if (first_p > 1L) clip_trk$feed(lines[seq_len(first_p - 1L)]) else clip_trk$feed(character())
      clip_trk$feed(lines[first_p:length(lines)])

      reg <- regions[[k]]
      is_margin_op <- op_clean %in% c("axis", "title", "mtext", "box")
      is_data_op <- op_clean %in% c("plotXY", "rect", "polygon", "path", "segments", "arrows", "abline", "symbols", "raster")
      clip_matches_plot <- !is.null(active_clip) && !anyNA(reg$bbox) &&
        all(abs(active_clip - reg$bbox) < 0.05)
      # Functions such as barplot() draw bars with xpd = TRUE (figure-wide clip)
      in_plot <- !is_margin_op && (
        clip_matches_plot || (is_data_op && !anyNA(reg$bbox) && !anyNA(reg$usr))
      )

      k_leaf <- k_leaf + 1L
      lid <- sprintf("L%03d", k_leaf)
      w <- wrap_base_entry_chunk(chunks[[k]], lid, op_clean)
      wrapped_chunks[[k]] <- w$text
      drew_mask[[k]] <- TRUE
      leaf_dl_idx[[lid]] <- k

      vp_str <- if (in_plot) sprintf("figure-%d::plot", fig_idx[[k]]) else sprintf("figure-%d", fig_idx[[k]])
      slot_str <- if (in_plot) sprintf("panel-%d", fig_idx[[k]]) else sprintf("figure-%d", fig_idx[[k]])

      leaf_rows[[k_leaf]] <- list(
        leaf_id = lid,
        grob_name = op_clean,
        grob_path = sprintf("base/%d/%s", k, op_clean),
        grob_class = op_clean,
        vp_path = vp_str,
        layout_slot = slot_str,
        bbox = reg$bbox,
        usr = reg$usr,
        xlog = reg$xlog,
        ylog = reg$ylog,
        fig = fig_idx[[k]],
        in_plot = in_plot,
        dl_idx = k
      )
    } else {
      clip_trk$feed(lines)
    }
  }

  scene_svg_raw <- paste0(head_text, paste(wrapped_chunks, collapse = ""), tail_text)
  scene_doc <- tryCatch(read_svg_doc(scene_svg_raw), error = function(e) {
    cli::cli_warn("Base wrapped SVG was not well-formed; falling back to unwrapped replay.")
    NULL
  })

  if (is.null(scene_doc)) {
    plain_svg <- paste0(head_text, paste(chunks, collapse = ""), tail_text)
    scene_doc <- read_svg_doc(plain_svg)
  }

  elements_df <- parse_svg_elements(scene_doc)

  leaves_df <- if (length(leaf_rows) == 0L) {
    empty_leaves_df()
  } else {
    data.frame(
      leaf_id = vapply(leaf_rows, `[[`, character(1L), "leaf_id"),
      grob_name = vapply(leaf_rows, `[[`, character(1L), "grob_name"),
      grob_path = vapply(leaf_rows, `[[`, character(1L), "grob_path"),
      grob_class = vapply(leaf_rows, `[[`, character(1L), "grob_class"),
      vp_path = vapply(leaf_rows, `[[`, character(1L), "vp_path"),
      layout_slot = vapply(leaf_rows, `[[`, character(1L), "layout_slot"),
      bbox_x0 = round_pt(vapply(leaf_rows, function(r) r$bbox[[1L]], numeric(1L))),
      bbox_y0 = round_pt(vapply(leaf_rows, function(r) r$bbox[[2L]], numeric(1L))),
      bbox_x1 = round_pt(vapply(leaf_rows, function(r) r$bbox[[3L]], numeric(1L))),
      bbox_y1 = round_pt(vapply(leaf_rows, function(r) r$bbox[[4L]], numeric(1L))),
      xscale0 = vapply(leaf_rows, function(r) r$usr[[1L]], numeric(1L)),
      xscale1 = vapply(leaf_rows, function(r) r$usr[[2L]], numeric(1L)),
      yscale0 = vapply(leaf_rows, function(r) r$usr[[3L]], numeric(1L)),
      yscale1 = vapply(leaf_rows, function(r) r$usr[[4L]], numeric(1L)),
      n_elements = integer(length(leaf_rows)),
      dense = rep(FALSE, length(leaf_rows)),
      clip_id = rep(NA_character_, length(leaf_rows)),
      clip_x0 = rep(NA_real_, length(leaf_rows)),
      clip_y0 = rep(NA_real_, length(leaf_rows)),
      clip_x1 = rep(NA_real_, length(leaf_rows)),
      clip_y1 = rep(NA_real_, length(leaf_rows)),
      z_index = seq_len(length(leaf_rows)),
      semantic_role = rep(NA_character_, length(leaf_rows)),
      edit_policy = rep(NA_character_, length(leaf_rows)),
      stringsAsFactors = FALSE
    )
  }

  leaves_df <- attach_leaf_clips(leaves_df, scene_doc)

  if (nrow(leaves_df) > 0L) {
    counts <- table(factor(elements_df$leaf_id, levels = leaves_df$leaf_id))
    leaves_df$n_elements <- as.integer(counts[leaves_df$leaf_id])
  }

  # Dense leaf rasterization for base pages
  dense_ids <- character()
  rasters <- list()
  if (is.finite(dense) && nrow(leaves_df) > 0L) {
    text_leaves <- unique(elements_df$leaf_id[!is.na(elements_df$leaf_id) & elements_df$tag == "text"])
    cand_dense <- leaves_df$leaf_id[
      leaves_df$n_elements >= dense & !(leaves_df$leaf_id %in% text_leaves)
    ]
    if (length(cand_dense) > 0L) {
      ns <- svg_ns()
      w_pt <- round_pt(width * PT_PER_IN)
      h_pt <- round_pt(height * PT_PER_IN)
      for (lid in cand_dense) {
        target_k <- leaf_dl_idx[[lid]]
        png_bytes <- tryCatch(
          render_leaf_png(
            function() {
              grDevices::replayPlot(stub)
              graphics::par(bg = "transparent")
              for (j in seq_len(n_dl)) {
                if (j == target_k || !drew_mask[[j]]) {
                  do.call(dl[[j]][[1L]], as.list(dl[[j]][[2L]]), quote = TRUE)
                }
              }
            },
            width = width, height = height
          ),
          error = function(e) NULL
        )
        if (!is.null(png_bytes)) {
          rasters[[lid]] <- png_bytes
          gnode <- xml2::xml_find_first(scene_doc, sprintf("//d1:g[@data-gloss-leaf='%s']", lid), ns)
          if (!inherits(gnode, "xml_missing")) {
            xml2::xml_remove(xml2::xml_children(gnode))
            xml2::xml_set_attr(gnode, "data-gloss-raster", "true")
            xml2::xml_add_child(
              gnode, "image",
              x = "0", y = "0",
              width = sprintf("%.2f", w_pt),
              height = sprintf("%.2f", h_pt),
              preserveAspectRatio = "none",
              href = paste0("rasters/", lid, ".png")
            )
          }
        }
      }
      dense_ids <- names(rasters)
      leaves_df$dense <- leaves_df$leaf_id %in% dense_ids
    }
  }

  # Build panels, extracted data tables, layers, element bridges, and neutral lineage
  ir_res <- base_extract_ir_and_lineage(dl, leaf_rows, leaves_df, elements_df)

  list(
    scene_svg = as.character(scene_doc),
    leaves = leaves_df,
    elements = ir_res$elements,
    dense_leaves = dense_ids,
    rasters = rasters,
    ir = ir_res$ir,
    tables = ir_res$tables,
    lineage = ir_res$lineage
  )
}

base_extract_call_table <- function(entry, op_name) {
  a <- tryCatch(as.list(entry[[2L]]), error = function(e) list())
  if (length(a) < 2L) return(NULL)

  if (identical(op_name, "plotXY")) {
    xy <- a[[2L]]
    if (is.list(xy) && is.numeric(xy$x) && is.numeric(xy$y) && length(xy$x) == length(xy$y) && length(xy$x) > 0L) {
      plot_type <- as.character(a[[3L]] %||% "p")[[1L]]
      geom_name <- switch(
        plot_type,
        l = , s = , S = "BaseLine",
        b = , o = "BasePointLine",
        h = "BaseHistogram",
        p = "BasePoints",
        "BasePlotXY"
      )
      return(list(
        data = data.frame(x = as.numeric(xy$x), y = as.numeric(xy$y), stringsAsFactors = FALSE),
        geom = geom_name,
        part_role = if (geom_name == "BaseLine") "line" else "point"
      ))
    }
  }
  if (identical(op_name, "rect") && length(a) >= 5L) {
    if (is.numeric(a[[2L]]) && is.numeric(a[[3L]]) && is.numeric(a[[4L]]) && is.numeric(a[[5L]])) {
      n <- max(lengths(a[2:5]))
      if (n > 0L) {
        return(list(
          data = data.frame(
            xleft = rep_len(as.numeric(a[[2L]]), n),
            ybottom = rep_len(as.numeric(a[[3L]]), n),
            xright = rep_len(as.numeric(a[[4L]]), n),
            ytop = rep_len(as.numeric(a[[5L]]), n),
            stringsAsFactors = FALSE
          ),
          geom = "BaseRect",
          part_role = "rect"
        ))
      }
    }
  }
  if (identical(op_name, "polygon") && length(a) >= 3L) {
    if (is.numeric(a[[2L]]) && is.numeric(a[[3L]]) && length(a[[2L]]) == length(a[[3L]]) && length(a[[2L]]) > 0L) {
      return(list(
        data = data.frame(x = as.numeric(a[[2L]]), y = as.numeric(a[[3L]]), stringsAsFactors = FALSE),
        geom = "BasePolygon",
        part_role = "polygon"
      ))
    }
  }
  # ISS-BASE-01: Extended primitive call-table extractors (segments, arrows, symbols, abline, xspline, text)
  if (op_name %in% c("segments", "arrows") && length(a) >= 5L) {
    if (is.numeric(a[[2L]]) && is.numeric(a[[3L]]) && is.numeric(a[[4L]]) && is.numeric(a[[5L]])) {
      n <- max(lengths(a[2:5]))
      if (n > 0L) {
        return(list(
          data = data.frame(
            x0 = rep_len(as.numeric(a[[2L]]), n),
            y0 = rep_len(as.numeric(a[[3L]]), n),
            x1 = rep_len(as.numeric(a[[4L]]), n),
            y1 = rep_len(as.numeric(a[[5L]]), n),
            stringsAsFactors = FALSE
          ),
          geom = if (identical(op_name, "arrows")) "BaseArrows" else "BaseSegments",
          part_role = "segment"
        ))
      }
    }
  }
  if (identical(op_name, "abline") && length(a) >= 5L) {
    # C_abline(a, b, h, v, untf, ...)
    a_val <- a[[2L]]
    b_val <- a[[3L]]
    h_val <- a[[4L]]
    v_val <- a[[5L]]
    rows <- list()
    if (is.numeric(a_val) && is.numeric(b_val) && length(a_val) > 0L && length(b_val) > 0L) {
      n <- max(length(a_val), length(b_val))
      rows[[length(rows) + 1L]] <- data.frame(
        kind = rep("slope_intercept", n),
        intercept = rep_len(as.numeric(a_val), n),
        slope = rep_len(as.numeric(b_val), n),
        h = rep(NA_real_, n),
        v = rep(NA_real_, n),
        stringsAsFactors = FALSE
      )
    }
    if (is.numeric(h_val) && length(h_val) > 0L) {
      n <- length(h_val)
      rows[[length(rows) + 1L]] <- data.frame(
        kind = rep("horizontal", n),
        intercept = rep(NA_real_, n),
        slope = rep(NA_real_, n),
        h = as.numeric(h_val),
        v = rep(NA_real_, n),
        stringsAsFactors = FALSE
      )
    }
    if (is.numeric(v_val) && length(v_val) > 0L) {
      n <- length(v_val)
      rows[[length(rows) + 1L]] <- data.frame(
        kind = rep("vertical", n),
        intercept = rep(NA_real_, n),
        slope = rep(NA_real_, n),
        h = rep(NA_real_, n),
        v = as.numeric(v_val),
        stringsAsFactors = FALSE
      )
    }
    if (length(rows) > 0L) {
      return(list(
        data = do.call(rbind, rows),
        geom = "BaseAbline",
        part_role = "reference"
      ))
    }
  }
  if (identical(op_name, "symbols") && length(a) >= 4L) {
    if (is.numeric(a[[2L]]) && is.numeric(a[[3L]]) && length(a[[2L]]) == length(a[[3L]]) && length(a[[2L]]) > 0L) {
      sz <- if (is.numeric(a[[5L]])) as.numeric(a[[5L]]) else rep(NA_real_, length(a[[2L]]))
      return(list(
        data = data.frame(
          x = as.numeric(a[[2L]]),
          y = as.numeric(a[[3L]]),
          size = rep_len(sz, length(a[[2L]])),
          stringsAsFactors = FALSE
        ),
        geom = "BaseSymbols",
        part_role = "symbol"
      ))
    }
  }
  if (identical(op_name, "xspline") && length(a) >= 3L) {
    if (is.numeric(a[[2L]]) && is.numeric(a[[3L]]) && length(a[[2L]]) == length(a[[3L]]) && length(a[[2L]]) > 0L) {
      return(list(
        data = data.frame(x = as.numeric(a[[2L]]), y = as.numeric(a[[3L]]), stringsAsFactors = FALSE),
        geom = "BaseXspline",
        part_role = "line"
      ))
    }
  }
  if (identical(op_name, "text") && length(a) >= 3L) {
    xy <- a[[2L]]
    lbls <- a[[3L]]
    if (is.list(xy) && is.numeric(xy$x) && is.numeric(xy$y) && length(xy$x) > 0L && !is.null(lbls)) {
      n <- max(length(xy$x), length(xy$y), length(lbls))
      return(list(
        data = data.frame(
          x = rep_len(as.numeric(xy$x), n),
          y = rep_len(as.numeric(xy$y), n),
          label = rep_len(as.character(lbls), n),
          stringsAsFactors = FALSE
        ),
        geom = "BaseText",
        part_role = "label"
      ))
    }
  }
  NULL
}

base_extract_ir_and_lineage <- function(dl, leaf_rows, leaves_df, elements_df = empty_elements_df()) {
  elements_df <- ensure_df_columns(elements_df, empty_elements_df())
  n <- nrow(leaves_df)
  if (n == 0L) {
    return(list(
      ir = list(panels = list(), layers = list(), scales = list(), orders = stats::setNames(list(), character())),
      tables = stats::setNames(list(), character()),
      lineage = empty_lineage_df(),
      elements = elements_df
    ))
  }

  panels <- list()
  fig_to_panel <- stats::setNames(character(), character())
  layers <- list()
  tables <- stats::setNames(list(), character())

  panel_ids <- rep(NA_character_, n)
  layer_ids <- rep(NA_integer_, n)
  table_ids <- rep(NA_character_, n)
  cardinalities <- rep("unlinked", n)
  n_rows_vec <- rep(NA_integer_, n)

  for (r in seq_len(n)) {
    lr <- leaf_rows[[r]]
    fkey <- as.character(lr$fig)
    if (isTRUE(lr$in_plot)) {
      if (!(fkey %in% names(fig_to_panel))) {
        pid <- sprintf("P%d", length(panels) + 1L)
        fig_to_panel[[fkey]] <- pid
        # ISS-ASSET-02: Unify x_domain/y_domain with ggplot as linear post-transform
        # rendering coordinates (par("usr")), while x_data_domain/y_data_domain store
        # raw inverse-transformed units (10^usr when xlog/ylog is TRUE).
        panels[[length(panels) + 1L]] <- make_panel_ir(
          panel_id = pid,
          facet_vars = list(figure = as.integer(lr$fig)),
          bbox_pt = lr$bbox,
          x_domain = lr$usr[1:2],
          y_domain = lr$usr[3:4],
          coord = "BaseGraphics",
          flipped = FALSE,
          x_trans = if (isTRUE(lr$xlog)) "log-10" else "identity",
          y_trans = if (isTRUE(lr$ylog)) "log-10" else "identity",
          domain_space = "transformed",
          expansion_included = TRUE
        )
      }
      panel_ids[[r]] <- fig_to_panel[[fkey]]

      extracted <- base_extract_call_table(dl[[lr$dl_idx]], lr$grob_name)
      if (!is.null(extracted)) {
        li <- length(layers) + 1L
        tid <- sprintf("built_layer%d", li)
        tables[[tid]] <- list(
          table_id = tid,
          role = "built",
          key = character(),
          layer_id = li,
          data = extracted$data
        )
        layers[[li]] <- make_layer_ir(
          layer_id = li,
          geom = extracted$geom,
          stat = "StatIdentity",
          position = "PositionIdentity",
          aes = list(x = "x", y = "y"),
          raw_table = NULL,
          built_table = tid
        )
        layer_ids[[r]] <- li
        table_ids[[r]] <- tid
        nr <- as.integer(nrow(extracted$data))
        n_rows_vec[[r]] <- nr
        cardinalities[[r]] <- infer_lineage_cardinality(
          geom = if (extracted$geom %in% c("BaseLine", "BasePolygon", "BaseXspline")) "GeomLine" else "GeomPoint",
          stat = "StatIdentity",
          n_rows = nr,
          n_elements = leaves_df$n_elements[[r]]
        )

        el_idx <- which(!is.na(elements_df$leaf_id) & elements_df$leaf_id == leaves_df$leaf_id[[r]])
        if (length(el_idx) > 0L) {
          elements_df$part_role[el_idx] <- extracted$part_role %||% "mark"
          if (identical(cardinalities[[r]], "1:1") && length(el_idx) == nr) {
            elements_df$built_row_id[el_idx] <- seq_len(nr)
          }
        }
      }
    }
  }

  lineage <- make_lineage_df(
    leaves = leaves_df,
    panel_id = panel_ids,
    layer_id = layer_ids,
    table_id = table_ids,
    cardinality = cardinalities,
    n_rows = n_rows_vec
  )

  list(
    ir = list(
      panels = panels,
      layers = layers,
      scales = list(),
      orders = stats::setNames(list(), character())
    ),
    tables = tables,
    lineage = lineage,
    elements = elements_df
  )
}
