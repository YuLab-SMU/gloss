# gloss bench figure patchwork-014
# source: patchwork::area (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(patchwork)
# ---- chunk 1 ----
### Name: area
### Title: Specify a plotting area in a layout
### Aliases: area

### ** Examples

library(ggplot2)

p1 <- ggplot(mtcars) + geom_point(aes(mpg, disp))
p2 <- ggplot(mtcars) + geom_boxplot(aes(gear, disp, group = gear))
p3 <- ggplot(mtcars) + geom_bar(aes(gear)) + facet_wrap(~cyl)

layout <- c(
  area(1, 1),
  area(1, 3, 3),
  area(3, 1, 3, 2)
)

# Show the layout to make sure it looks as it should
plot(layout)

# Apply it to a patchwork
p1 + p2 + p3 + plot_layout(design = layout)
