# gloss bench figure exts-002
# source: ggdibbler (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggdibbler)
# ---- chunk 1 ----
### Name: geom_hex_sample
### Title: Uncertain hexagonal heatmap of 2d bin counts
### Aliases: geom_hex_sample StatBinhexSample stat_bin_hex_sample
### Keywords: datasets

### ** Examples

library(ggplot2)
d <- ggplot(smaller_diamonds, aes(carat, price))
d + geom_hex()

b <- ggplot(smaller_uncertain_diamonds, aes(carat, price))
b + geom_hex_sample(alpha=0.15)
