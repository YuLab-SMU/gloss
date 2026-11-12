# S5 (2026-11-10): is page capture a drop-in for what the engines give today?
# Host, no third-party code.
#   A. the six test inputs: leaves, elements and panels from the page route
#      against gloss() as it is;
#   B. a base plot's panel and user coordinates from par(), with no viewport:
#      do they place the data where the device drew it?
#   C. a wrapped display list redrawn on a second device (what rasterising a
#      dense leaf needs).
# Run from the repository root: Rscript dev_docs/research/capture-fidelity/s5-drop-in.R
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))
source("dev_docs/research/capture-fidelity/page-capture.R")
source("tests/testthat/helper-figures.R")

cat("== A. the six test inputs: page route against gloss() ==\n")
inputs <- six_inputs()
for (nm in names(inputs)) {
  inp <- inputs[[nm]]
  eng <- find_engine(inp$x)
  fig <- suppressWarnings(gloss(inp$x, width = 7, height = 5, dense = Inf, context = FALSE))
  old <- fig$substrate
  if (identical(eng$name, "base")) {
    # base: the page route has no grobs; compare the pages only
    s <- svglite::svgstring(width = 7, height = 5); grDevices::dev.control("enable")
    inp$x(); rp <- grDevices::recordPlot(); A <- last_page(s); invisible(grDevices::dev.off())
    by <- replay_by_entry(rp)
    a <- scene_signatures(by$page); b <- scene_signatures(A); o <- scene_signatures(old$scene)
    cat(sprintf("  %-13s base: page route = native %s | gloss() today = native %s (differ %d) | entries that drew %d, gridGraphics leaves %d\n",
                nm, identical(a, b), identical(o, b), diffn(o, b), sum(diff(c(0L, by$seen)) > 0L), nrow(old$leaves)))
    next
  }
  set.seed(99)
  s <- svglite::svgstring(width = 7, height = 5); grDevices::dev.control("enable")
  suppressWarnings(inp$draw())
  new <- suppressWarnings(capture_grid_page(s))
  state <- eng$prepare(inp$x, 7, 5)
  if (identical(eng$name, "heatmap")) { pdf(NULL); state$drawn <- ComplexHeatmap::draw(state$ht); invisible(dev.off()) }
  pan_new <- if (!is.null(eng$panels)) eng$panels(state, new) else NULL
  cols <- c("name", "class", "vp", "x0", "y0", "x1", "y1", "xscale0", "xscale1", "yscale0", "yscale1", "n_expected", "n_drawn", "status")
  same_leaves <- isTRUE(all.equal(old$leaves[cols], new$leaves[cols], check.attributes = FALSE))
  same_elements <- isTRUE(all.equal(old$elements, new$elements, check.attributes = FALSE))
  same_panels <- if (is.null(pan_new)) nrow(old$panels) == 0L else isTRUE(all.equal(old$panels, pan_new$panels, check.attributes = FALSE))
  cat(sprintf("  %-13s %-9s leaves %3d / %3d same=%-5s | elements %5d / %5d same=%-5s | panels %d / %d same=%s\n",
              nm, eng$name, nrow(old$leaves), nrow(new$leaves), same_leaves, nrow(old$elements), nrow(new$elements),
              same_elements, nrow(old$panels), if (is.null(pan_new)) 0L else nrow(pan_new$panels), same_panels))
  if (!same_leaves) {
    k <- which(!vapply(cols, function(cc) isTRUE(all.equal(old$leaves[[cc]], new$leaves[[cc]])), TRUE))
    cat("      leaf columns that differ:", paste(cols[k], collapse = ", "), "\n")
  }
}

cat("\n== B. base: panel box and scales from par(), checked against the drawn points ==\n")
check_base <- function(label, draw, x, y, logx = FALSE, logy = FALSE, entry_op = "C_plotXY", which_entry = 1L) {
  s <- svglite::svgstring(width = 7, height = 5); grDevices::dev.control("enable")
  draw(); rp <- grDevices::recordPlot(); invisible(grDevices::dev.off())
  by <- replay_by_entry(rp)
  k <- which(by$ops == entry_op)[which_entry]
  first <- if (k == 1L) 1L else by$seen[k - 1L] + 1L
  doc <- xml2::read_xml(by$page)
  nodes <- xml2::xml_find_all(doc, prim_xpath(), svg_ns(doc))[first:by$seen[k]]
  cx <- as.numeric(xml2::xml_attr(nodes, "cx")); cy <- as.numeric(xml2::xml_attr(nodes, "cy"))
  usr <- by$usr[[k]]; plt <- by$plt[[k]]; fig <- by$fig[[k]]
  W <- 7 * 72; H <- 5 * 72
  # plot region on the device, from fig (fraction of the device) and plt (fraction of the figure region)
  fx0 <- fig[1] * W; fx1 <- fig[2] * W; fy0 <- fig[3] * H; fy1 <- fig[4] * H
  px0 <- fx0 + plt[1] * (fx1 - fx0); px1 <- fx0 + plt[2] * (fx1 - fx0)
  py0 <- fy0 + plt[3] * (fy1 - fy0); py1 <- fy0 + plt[4] * (fy1 - fy0)
  ux <- if (logx) log10(x) else x; uy <- if (logy) log10(y) else y
  ex <- px0 + (ux - usr[1]) / (usr[2] - usr[1]) * (px1 - px0)
  ey <- H - (py0 + (uy - usr[3]) / (usr[4] - usr[3]) * (py1 - py0))
  ok <- length(cx) == length(x)
  cat(sprintf("  %-26s entry %2d (%s) drew %3d circles for %3d rows%s\n", label, k, entry_op, length(cx), length(x),
              if (ok) sprintf("; largest gap between computed and drawn position: %.3f pt (x), %.3f pt (y)",
                              max(abs(ex - cx)), max(abs(ey - cy))) else "  [counts differ]"))
}
check_base("scatter", function() plot(mtcars$wt, mtcars$mpg, pch = 19), mtcars$wt, mtcars$mpg)
check_base("log-log", function() plot(1:100, (1:100)^2, log = "xy", pch = 19), 1:100, (1:100)^2, logx = TRUE, logy = TRUE)
check_base("mfrow, second panel", function() { par(mfrow = c(1, 2)); plot(1:5, pch = 19); plot(mtcars$hp, mtcars$qsec, pch = 19) },
           mtcars$hp, mtcars$qsec, which_entry = 2L)
check_base("layout + margins", function() { layout(matrix(1:2, 2), heights = c(1, 2)); par(mar = c(2, 6, 1, 3)); plot(1:3, pch = 19); plot(mtcars$disp, mtcars$drat, pch = 19) },
           mtcars$disp, mtcars$drat, which_entry = 2L)

cat("\n== C. a wrapped display list redrawn on a second device ==\n")
p <- inputs$ggplot_facet$x
s <- svglite::svgstring(width = 7, height = 5); grDevices::dev.control("enable")
print(p); A <- last_page(s)
grid::grid.force()
dl <- list()
grid::grid.DLapply(function(elt) { dl[[length(dl) + 1L]] <<- elt; elt })
invisible(grDevices::dev.off())
B <- plain_svg(function() { grid::grid.newpage(); for (elt in dl) grid::grid.draw(elt, recording = FALSE) }, 7, 5)
cat(sprintf("  display list of %d elements (%s) drawn on a second svglite device: identical to the page = %s\n",
            length(dl), paste(names(table(vapply(dl, function(e) class(e)[1], ""))), collapse = ", "),
            identical(scene_signatures(B), scene_signatures(A))))
