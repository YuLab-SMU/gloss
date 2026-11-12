# gloss bench figure tree-038
# source: ggtree::open_tree (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: open_tree
### Title: open_tree
### Aliases: open_tree

### ** Examples

tree <- rtree(15)
p <- ggtree(tree) + geom_tiplab()
open_tree(p, 180)
