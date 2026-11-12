# Where ggimage puts an image for each hjust (2026-11-12; plan
# 2026-11-11-tree-binding, Task 6). Run from the repository root in the bench
# container with the bioc library (ggimage is not in the CRAN one):
#   bench/docker/run.sh Rscript dev_docs/research/image-justification/ggimage.R
# For each case and row: the row on the page (pt, from gloss's ggplot engine,
# the transform the binder uses, after the layer's nudge), and the box of the
# <image> svglite wrote for it.
source("bench/R/common.R")
.libPaths(c(bench_envs$bioc$lib, .libPaths()))
suppressMessages({library(ggplot2); pkgload::load_all(".", quiet = TRUE)})
cat("ggimage", as.character(packageVersion("ggimage")), "| ggplot2", as.character(packageVersion("ggplot2")),
    "| svglite", as.character(packageVersion("svglite")), "| R", R.version$major, R.version$minor, "\n")
img <- system.file("extdata", "Rlogo.png", package = "ggimage")
stopifnot(nzchar(img))
d <- data.frame(x = c(1, 3, 5), y = c(1, 2, 3), image = img)
cat(sprintf("%-5s %-6s %-5s %-4s %-3s %8s %8s %8s %8s %8s %8s\n", "by", "hjust", "size", "xmax", "row",
            "row_x", "box_x0", "box_w", "x0-row", "cx-row", "cy-row"))
for (by in c("width", "height")) for (xmax in c(8, 30)) for (size in c(0.05, 0.2)) for (h in c(0, 0.5, 1)) {
  p <- ggplot(d, aes(x, y, image = image)) + ggimage::geom_image(hjust = h, size = size, by = by) +
    xlim(0, xmax) + ylim(0, 4)
  eng <- gl_plugin("engine", "ggplot")
  res <- suppressWarnings(suppressMessages(capture_figure(p, eng, context = FALSE)))
  stated <- eng$bind(res$state, res$fig$substrate)
  geo <- scene_geometry(res$fig$substrate)
  for (cl in stated$claims) {
    g <- geo[geo$leaf %in% cl$leaf, ]
    if (!all(g$tag == "image")) next
    pr <- cl$pred
    for (k in seq_len(nrow(g))) {
      r <- if (nrow(pr) == nrow(g)) k else match(cl$leaf, vapply(stated$claims, `[[`, "", "leaf"))
      cat(sprintf("%-5s %-6s %-5s %-4s %-3d %8.2f %8.2f %8.2f %8.2f %8.2f %8.2f\n", by, h, size, xmax, r,
                  pr$x[r], g$x0[k], g$x1[k] - g$x0[k], g$x0[k] - pr$x[r], (g$x0[k] + g$x1[k]) / 2 - pr$x[r],
                  (g$y0[k] + g$y1[k]) / 2 - pr$y[r]))
    }
  }
}
