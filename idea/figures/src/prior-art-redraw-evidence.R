# Figure: real screenshots from the 2026-11-07 translation experiments.
# Three of the five test figures, as drawn by svglite (baseline), plotly and
# canvasXpress. All shots are the 700x500 captures: svglite from Craft Anything,
# plotly and canvasXpress from REA (the two tools agree on every pixel count).
# Pixel shares come from dev_docs/research/translate/pixel_diffs.csv (share of
# pixels off by more than 16 levels against the ggplot2 PNG).
#
#   Rscript idea/figures/src/prior-art-redraw-evidence.R
# writes idea/figures/prior-art-redraw-evidence.png

library(grid)
source("dev_docs/figures/design/src/theme_research.R")
shots <- "dev_docs/research/translate/shots"
diffs <- read.csv("dev_docs/research/translate/pixel_diffs.csv")
fam <- "Helvetica Neue"
sym <- "PingFang SC"  # has the ✗ glyph

rows <- data.frame(
  key   = c("b_patchwork", "c_repel", "e_pointrange"),
  label = c("(b) patchwork", "(c) ggrepel", "(e) forest plot")
)
cols <- data.frame(
  key    = c("svglite", "plotly", "cx"),
  label  = c("ggplot2 → svglite (baseline)", "plotly::ggplotly()", "canvasXpress()")
)
# Failures that the doc reports, keyed by figure x renderer
fail <- c(
  "b_patchwork.plotly" = "only the last panel, no warning",
  "c_repel.plotly"     = "all 32 labels dropped (it warns)",
  "e_pointrange.cx"    = "a bar chart, axes swapped, no warning"
)
pct <- function(fig, r) {
  row <- diffs$figure == fig & diffs$render == r
  v <- diffs$craft_diff_frac[row]
  stopifnot(length(v) == 1, diffs$agree[row] %in% c(TRUE, "True"))
  sprintf("%.1f%% of pixels differ", 100 * v)
}
# Values quoted in the prior-art note
stopifnot(pct("b_patchwork", "plotly") == "26.6% of pixels differ",
          pct("e_pointrange", "cx") == "31.8% of pixels differ",
          pct("c_repel", "plotly") == "6.5% of pixels differ")

cell <- function(fig, r) {
  tool <- if (r == "svglite") "craft" else "rea"
  f <- file.path(shots, sprintf("%s_%s_%s.png", fig, r, tool))
  stopifnot(identical(dim(png::readPNG(f))[1:2], c(500L, 700L)))
  img <- png::readPNG(f)
  key <- paste(fig, r, sep = ".")
  notes <- gList(textGrob(pct(fig, r), x = 0.02, y = unit(1.55, "lines"), just = "left",
                          gp = gpar(fontfamily = "Menlo", fontsize = 10.5, col = rw$muted)))
  if (key %in% names(fail)) {
    notes <- gList(notes,
      textGrob("✗", x = 0.02, y = unit(0.45, "lines"), just = "left",
               gp = gpar(fontfamily = sym, fontsize = 12, fontface = "bold", col = rw$highlight)),
      textGrob(fail[[key]], x = unit(0.02, "npc") + unit(1.1, "lines"), y = unit(0.45, "lines"),
               just = "left", gp = gpar(fontfamily = fam, fontsize = 12, fontface = "bold", col = rw$highlight)))
  }
  border <- if (key %in% names(fail)) rw$highlight else rw$stroke
  gTree(children = gList(
    grobTree(rectGrob(gp = gpar(fill = "white", col = border, lwd = if (border == rw$highlight) 2.2 else 0.8)),
             rasterGrob(img, interpolate = TRUE),
             vp = viewport(y = unit(1, "npc"), height = unit(1, "npc") - unit(2.4, "lines"), just = "top",
                           width = unit(1, "snpc") * 1.4)),
    grobTree(notes, vp = viewport(y = 0, height = unit(2.2, "lines"), just = "bottom",
                                  width = unit(1, "snpc") * 1.4))
  ))
}

lay <- grid.layout(nrow = 1 + nrow(rows), ncol = 1 + nrow(cols),
                   widths = unit(c(1.6, rep(1, 3)), c("in", rep("null", 3))),
                   heights = unit(c(0.45, rep(1, 3)), c("in", rep("null", 3))))
body <- gList()
for (j in seq_len(nrow(cols))) {
  body <- gList(body, grobTree(textGrob(cols$label[j], gp = gpar(fontfamily = fam, fontsize = 14,
    fontface = "bold", col = rw$body)), vp = viewport(layout.pos.row = 1, layout.pos.col = j + 1)))
}
for (i in seq_len(nrow(rows))) {
  body <- gList(body, grobTree(textGrob(rows$label[i], x = 0, just = "left",
    gp = gpar(fontfamily = fam, fontsize = 13.5, fontface = "bold", col = rw$body)),
    vp = viewport(layout.pos.row = i + 1, layout.pos.col = 1)))
  for (j in seq_len(nrow(cols))) {
    body <- gList(body, grobTree(cell(rows$key[i], cols$key[j]),
      vp = viewport(layout.pos.row = i + 1, layout.pos.col = j + 1,
                    width = unit(1, "npc") - unit(0.25, "in"), height = unit(1, "npc") - unit(0.2, "in"))))
  }
}

u <- unit
fig <- gTree(children = gList(
  rectGrob(gp = gpar(fill = rw$canvas, col = NA)),
  textGrob("Redrawing in another engine changed the figure, sometimes without a warning",
           y = u(1, "npc") - u(0.5, "in"),
           gp = gpar(fontfamily = fam, fontsize = 24, fontface = "bold", col = rw$ink)),
  textGrob("Screenshots from the 2026-11-07 experiments. Pixel share: pixels off by more than 16 levels against the ggplot2 PNG.",
           y = u(1, "npc") - u(0.9, "in"),
           gp = gpar(fontfamily = fam, fontsize = 13.5, col = rw$muted)),
  grobTree(roundrectGrob(r = u(0.22, "in"), gp = gpar(fill = rw$panel, col = NA)),
           grobTree(body, vp = viewport(width = u(1, "npc") - u(0.4, "in"),
                                         height = u(1, "npc") - u(0.3, "in"), layout = lay)),
           vp = viewport(x = u(0.3, "in"), y = u(0.3, "in"), just = c("left", "bottom"),
                         width = u(1, "npc") - u(0.6, "in"), height = u(1, "npc") - u(1.45, "in")))
))
rw_save(fig, "idea/figures/prior-art-redraw-evidence.png", width = 14, height = 10.6, res = 150)
