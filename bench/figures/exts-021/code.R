# gloss bench figure exts-021
# source: gglm (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(gglm)
# ---- chunk 1 ----
### Name: stat_normal_qq
### Title: stat_normal_qq
### Aliases: stat_normal_qq

### ** Examples

data(mtcars)
model <- lm(mpg ~ cyl + disp + hp, data = mtcars)
ggplot2::ggplot(data = model) + stat_normal_qq()
