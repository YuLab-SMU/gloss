# S7 (2026-11-10): does the fidelity comparison see clipping?
# scene_signatures() compares tag, attributes and text of each primitive. The
# clip region is an attribute of an ANCESTOR <g>, so a primitive that lost or
# changed its clip has the same signature. Check on a clipping grob (a leaf:
# inside a graphics group its clip ends with the group) and on ordinary figures.
# Run from the repository root: Rscript dev_docs/research/capture-fidelity/s7-clip-blind-spot.R
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
source("dev_docs/research/capture-fidelity/page-capture.R")
source("tests/testthat/helper-figures.R")

row <- function(label, scene, ref) {
  a <- scene_signatures(scene); b <- scene_signatures(ref)
  ca <- clip_signatures(scene); cb <- clip_signatures(ref)
  cat(sprintf("  %-34s primitives equal %-5s | with clip regions equal %-5s (%d of %d differ)\n", label,
              identical(a, b), identical(ca, cb), if (length(ca) == length(cb)) sum(ca != cb) else NA, length(cb)))
}

cat("== a clipping grob as a leaf ==\n")
g <- grid::gTree(children = grid::gList(grid::clipGrob(width = .4, height = .4),
                                        grid::circleGrob(r = .45, gp = grid::gpar(fill = "blue"))))
ref <- plain_svg(function() grid::grid.draw(g), 7, 5)
row("gloss() today", gloss(g, width = 7, height = 5, context = FALSE)$substrate$scene, ref)
s <- svglite::svgstring(width = 7, height = 5); grDevices::dev.control("enable"); grid::grid.draw(g)
row("page route", capture_grid_page(s)$scene, ref)

cat("\n== ordinary figures: is clipping kept? ==\n")
inputs <- six_inputs()
for (nm in names(inputs)) {
  inp <- inputs[[nm]]
  set.seed(5); ref <- suppressWarnings(plain_svg(inp$draw, 7, 5))
  set.seed(5); fig <- suppressWarnings(gloss(inp$x, width = 7, height = 5, dense = Inf, context = FALSE))
  row(paste("gloss() today:", nm), fig$substrate$scene, ref)
}
