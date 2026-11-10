# gloss bench figure patchwork-001
# source: patchwork::wrap_elements (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(patchwork)
# ---- chunk 1 ----
### Name: wrap_elements
### Title: Wrap arbitrary graphics in a patchwork-compliant patch
### Aliases: wrap_elements

### ** Examples

library(ggplot2)
library(grid)

# Combine grobs with each other
wrap_elements(panel = textGrob('Here are some text')) +
  wrap_elements(
    panel = rectGrob(gp = gpar(fill = 'steelblue')),
    full = rectGrob(gp = gpar(fill = 'goldenrod'))
  )
