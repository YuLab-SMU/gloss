# gloss bench figure tree-074
# source: ggtree::ggtree-format-painter (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: %<%
### Title: %<%
### Aliases: %<%

### ** Examples

library("ggplot2")
nwk <- system.file("extdata", "sample.nwk", package="treeio")
tree <- read.tree(nwk)
p <- ggtree(tree) + geom_tippoint(color="#b5e521", alpha=1/4, size=10)
p %<% rtree(30)
