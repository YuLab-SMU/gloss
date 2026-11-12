# gloss bench figure tree-078
# source: ggtree::geom_tiplab (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: geom_tiplab
### Title: geom_tiplab
### Aliases: geom_tiplab

### ** Examples

require(ape)
tr <- rtree(10)
ggtree(tr) + geom_tiplab()
