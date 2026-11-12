# S1 (2026-11-10): capture the PAGE a figure draws, by wrapping the grid display
# list in place, instead of capturing a grob an engine builds or a grid.grab().
#
#   draw()                      -> page A: what the figure's own code/print draws
#   grid.force()                -> forces the display list in place
#   grid.DLapply(wrap leaves)   -> every leaf becomes probe + group (ADR-0001)
#   grid.refresh()              -> page B: the same display list, drawn again
#
# Question: is B, with groups inlined, primitive for primitive equal to A?
# Run from the repository root: Rscript dev_docs/research/capture-fidelity/s1-page-grid.R
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))

source("dev_docs/research/capture-fidelity/page-capture.R")

# Draw on svglite (page A0), then capture that page in place (page B).
page_capture <- function(draw, width = 7, height = 5, seed = NULL) {
  s <- svglite::svgstring(width = width, height = height, standalone = TRUE)
  dev <- grDevices::dev.cur()
  on.exit(if (dev %in% grDevices::dev.list()) grDevices::dev.off(dev), add = TRUE)
  grDevices::dev.control("enable")
  if (!is.null(seed)) set.seed(seed)
  draw()
  grDevices::dev.set(dev)
  A <- last_page(s)
  if (!is.null(seed)) set.seed(seed)
  list(A = A, sub = capture_grid_page(s, width, height))
}

report <- function(label, draw, seed = NULL) {
  t0 <- Sys.time()
  r <- tryCatch(suppressWarnings(page_capture(draw, seed = seed)), error = function(e) e)
  if (inherits(r, "error")) {
    cat(sprintf("%-34s ERROR: %s\n", label, substr(gsub("\n", " ", conditionMessage(r)), 1, 120)))
    return(invisible(NULL))
  }
  a <- scene_signatures(r$sub$scene); b <- scene_signatures(r$A)
  cat(sprintf("%-34s page A %5d prims | scene %5d | identical=%-5s differ=%-4d | leaves %4d, unowned %d | %.2fs\n",
              label, length(b), length(a), identical(a, b), diffn(a, b), nrow(r$sub$leaves),
              sum(is.na(r$sub$elements$leaf)), as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  invisible(r)
}

if (sys.nframe() == 0L) {
  library(ggplot2)
  p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point() +
    geom_smooth(method = "lm", formula = y ~ x) + facet_wrap(~am)
  report("ggplot print()", function() print(p))
  report("patchwork print()", function() print(patchwork::wrap_plots(p, p + theme_bw(), ncol = 1)))
  set.seed(1); m <- matrix(rnorm(80), 10, dimnames = list(paste0("g", 1:10), paste0("s", 1:8)))
  ha <- ComplexHeatmap::HeatmapAnnotation(cyl = sample(c("a", "b"), 8, TRUE))
  ht <- ComplexHeatmap::Heatmap(m, top_annotation = ha, name = "z")
  report("ComplexHeatmap draw()", function() ComplexHeatmap::draw(ht))
  report("ComplexHeatmap list + split", function() ComplexHeatmap::draw(ht + ComplexHeatmap::Heatmap(m[, 1:3], name = "w", row_km = 2)))
  report("lattice xyplot print()", function() print(lattice::xyplot(mpg ~ wt | factor(cyl), mtcars)))
  report("lattice levelplot", function() print(lattice::levelplot(volcano)))
  p0 <- ggplot(mtcars, aes(wt, mpg, color = cyl, size = cyl)) + geom_point() + theme(legend.position = "none")
  if (requireNamespace("ggExtra", quietly = TRUE)) {
    report("ggExtra ggMarginal print()", function() print(ggExtra::ggMarginal(p0, type = "density")))
    report("ggExtra p1 then p2, one page", function() { print(ggExtra::ggMarginal(p0, type = "histogram")); print(ggExtra::ggMarginal(p0, type = "density")) })
  }
  if (requireNamespace("pheatmap", quietly = TRUE)) report("pheatmap", function() pheatmap::pheatmap(m))
  if (requireNamespace("aplot", quietly = TRUE)) report("aplot insert_top print()", function() print(aplot::insert_top(p0, p0 + theme_void(), height = .3)))
  if (requireNamespace("gridExtra", quietly = TRUE)) report("gridExtra grid.arrange", function() gridExtra::grid.arrange(p0, p0, ncol = 2))
  if (requireNamespace("cowplot", quietly = TRUE)) report("cowplot plot_grid print()", function() print(cowplot::plot_grid(p0, p0, labels = "AUTO")))
  report("grid calls with viewports", function() {
    grid::grid.newpage()
    grid::pushViewport(grid::viewport(width = .8, height = .8, name = "a", xscale = c(0, 10)))
    grid::grid.rect(gp = grid::gpar(fill = "grey90"))
    grid::pushViewport(grid::viewport(width = .5, height = .5, name = "a"))   # same name, another definition
    grid::grid.points(grid::unit(1:3 / 4, "npc"), grid::unit(1:3 / 4, "npc"), pch = 19)
    grid::upViewport(2)
    grid::grid.text("title", y = .95)
  })
  if (requireNamespace("ggrepel", quietly = TRUE)) {
    pr <- ggplot(mtcars, aes(wt, mpg, label = rownames(mtcars))) + geom_point() + ggrepel::geom_text_repel()
    report("ggrepel, no seed, RNG not pinned", function() print(pr))
    report("ggrepel, no seed, RNG pinned", function() print(pr), seed = 42)
  }
  big <- data.frame(x = rnorm(1e4), y = rnorm(1e4))
  report("10^4 points", function() print(ggplot(big, aes(x, y)) + geom_point(size = .3)))
}
