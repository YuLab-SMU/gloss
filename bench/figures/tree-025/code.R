# gloss bench figure tree-025
# source: ggtree::rotate_tree (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: rotate_tree
### Title: rotate_tree
### Aliases: rotate_tree

### ** Examples

tree <- rtree(15)
p <- ggtree(tree) + geom_tiplab()
p2 <- open_tree(p, 180)
rotate_tree(p2, 180)
