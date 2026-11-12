# gloss bench figure tree-052
# source: ggtree::ggexpand (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: hexpand
### Title: hexpand
### Aliases: hexpand vexpand ggexpand

### ** Examples

x <- rtree(20)
x$tip.label <- paste0('RRRRREEEEEAAAAALLLLLYYYYY_Long_Lable_', x$tip.label)
p1 <- ggtree(x) + geom_tiplab()
p1 + ggexpand(1.5, side = "h")
