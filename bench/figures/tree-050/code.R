# gloss bench figure tree-050
# source: ggtree::revts (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: revts
### Title: revts
### Aliases: revts

### ** Examples

tr <- rtree(10)
p <- ggtree(tr) + theme_tree2()
p2 <- revts(p) 
p2 + scale_x_continuous(labels=abs)
