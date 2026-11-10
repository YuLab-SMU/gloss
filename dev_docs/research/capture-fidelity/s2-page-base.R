# S2 (2026-11-10): capture a base-graphics page natively, without gridGraphics.
#
# A recordedplot holds the device's display list: one entry per graphics call
# (C_plot_new, C_plot_window, C_plotXY, C_axis, C_box, C_title, ...). The
# entries are evaluated one at a time on svglite, the way replayPlot() plays
# them, and the device's output is read after each one (svgstring() can be
# read while the page is open). The primitives written between two reads were
# drawn by that entry: attribution comes from the device, with no redrawing by
# another renderer.
#
# Questions: (1) is the page identical to the code's own drawing on svglite and
# to replayPlot()? (2) how does gridGraphics' echo compare on the same inputs?
# Run from the repository root: Rscript dev_docs/research/capture-fidelity/s2-page-base.R
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE, helpers = FALSE))

source("dev_docs/research/capture-fidelity/page-capture.R")

# The code drawing on svglite: its page, and the device snapshot.
record_native <- function(f, width = 7, height = 5) {
  s <- svglite::svgstring(width = width, height = height, standalone = TRUE)
  dev <- grDevices::dev.cur()
  on.exit(if (dev %in% grDevices::dev.list()) grDevices::dev.off(dev))
  grDevices::dev.control("enable")
  f()
  rp <- grDevices::recordPlot()
  pages <- as.character(s())
  list(rp = rp, page = close_groups(pages[length(pages)]), pages = length(pages))
}

replay_plain <- function(rp, width = 7, height = 5) {
  plain_svg(function() grDevices::replayPlot(rp), width, height)
}

echo_page <- function(x, width = 7, height = 5) {
  tryCatch(suppressWarnings(gloss(x, width = width, height = height, dense = Inf, context = FALSE)$substrate$scene),
           error = function(e) NULL)
}

cases <- list(
  scatter_abline_legend = function() { plot(mtcars$wt, mtcars$mpg, pch = 19); abline(lm(mpg ~ wt, mtcars)); legend("topright", "fit", lty = 1) },
  mfrow_bar_legend = function() { par(mfrow = c(1, 2)); barplot(1:3, col = 2:4); legend("top", c("a", "b"), fill = 2:3, horiz = TRUE, bty = "n"); plot(1:10, las = 2); axis(4) },
  pairs = function() plot(mtcars[, c(1, 3:6)], pch = 20, cex = 1.5, col = "#69b3a2"),
  rect_border_0 = function() { plot.new(); rect(.2, .2, .8, .8, col = "white", border = 0) },
  rect_border_FALSE = function() { plot.new(); rect(.2, .2, .8, .8, col = "white", border = FALSE) },
  bg_colour = function() { par(bg = "lightblue"); plot(1:10) },
  axis_las_mtext = function() { plot(1:10, xaxt = "n"); axis(1, at = 1:10, labels = paste("label", 1:10), las = 2); mtext("side text", 4) },
  boxplot = function() boxplot(mpg ~ cyl, mtcars, col = "grey90"),
  hist_density = function() { hist(mtcars$mpg, freq = FALSE); lines(density(mtcars$mpg), lwd = 2) },
  image_contour = function() { image(volcano); contour(volcano, add = TRUE) },
  persp = function() persp(volcano[seq(1, 87, 6), seq(1, 61, 6)], theta = 30),
  pie = function() pie(c(3, 2, 5), labels = c("a", "b", "c")),
  plotmath = function() { plot(1:10, main = expression(alpha^2 + beta), xlab = quote(x[i])); text(5, 5, expression(hat(mu))) },
  layout_widths = function() { layout(matrix(1:3, 1), widths = c(2, 1, 1)); plot(1:5); plot(5:1, type = "l"); barplot(c(a = 1, b = 2)) },
  par_new_two_axes = function() { par(mar = c(5, 4, 4, 4)); plot(1:10, type = "l"); par(new = TRUE); plot(10:1 * 100, axes = FALSE, xlab = "", ylab = "", col = 2); axis(4) },
  log_axes = function() plot(1:100, (1:100)^2, log = "xy"),
  heatmap_base = function() heatmap(as.matrix(mtcars[1:12, 1:6]), scale = "column"),
  dendrogram = function() plot(hclust(dist(mtcars[1:15, ]))),
  matplot_arrows = function() { matplot(cbind(1:10, 10:1), type = "b"); arrows(2, 2, 5, 5); segments(1, 9, 9, 9, lty = 3); polygon(c(6, 8, 7), c(2, 2, 4), col = "grey") },
  stars = function() stars(mtcars[1:9, 1:5]),
  mosaic = function() mosaicplot(Titanic, color = TRUE),
  coplot = function() coplot(mpg ~ wt | factor(cyl), mtcars),
  smooth_scatter = function() smoothScatter(mtcars$wt, mtcars$mpg),
  filled_contour = function() filled.contour(volcano),
  symbols_xpd = function() { par(xpd = NA); plot(1:5); symbols(1:5, 1:5, circles = 1:5 / 10, add = TRUE, inches = FALSE); text(0.5, 5.5, "outside") },
  lm_page_4 = function() plot(lm(mpg ~ wt, mtcars))
)

if (sys.nframe() == 0L) {
  cat(sprintf("%-22s %5s %7s | %-18s %-18s | %-22s | %s\n", "case", "prims", "entries",
              "by entry = native", "replayPlot = native", "gridGraphics vs native", "seconds (by entry)"))
  for (nm in names(cases)) {
    rec <- suppressWarnings(record_native(cases[[nm]]))
    native <- scene_signatures(rec$page)
    plain <- scene_signatures(replay_plain(rec$rp))
    t0 <- Sys.time()
    by <- tryCatch(suppressWarnings(replay_by_entry(rec$rp)), error = function(e) e)
    secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    echo <- echo_page(rec$rp)
    echo_txt <- if (is.null(echo)) "error" else {
      a <- scene_signatures(echo)
      if (identical(a, native)) "identical" else sprintf("differ=%d (%d prims)", diffn(a, native), length(a))
    }
    if (inherits(by, "error")) {
      cat(sprintf("%-22s %5d %7d | ERROR %s\n", nm, length(native), length(rec$rp[[1]]), substr(conditionMessage(by), 1, 90)))
      next
    }
    b <- scene_signatures(by$page)
    mono <- all(diff(c(0L, by$seen)) >= 0L) && by$seen[length(by$seen)] == length(b)
    cat(sprintf("%-22s %5d %7d | %-18s %-18s | %-22s | %.2f%s%s\n", nm, length(native), length(by$seen),
                if (identical(b, native)) "identical" else sprintf("differ=%d", diffn(b, native)),
                if (identical(plain, native)) "identical" else sprintf("differ=%d", diffn(plain, native)),
                echo_txt, secs, if (!mono) "  [counts not monotone]" else "",
                if (rec$pages > 1) sprintf("  [%d pages drawn, last kept]", rec$pages) else ""))
  }
}
