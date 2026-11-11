# gloss bench figure tree-030
# source: ggtree::geom_balance (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: geom_balance
### Title: geom_balance
### Aliases: geom_balance

### ** Examples

library(ggtree)
set.seed(123)
tr<- rtree(15)
x <- ggtree(tr)
x + geom_balance(17)
