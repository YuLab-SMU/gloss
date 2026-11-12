# Where a character symbol drawn as a glyph outline (showtext) lies against
# its point: the outline's vertex mean and its box centre (plan
# 2026-11-11-tree-binding, Task 5; bench tree-061 draws geom_point(shape =
# '|') with emojifont, which turns showtext on).
#   Rscript dev_docs/research/point-symbols/glyph.R
# Uses gloss's own capture and the ggplot engine's rows (pkgload::load_all()).
suppressMessages(pkgload::load_all(quiet = TRUE))
cat("showtext", as.character(utils::packageVersion("showtext")), "| svglite", as.character(utils::packageVersion("svglite")),
    "|", Sys.info()[["sysname"]], "\n")
showtext::showtext_auto(TRUE)
d <- data.frame(x = 1:6, y = c(2, 4, 1, 3, 5, 2))
cat("dx, dy: the measure minus the row's point, pt (y down), over 6 points\n")
for (ch in c("|", "A", "o", "+", "x", "j")) for (sz in c(1.5, 4, 10)) {
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$y)) + ggplot2::geom_point(shape = ch, size = sz)
  eng <- gl_plugin("engine", "ggplot")
  res <- suppressWarnings(capture_figure(p, eng, context = FALSE))
  cl <- eng$bind(res$state, res$fig$substrate)$claims[[1]]
  geo <- scene_geometry(res$fig$substrate)
  g <- geo[geo$leaf %in% cl$leaf, ]
  g <- g[order(g$ordinal), ]
  if (nrow(g) != nrow(cl$pred)) {
    cat(sprintf("'%s' size %.1f: %d elements for %d rows\n", ch, sz, nrow(g), nrow(cl$pred)))
    next
  }
  vm <- t(vapply(g$vertices, function(v) if (is.null(v)) c(NA, NA) else colMeans(v), numeric(2)))
  rg <- function(v) paste(sprintf("%+.2f", range(v)), collapse = "..")
  inside <- cl$pred$x >= g$x0 & cl$pred$x <= g$x1
  cat(sprintf("'%s' size %4.1f, tags %s: vertex mean dx %s dy %s | box centre dx %s dy %s | box width %.2f | point inside the box along: %d of %d\n",
              ch, sz, paste(unique(g$tag), collapse = "+"), rg(vm[, 1] - cl$pred$x), rg(vm[, 2] - cl$pred$y),
              rg((g$x0 + g$x1) / 2 - cl$pred$x), rg((g$y0 + g$y1) / 2 - cl$pred$y), mean(g$x1 - g$x0), sum(inside), length(inside)))
}
showtext::showtext_auto(FALSE)
