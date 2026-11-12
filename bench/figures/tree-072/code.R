# gloss bench figure tree-072
# source: ggtree::geom_cladelab (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: geom_cladelab
### Title: geom_cladelab
### Aliases: geom_cladelab

### ** Examples

set.seed(2015-12-21)
tree <- rtree(30)
data <- data.frame(id=c(34, 56),
                   annote=c("another clade", "long clade names"),
                   image=c("7fb9bea8-e758-4986-afb2-95a2c3bf983d",
                           "0174801d-15a6-4668-bfe0-4c421fbe51e8"),
                   group=c("A", "B"),
                   offset=c(0.1, 0.1),
                   offset.text=c(0.1, 0.2))

p <- ggtree(tree) + xlim(NA, 6)

p + geom_cladelab(node=45, label="test label") +
    geom_cladelab(node=34, label="another clade")
p2 <- p + geom_cladelab(data=data,
                        mapping=aes(
                             node=id, 
                             label=annote, 
                             image=image,
                             color=group, 
                             offset=offset
                        ),
                        geom="shadowtext",
                        hjust=0.5,
                        align=TRUE,
                        horizontal=FALSE,
                        angle=90,
                        show.legend = FALSE
                       ) 
p2
