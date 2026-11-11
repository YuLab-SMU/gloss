# Label sheets and label keys (M1 plan 2026-11-11-m1-roles-and-binding, Task 1).
# Pure functions of a captured substrate; they run nothing a figure wrote.
# Sourced by label-sheet.R and score-labels.R.

# A leaf's key survives renumbering. Grid's grob and viewport counters
# (`GRID.text.6`, `geom_point.points.3`, `GRID.VP.1`) and base display-list
# indices (`base/4/plotXY`) change with anything drawn before; the key drops
# them and keeps every other part of the viewport path and the grob path.
# Leaves with the same key are told apart by their order (`occurrence`).
norm_segments <- function(x, sep) {
  vapply(strsplit(ifelse(is.na(x), "", x), sep, fixed = TRUE), function(s) {
    s <- sub("\\.[0-9]+$", "", s)
    s[grepl("^[0-9]+$", s)] <- "#"
    paste(s, collapse = sep)
  }, "")
}
leaf_key <- function(path, vp) paste(norm_segments(vp, "::"), norm_segments(path, "/"), sep = " | ")
key_occurrence <- function(key) stats::ave(seq_along(key), key, FUN = seq_along)

# One row per leaf, in drawing order: what an annotator needs to find it on
# the page (the box of its elements, its first text, colours) and the empty
# columns they fill. `elements` is "all"; a leaf whose elements need more than
# one label is copied into one row per range ("1-4", "5-9").
sheet_table <- function(sub, id) {
  l <- sub$leaves
  e <- sub$elements[!is.na(sub$elements$leaf), , drop = FALSE]
  by <- function(v, f, empty) {
    r <- vapply(l$id, function(i) { x <- v[e$leaf == i]; if (length(x)) f(x) else empty }, empty)
    unname(r)
  }
  first <- function(x) { x <- x[!is.na(x) & x != "none" & nzchar(x)]; if (length(x)) x[1] else "" }
  key <- leaf_key(l$path, l$vp)
  data.frame(
    figure = id, k = seq_len(nrow(l)), leaf = l$id, key = key, occurrence = key_occurrence(key),
    class = l$class, n_elements = by(e$leaf, length, 0L),
    tags = by(e$tag, function(t) paste(sort(unique(t)), collapse = "+"), ""),
    x0 = round(by(e$x0, min, NA_real_), 1), y0 = round(by(e$y0, min, NA_real_), 1),
    x1 = round(by(e$x1, max, NA_real_), 1), y1 = round(by(e$y1, max, NA_real_), 1),
    text = substr(gsub("[\r\n\t]+", " ", by(e$text, first, "")), 1L, 60L),
    fill = by(e$fill, first, ""), stroke = by(e$stroke, first, ""),
    path = l$path, elements = "all", role = "", kind = "", note = "",
    stringsAsFactors = FALSE)
}

# The page with every leaf's box outlined and numbered by `k`. Numbers are
# placed greedily so that leaves sharing a box (a panel's grid lines) do not
# print over each other. The sheet shows the capture only, no rule output.
sheet_svg <- function(scene, tab) {
  pal <- c("#D7263D", "#1B998B", "#2E86AB", "#F46036", "#7B2D8E", "#C5A000")
  boxes <- tab[tab$n_elements > 0 & !is.na(tab$x0), , drop = FALSE]
  placed <- matrix(numeric(), 0, 4)
  hits <- function(r) any(placed[, 1] < r[3] & placed[, 3] > r[1] & placed[, 2] < r[4] & placed[, 4] > r[2])
  out <- character()
  for (i in seq_len(nrow(boxes))) {
    b <- boxes[i, ]
    col <- pal[(b$k - 1L) %% length(pal) + 1L]
    w <- max(b$x1 - b$x0, 0.6); h <- max(b$y1 - b$y0, 0.6)
    out <- c(out, sprintf('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" style="fill: none; stroke: %s; stroke-width: 0.5; stroke-dasharray: 1.5 1;"/>',
                          b$x0 - 0.3, b$y0 - 0.3, w + 0.6, h + 0.6, col))
    lab <- as.character(b$k)
    lw <- 2.9 * nchar(lab) + 1.2; lh <- 5.2
    x <- b$x0; y <- b$y0 - lh
    if (y < 0) y <- b$y0
    for (try in seq_len(60)) {
      r <- c(x, y, x + lw, y + lh)
      if (!hits(r)) break
      x <- x + lw
      if (x + lw > b$x0 + max(w, 40)) { x <- b$x0; y <- y + lh }
    }
    placed <- rbind(placed, r)
    out <- c(out, sprintf('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" style="fill: #FFFFFF; fill-opacity: 0.85; stroke: %s; stroke-width: 0.3;"/>',
                          r[1], r[2], lw, lh, col),
             sprintf('<text x="%.2f" y="%.2f" style="font-size: 4.6px; font-family: Helvetica, Arial, sans-serif; fill: %s;">%s</text>',
                     r[1] + 0.6, r[2] + 4.2, col, lab))
  }
  overlay <- paste0('<g data-gloss-sheet="overlay">\n', paste(out, collapse = "\n"), "\n</g>\n")
  sub("</svg>\\s*$", paste0(overlay, "</svg>\n"), scene)
}

# One row per element of a leaf, numbered within its leaf in drawing order:
# the indices a split label's `elements` ranges refer to.
sheet_elements <- function(sub, tab) {
  e <- sub$elements[!is.na(sub$elements$leaf), , drop = FALSE]
  e <- e[order(match(e$leaf, tab$leaf), seq_len(nrow(e))), , drop = FALSE]
  data.frame(figure = tab$figure[1], k = tab$k[match(e$leaf, tab$leaf)],
             index = stats::ave(seq_len(nrow(e)), e$leaf, FUN = seq_along), tag = e$tag,
             x0 = round(e$x0, 1), y0 = round(e$y0, 1), x1 = round(e$x1, 1), y1 = round(e$y1, 1),
             text = substr(gsub("[\r\n\t]+", " ", e$text), 1L, 60L), fill = e$fill, stroke = e$stroke,
             stringsAsFactors = FALSE)
}

# Parse "all", "3", "1-4", "1-4,7" into element indices of a leaf of n.
parse_elements <- function(spec, n) {
  spec <- gsub("\\s", "", spec)
  if (identical(spec, "all") || !nzchar(spec)) return(seq_len(n))
  parts <- strsplit(strsplit(spec, ",", fixed = TRUE)[[1]], "-", fixed = TRUE)
  idx <- unlist(lapply(parts, function(p) {
    v <- suppressWarnings(as.integer(p))
    if (anyNA(v) || !length(v) || length(v) > 2L) return(NA_integer_)
    if (length(v) == 2L) seq(v[1], v[2]) else v
  }))
  if (anyNA(idx) || any(idx < 1L | idx > n)) stop(sprintf("elements '%s' do not lie in 1..%d", spec, n), call. = FALSE)
  idx
}

# Write <id>.csv (the leaf table, the template annotators fill), <id>.svg
# (the outlined page) and, where rsvg-convert exists, <id>.png at 2x and
# <id>-page.png (the page without outlines).
write_sheet <- function(sub, id, out_dir) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  tab <- sheet_table(sub, id)
  utils::write.csv(tab, file.path(out_dir, paste0(id, ".csv")), row.names = FALSE, na = "")
  utils::write.csv(sheet_elements(sub, tab), file.path(out_dir, paste0(id, "-elements.csv")), row.names = FALSE, na = "")
  svg <- file.path(out_dir, paste0(id, ".svg"))
  writeLines(sheet_svg(sub$scene, tab), svg, useBytes = TRUE)
  rsvg <- Sys.which("rsvg-convert")
  if (nzchar(rsvg)) {
    page <- tempfile(fileext = ".svg")
    writeLines(sub$scene, page, useBytes = TRUE)
    system2(rsvg, c("-z", "3", "-b", "white", "-o", shQuote(file.path(out_dir, paste0(id, ".png"))), shQuote(svg)))
    system2(rsvg, c("-z", "2", "-b", "white", "-o", shQuote(file.path(out_dir, paste0(id, "-page.png"))), shQuote(page)))
    unlink(page)
  }
  invisible(tab)
}
