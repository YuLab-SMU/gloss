# gloss bench figure tree-017
# source: ggtree::rotate (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: rotate
### Title: rotate
### Aliases: rotate

### ** Examples

x <- rtree(15)
p <- ggtree(x) + geom_tiplab()
rotate(p, 17)
