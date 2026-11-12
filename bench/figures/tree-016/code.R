# gloss bench figure tree-016
# source: ggtree::xlim_tree (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: xlim_tree
### Title: xlim_tree
### Aliases: xlim_tree

### ** Examples

x <- rtree(30)
p <- ggtree(x) + geom_tiplab()
d <- data.frame(label = x$tip.label, 
                value = rnorm(30))
p2 <- p + geom_facet(panel = "Dot", data = d, 
            geom = geom_point, mapping = aes(x = value))
p2 + xlim_tree(6)
