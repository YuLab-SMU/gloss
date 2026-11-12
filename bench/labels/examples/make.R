# The guideline's worked examples: three hand-built figures (not bench
# figures), captured by gloss and drawn as label sheets.
#   Rscript bench/labels/examples/make.R
devtools::load_all(quiet = TRUE)
source("bench/R/sheet.R")
out <- "bench/labels/examples"

# ggplot: points by group, a fitted line per group, facets, a reference line
# at a typed value, a typed annotation, data labels, title and caption
d <- datasets::mtcars
d$car <- rownames(d)
p <- ggplot2::ggplot(d, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
  ggplot2::geom_hline(yintercept = 20, linetype = 2) +
  ggplot2::geom_point() +
  ggplot2::geom_smooth(method = "lm", formula = y ~ x, se = TRUE) +
  ggplot2::geom_text(data = d[d$mpg > 30, ], ggplot2::aes(label = car), size = 2.5, vjust = -1) +
  ggplot2::annotate("text", x = 5, y = 32, label = "heavier") +
  ggplot2::annotate("rect", xmin = 4.5, xmax = 5.5, ymin = 10, ymax = 16, alpha = 0.2) +
  ggplot2::facet_wrap(~am, labeller = ggplot2::label_both) +
  ggplot2::labs(title = "Fuel use by weight", caption = "mtcars", colour = "cylinders")
write_sheet(suppressWarnings(gloss(p))$substrate, "ex-ggplot", out)

# base: points, a typed reference line, a legend drawn by legend(), a typed
# text, bars in a second panel
f <- function() {
  op <- graphics::par(mfrow = c(1, 2))
  on.exit(graphics::par(op))
  plot(d$wt, d$mpg, col = d$cyl, pch = 19, main = "Weight", xlab = "wt", ylab = "mpg")
  graphics::abline(h = 20, lty = 2)
  graphics::legend("topright", legend = c(4, 6, 8), col = c(4, 6, 8), pch = 19, title = "cyl")
  graphics::text(4.5, 32, "heavier")
  graphics::barplot(table(d$gear), main = "Gears")
}
write_sheet(gloss(f)$substrate, "ex-base", out)

# ComplexHeatmap: split rows, a column annotation, dendrograms, legends
set.seed(1)
m <- matrix(stats::rnorm(48), 6, dimnames = list(paste0("g", 1:6), paste0("s", 1:8)))
ha <- ComplexHeatmap::HeatmapAnnotation(group = rep(c("a", "b"), each = 4))
ht <- ComplexHeatmap::Heatmap(m, name = "z", row_split = rep(1:2, each = 3), top_annotation = ha,
                              column_title = "Samples")
write_sheet(suppressMessages(gloss(ht))$substrate, "ex-heatmap", out)

# ggplot: boxplots with outliers over a band at typed values that spans the
# panel (the two kinds the first three figures do not draw: data / box and
# reference / reference area)
p <- ggplot2::ggplot(d, ggplot2::aes(factor(cyl), mpg)) +
  ggplot2::annotate("rect", xmin = -Inf, xmax = Inf, ymin = 20, ymax = 25, alpha = 0.2) +
  ggplot2::geom_boxplot() +
  ggplot2::labs(x = "cylinders")
write_sheet(suppressWarnings(gloss(p))$substrate, "ex-box", out)
