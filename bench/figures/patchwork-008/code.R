# gloss bench figure patchwork-008
# source: patchwork::inset_element (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(patchwork)
# ---- chunk 1 ----
### Name: inset_element
### Title: Create an inset to be added on top of the previous plot
### Aliases: inset_element

### ** Examples

library(ggplot2)
p1 <- ggplot(mtcars) + geom_point(aes(mpg, disp))
p2 <- ggplot(mtcars) + geom_boxplot(aes(gear, disp, group = gear))

# Basic use
p1 + inset_element(p2, 0.6, 0.6, 1, 1)

# Align to the full area instead
p1 + inset_element(p2, 0, 0.6, 0.4, 1, align_to = 'full')

# Grobs and other objects can be added as insets as well
p1 + inset_element(grid::circleGrob(), 0.4, 0.4, 0.6, 0.6)

if (requireNamespace('png', quietly = TRUE)) {
  logo <- system.file('help', 'figures', 'logo.png', package = 'patchwork')
  logo <- png::readPNG(logo, native = TRUE)
  p1 + inset_element(logo, 0.8, 0.8, 1, 1, align_to = 'full')
}

# Just as expected insets are still amenable to changes after the fact
p1 +
  inset_element(p2, 0.6, 0.6, 1, 1) +
  theme_classic()

# Tagging also continues to work as expected
p1 +
  inset_element(p2, 0.6, 0.6, 1, 1) +
  plot_annotation(tag_levels = '1')

# but can be turned off, like for wrapped plots
p1 +
  inset_element(p2, 0.6, 0.6, 1, 1, ignore_tag = TRUE) +
  plot_annotation(tag_levels = '1')
