# gloss bench figure exts-020
# source: ggeasy (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggeasy)
# ---- chunk 1 ----
### Name: easy_add_legend_title
### Title: Easily add legend title(s)
### Aliases: easy_add_legend_title

### ** Examples


library(ggplot2)

# Add legend title to a specific aesthetic
ggplot(mtcars, aes(wt, mpg, colour = cyl, size = hp)) +
  geom_point() + easy_add_legend_title(col = "Number of Cylinders")
