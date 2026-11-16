#!/usr/bin/env Rscript

# Build a prompt-side visual evidence view. The original captured scene is
# written separately; the prepared view adds only deterministic labels and
# panel guides. It never writes a binding or changes the substrate.

suppressPackageStartupMessages({
  pkgload::load_all(".", quiet = TRUE, export_all = FALSE, helpers = FALSE)
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("ggplot2 is required")
  if (!requireNamespace("rsvg", quietly = TRUE)) stop("rsvg is required")
})

out <- "bench/runs/2026-11-15-visual-view"
dir.create(out, recursive = TRUE, showWarnings = FALSE)

p <- ggplot2::ggplot(
  mtcars,
  ggplot2::aes(wt, mpg, colour = factor(cyl))
) + ggplot2::geom_point() + ggplot2::facet_wrap(~am)
fig <- gloss::gloss(p, width = 7, height = 4, context = FALSE)
elements <- gloss::gl_elements(fig)
panels <- gloss::gl_panels(fig)

points <- elements[!is.na(elements$panel) & elements$tag == "circle", , drop = FALSE]
points <- points[order(points$panel, points$y0, points$x0, points$id), , drop = FALSE]
panel_points <- split(points, points$panel)
points <- do.call(rbind, lapply(names(panel_points), function(panel) {
  utils::head(panel_points[[panel]], 6L)
}))
rownames(points) <- NULL
stopifnot(nrow(points) == 12L)

page_w <- fig$meta$width * 72
page_h <- fig$meta$height * 72
clamp <- function(x, lo, hi) max(lo, min(hi, x))
xml_attr <- function(x) {
  x <- enc2utf8(as.character(x))
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}

labels <- points$id
panel_xml <- paste(vapply(seq_len(nrow(panels)), function(i) {
  p <- panels[i, ]
  paste0(
    '<rect x="', p$x0, '" y="', p$y0, '" width="', p$x1 - p$x0,
    '" height="', p$y1 - p$y0,
    '" fill="none" stroke="#2b6cb0" stroke-width="1.2" stroke-dasharray="4 3" opacity="0.75"/>',
    '<text x="', p$x0 + 3, '" y="', p$y0 + 12,
    '" fill="#1e4e79" font-family="monospace" font-size="9" font-weight="bold">',
    xml_attr(p$key), '</text>'
  )
}, ""), collapse = "")

point_xml <- paste(vapply(seq_len(nrow(points)), function(i) {
  e <- points[i, ]
  label <- labels[i]
  cx <- (e$x0 + e$x1) / 2
  cy <- (e$y0 + e$y1) / 2
  dx <- if (i %% 2L) -12 else 5
  dy <- if ((i %% 4L) %in% c(1L, 2L)) -13 else 9
  x <- clamp(cx + dx, 1, page_w - 18)
  y <- clamp(cy + dy, 14, page_h - 3)
  paste0(
    '<rect x="', e$x0 - 2, '" y="', e$y0 - 2, '" width="', e$x1 - e$x0 + 4,
    '" height="', e$y1 - e$y0 + 4,
    '" fill="none" stroke="#c53030" stroke-width="1.1"/>',
    '<line x1="', cx, '" y1="', cy, '" x2="', x + 7, '" y2="', y - 7,
    '" stroke="#c53030" stroke-width="0.7"/>',
    '<rect x="', x, '" y="', y - 14, '" width="18" height="14" fill="#c53030" opacity="0.95"/>',
    '<text x="', x + 2, '" y="', y - 4,
    '" fill="#ffffff" font-family="monospace" font-size="7" font-weight="bold">', label, '</text>'
  )
}, ""), collapse = "")

overlay <- paste0(
  '<g id="gloss-prepared-visual-view" aria-label="prompt-side visual evidence">',
  '<rect x="0" y="0" width="', page_w, '" height="18" fill="#fffaf0" opacity="0.96"/>',
  '<text x="6" y="12" fill="#744210" font-family="sans-serif" font-size="9">',
  'Prepared view: labels locate elements only; no data bindings are shown.',
  '</text>',
  panel_xml, point_xml,
  '</g>'
)

scene <- fig$substrate$scene
stopifnot(grepl("</svg>", scene, fixed = TRUE))
prepared <- sub("</svg>", paste0(overlay, "</svg>"), scene, fixed = TRUE)
stopifnot(identical(scene, fig$substrate$scene))
restored <- sub(paste0(overlay, "</svg>"), "</svg>", prepared, fixed = TRUE)
stopifnot(identical(restored, scene))
stopifnot(!grepl("built_layer|row[ =:]", overlay, ignore.case = TRUE))

source_hash <- digest::digest(scene, algo = "sha256", serialize = FALSE)
prepared_hash <- digest::digest(prepared, algo = "sha256", serialize = FALSE)
writeLines(scene, file.path(out, "source.svg"), useBytes = TRUE)
writeLines(prepared, file.path(out, "prepared.svg"), useBytes = TRUE)
rsvg::rsvg_png(charToRaw(prepared), file.path(out, "prepared.png"),
               width = 1008, height = 576)

metadata <- list(
  format = "gloss-prepared-visual-view",
  version = "0.1.0",
  source_scene_sha256 = source_hash,
  prepared_view_sha256 = prepared_hash,
  geometry_source = "graphics-device scene; prepared overlay is prompt-side only",
  contains_binding_answers = FALSE,
  panels = lapply(seq_len(nrow(panels)), function(i) {
    p <- panels[i, ]
    list(id = p$id, key = p$key, bbox = list(x0 = p$x0, y0 = p$y0, x1 = p$x1, y1 = p$y1))
  }),
  element_labels = lapply(seq_len(nrow(points)), function(i) {
    e <- points[i, ]
    list(label = labels[i], element = e$id, tag = e$tag, panel = e$panel,
         bbox = list(x0 = e$x0, y0 = e$y0, x1 = e$x1, y1 = e$y1))
  })
)
jsonlite::write_json(metadata, file.path(out, "metadata.json"), auto_unbox = TRUE,
                     pretty = TRUE, na = "null")

# Re-render once to make the artifact contract executable and deterministic.
stopifnot(identical(digest::digest(prepared, algo = "sha256", serialize = FALSE), prepared_hash))
cat("prepared visual view:", out, "\n")
cat("source scene sha256:", source_hash, "\n")
cat("prepared view sha256:", prepared_hash, "\n")
cat("labelled elements:", nrow(points), "panels:", nrow(panels), "\n")
