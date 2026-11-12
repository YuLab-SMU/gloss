# gloss bench figure patchwork-018
# source: patchwork::plot_spacer (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(patchwork)
# ---- chunk 1 ----
### Name: plot_spacer
### Title: Add a completely blank area
### Aliases: plot_spacer

### ** Examples

library(ggplot2)

p1 <- ggplot(mtcars) + geom_point(aes(mpg, disp))
p2 <- ggplot(mtcars) + geom_boxplot(aes(gear, disp, group = gear))

p1 + plot_spacer() + p2
