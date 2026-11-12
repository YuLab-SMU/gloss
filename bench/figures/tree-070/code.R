# gloss bench figure tree-070
# source: ggtreeExtra::position_jitterx (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtreeExtra)
# ---- chunk 1 ----
### Name: position_jitterx
### Title: Jitter points to avoid overplotting, and the whole points can be
###   shifted vertically or horizontally
### Aliases: position_jitterx

### ** Examples

library(ggtree)
library(treeio)
library(ggplot2)
set.seed(1024)
tr <- rtree(10)

df <- data.frame(id=tr$tip.label, group=rep(c("A", "B"),5))
dat <- data.frame(id=rep(tr$tip.label, 8), value=rnorm(80, 0.5, 0.15))
dt <- merge(dat, df, by.x="id", by.y="id")
p1 <- ggtree(tr) %<+% df +
      geom_tiplab(
          align=TRUE,
          linesize=.1,
          size=3
      ) 

gf1 <- geom_fruit(data=dat,
                  geom=geom_boxplot,
                  mapping=aes(x=value, y=id),
                  orientation="y",
                  offset=0.1,
                  pwidth=0.9

         )
set.seed(1024)
gf2 <- geom_fruit(
          data=dat,
          geom=geom_point,
          mapping=aes(x=value, y=id, color=group),
          offset=0.1,
          pwidth=0.9,
          position= position_jitterx(height=0.3),
          axis.params=list(axis="x", text.size=2),
          grid.params=list()
          )

p2 <- p1 + geom_fruit_list(gf1, gf2)
p2
