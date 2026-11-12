# gloss bench figure exts-010
# source: ggstance (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggstance)
# ---- chunk 1 ----
### Name: geom_boxploth
### Title: Horizontal box and whiskers plot.
### Aliases: geom_boxploth

### ** Examples

library("ggplot2")

# With ggplot2 we need coord_flip():
ggplot(mpg, aes(class, hwy, fill = factor(cyl))) +
  geom_boxplot() +
  coord_flip()

# With ggstance we use the h-suffixed version:
ggplot(mpg, aes(hwy, class, fill = factor(cyl))) +
  geom_boxploth()
