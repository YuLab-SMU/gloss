# gloss bench figure tree-039
# source: ggtreeDendro (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----style, echo=FALSE, results="asis", message=FALSE-------------------------
knitr::opts_chunk$set(tidy = FALSE,
                      warning = FALSE,
                      message = FALSE)
library(yulab.utils)                      

# ---- chunk 2 ----
## -----------------------------------------------------------------------------
library(ggtree)
library(ggtreeDendro)
library(aplot)
scale_color_subtree <- ggtreeDendro::scale_color_subtree

# ---- chunk 3 ----
## ----fig.width=16, fig.height=6-----------------------------------------------
d <- dist(USArrests)

hc <- hclust(d, "ave")
den <- as.dendrogram(hc)

p1 <- autoplot(hc) + geom_tiplab()
p2 <- autoplot(den)
plot_list(p1, p2, ncol=2)

# ---- chunk 4 ----
## ----fig.width=8, fig.height=8------------------------------------------------
library("mdendro")
lnk <- linkage(d, digits = 1, method = "complete")
autoplot(lnk, layout = 'circular') + geom_tiplab() + 
  scale_color_subtree(4) + theme_tree()

# ---- chunk 5 ----
## ----fig.width=16, height=6---------------------------------------------------
library(cluster)
x1 <- agnes(mtcars)
x2 <- diana(mtcars)

p1 <- autoplot(x1) + geom_tiplab()
p2 <- autoplot(x2) + geom_tiplab()
plot_list(p1, p2, ncol=2)
