# gloss bench figure exts-018
# source: ggbreak (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggbreak)
# ---- chunk 1 ----
### Name: scale_x_cut
### Title: scale_x_cut
### Aliases: scale_x_cut scale_y_cut

### ** Examples

library(ggplot2)
library(ggbreak)
set.seed(2019-01-19)
d <- data.frame(
     x = 1:20,
     y = c(rnorm(5) + 4, rnorm(5) + 20, rnorm(5) + 5, rnorm(5) + 22)
 )
p <- ggplot(d, aes(x, y)) + geom_col()
p + scale_y_cut(breaks=c(7, 18), which=c(1, 3), scales=c(3, 0.5))
