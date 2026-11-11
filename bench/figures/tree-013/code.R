# gloss bench figure tree-013
# source: ggtree::geom_tiplab2 (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: geom_tiplab2
### Title: geom_tiplab2
### Aliases: geom_tiplab2

### ** Examples

library(ggtree)
set.seed(123)
tr <- rtree(10)
ggtree(tr, layout = "circular") + geom_tiplab2()
