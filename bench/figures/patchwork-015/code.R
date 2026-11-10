# gloss bench figure patchwork-015
# source: patchwork::guide_area (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(patchwork)
# ---- chunk 1 ----
### Name: guide_area
### Title: Add an area to hold collected guides
### Aliases: guide_area

### ** Examples

library(ggplot2)
p1 <- ggplot(mtcars) + geom_point(aes(mpg, disp, colour = factor(gear)))
p2 <- ggplot(mtcars) + geom_boxplot(aes(gear, disp, group = gear))
p3 <- ggplot(mtcars) + geom_bar(aes(gear)) + facet_wrap(~cyl)

# Guides are by default kept beeside their plot
p1 + p2 + p3
