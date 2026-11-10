# gloss bench figure patchwork-004
# source: patchwork::wrap_plots (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(patchwork)
# ---- chunk 1 ----
### Name: wrap_plots
### Title: Wrap plots into a patchwork
### Aliases: wrap_plots

### ** Examples

library(ggplot2)

p1 <- ggplot(mtcars) + geom_point(aes(mpg, disp))
p2 <- ggplot(mtcars) + geom_boxplot(aes(gear, disp, group = gear))
p3 <- ggplot(mtcars) + geom_bar(aes(gear)) + facet_wrap(~cyl)
p4 <- ggplot(mtcars) + geom_bar(aes(carb))
p5 <- ggplot(mtcars) + geom_violin(aes(cyl, mpg, group = cyl))

# Either add the plots as single arguments
wrap_plots(p1, p2, p3, p4, p5)

# Or add them as a list...
plots <- list(p1, p2, p3, p4, p5)
wrap_plots(plots)
