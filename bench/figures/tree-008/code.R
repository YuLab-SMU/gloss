# gloss bench figure tree-008
# source: ggtree::collapse (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: collapse.ggtree
### Title: collapse-ggtree
### Aliases: collapse.ggtree

### ** Examples

x <- rtree(15)
p <- ggtree(x) + geom_tiplab()
p
