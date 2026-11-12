# gloss bench figure tree-085
# source: tanggle (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
    collapse = TRUE,
    comment = "#>"
)
suppressPackageStartupMessages({
    library(tanggle, quietly=TRUE)
    library(phangorn, quietly=TRUE)
    library(ggtree, quietly=TRUE)
})

# ---- chunk 2 ----
## ----install-bioc, eval=FALSE-------------------------------------------------
# if (!requireNamespace("BiocManager", quietly = TRUE))
# #     install.packages("BiocManager") # [bench: install call removed]
# 
# # BiocManager::install("tanggle") # [bench: install call removed]

# ---- chunk 3 ----
## ----install-gh, eval=FALSE---------------------------------------------------
# if (!requireNamespace("remotes", quietly=TRUE))
# #   install.packages("remotes") # [bench: install call removed]
# # remotes::install_github("KlausVigo/tanggle") # [bench: install call removed]

# ---- chunk 4 ----
## ----install-ggtree, eval=FALSE-----------------------------------------------
# # remotes::install_github("YuLab-SMU/ggtree") # [bench: install call removed]

# ---- chunk 5 ----
## ----load-pkg, echo=TRUE, results='hide'--------------------------------------
library(tanggle)
library(phangorn)
library(ggtree)

# ---- chunk 6 ----
## -----------------------------------------------------------------------------
fdir <- system.file("extdata/trees", package = "phangorn")
Nnet <- phangorn::read.nexus.networx(file.path(fdir,"woodmouse.nxs"))

# ---- chunk 7 ----
## -----------------------------------------------------------------------------
p <- ggsplitnet(Nnet) + geom_tiplab2()
p

# ---- chunk 8 ----
## -----------------------------------------------------------------------------
p <- p + xlim(-0.019, .003) + ylim(-.01,.012) 
p

# ---- chunk 9 ----
## -----------------------------------------------------------------------------
Nnet$translate$label <- seq_along(Nnet$tip.label)

# ---- chunk 10 ----
## -----------------------------------------------------------------------------
ggsplitnet(Nnet) + geom_tiplab2(col = "blue", font = 4, hjust = -0.15) + 
    geom_nodepoint(col = "green", size = 0.25)

# ---- chunk 11 ----
## -----------------------------------------------------------------------------
ggsplitnet(Nnet) + geom_point(aes(shape=isTip, color=isTip), size=2)

# ---- chunk 12 ----
## -----------------------------------------------------------------------------
z <- read.evonet(text = "((1,((2,(3,(4)Y#H1)g)e,(((Y#H1,5)h,6)f)X#H2)c)a,
                 ((X#H2,7)d,8)b)r;")

# ---- chunk 13 ----
## -----------------------------------------------------------------------------
ggevonet(z, layout = "rectangular") + geom_tiplab() + geom_nodelab()
p <- ggevonet(z, layout = "slanted") + geom_tiplab() + geom_nodelab()
p + geom_tiplab(size=3, color="purple")
