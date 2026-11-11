# gloss bench figure tree-073
# source: ggtree::geom_striplab (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: geom_striplab
### Title: geom_striplab
### Aliases: geom_striplab

### ** Examples

set.seed(123)
tr <- rtree(10)
dt <- data.frame(ta1=c("t5", "t1"), ta2=c("t6", "t3"), group=c("A", "B"))
p <- ggtree(tr) + geom_tiplab()
p2 <- p + 
      geom_striplab(
        data = dt,
        mapping = aes(taxa1 = ta1, taxa2 = ta2, 
                      label = group, color=group),
        align = TRUE,
        show.legend = FALSE
      )
p2
