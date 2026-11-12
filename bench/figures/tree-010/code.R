# gloss bench figure tree-010
# source: ggtree::theme_tree (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: theme_tree
### Title: theme_tree
### Aliases: theme_tree

### ** Examples

require(ape)
tr <- rtree(10)
ggtree(tr) + theme_tree()
