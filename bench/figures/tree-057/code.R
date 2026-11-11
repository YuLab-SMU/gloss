# gloss bench figure tree-057
# source: ggtree::tree-layout (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: layout_rectangular
### Title: layout_rectangular
### Aliases: layout_rectangular layout_circular layout_inward_circular
###   layout_fan layout_dendrogram

### ** Examples

tree <- rtree(20)
p <- ggtree(tree, layout = "circular") + layout_rectangular()
tree <- rtree(20)
p <- ggtree(tree)
p + layout_circular()
tree <- rtree(20)
p <- ggtree(tree)
p + layout_inward_circular(xlim=4) + geom_tiplab(hjust=1)
