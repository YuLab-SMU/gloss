# gloss bench figure patchwork-012
# source: patchwork::plot_annotation (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(patchwork)
# ---- chunk 1 ----
### Name: plot_annotation
### Title: Annotate the final patchwork
### Aliases: plot_annotation

### ** Examples

library(ggplot2)

p1 <- ggplot(mtcars) + geom_point(aes(mpg, disp))
p2 <- ggplot(mtcars) + geom_boxplot(aes(gear, disp, group = gear))
p3 <- ggplot(mtcars) + geom_bar(aes(gear)) + facet_wrap(~cyl)

# Add title, etc. to a patchwork
p1 + p2 + plot_annotation('This is a title', caption = 'made with patchwork')

# Change styling of patchwork elements
p1 + p2 +
  plot_annotation(
    title = 'This is a title',
    caption = 'made with patchwork',
    theme = theme(plot.title = element_text(size = 16))
  )

# Add tags to plots
p1 / (p2 | p3) +
  plot_annotation(tag_levels = 'A')
