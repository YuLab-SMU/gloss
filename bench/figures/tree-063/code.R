# gloss bench figure tree-063
# source: ggtree::viewClade (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: viewClade
### Title: viewClade
### Aliases: viewClade

### ** Examples

x <- rtree(15)
p <- ggtree(x) + geom_tiplab()
viewClade(p, 18, xmax_adjust = 0.)
