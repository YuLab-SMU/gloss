# gloss bench figure tree-012
# source: ggtree::geom_rootpoint (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: geom_rootpoint
### Title: geom_rootpoint
### Aliases: geom_rootpoint

### ** Examples

library(ggtree)
tr <- rtree(10)
##  add root point
ggtree(tr) + geom_rootpoint()
