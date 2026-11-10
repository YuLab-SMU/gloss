# gloss bench figure patchwork-006
# source: patchwork::wrap_ggplot_grob (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(patchwork)
# ---- chunk 1 ----
### Name: wrap_ggplot_grob
### Title: Make a gtable created from a ggplot object patchwork compliant
### Aliases: wrap_ggplot_grob

### ** Examples

library(grid)
library(gtable)
library(ggplot2)

p1 <- ggplot(mtcars) + geom_point(aes(mpg, disp)) + ggtitle('disp and mpg seems connected')
p2 <- ggplot(mtcars) + geom_boxplot(aes(gear, disp, group = gear))

# Convert p2 so we can add new stuff to it
p2_table <- ggplotGrob(p2)
stamp <- textGrob('TOP SECRET', rot = 35,
  gp = gpar(fontsize = 72, fontface = 'bold')
)
p2_table <- gtable_add_grob(p2_table, stamp,
  t = 1, l = 1, b = nrow(p2_table), r = ncol(p2_table)
)

# Adding it directly will loose alignment
p1 + p2_table
