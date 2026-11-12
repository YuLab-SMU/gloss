# gloss bench figure tree-068
# source: ggtree::xlim_expand (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: xlim_expand
### Title: xlim_expand
### Aliases: xlim_expand

### ** Examples

x <- rtree(30)
p <- ggtree(x) + geom_tiplab()
d <- data.frame(label = x$tip.label, 
                value = rnorm(30))
p2 <- p + geom_facet(panel = "Dot", data = d, 
            geom = geom_point, mapping = aes(x = value))
p2 + xlim_expand(c(-10, 10), 'Dot')
