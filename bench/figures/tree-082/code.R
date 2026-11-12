# gloss bench figure tree-082
# source: ggtree::geom_tippoint (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: geom_tippoint
### Title: geom_tippoint
### Aliases: geom_tippoint

### ** Examples

library(ggtree)
tr<- rtree(15)
x <- ggtree(tr)
x + geom_tippoint()
