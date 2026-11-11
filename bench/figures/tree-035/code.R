# gloss bench figure tree-035
# source: sitePath (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

# ---- chunk 2 ----
## ----import_tree, message=FALSE-----------------------------------------------
library(sitePath)

tree_file <- system.file("extdata", "ZIKV.newick", package = "sitePath")
tree <- read.tree(tree_file)

# ---- chunk 3 ----
## ----bad_tree_example, echo=FALSE---------------------------------------------
bad_tree <- read.tree(system.file("extdata", "WNV.newick", package = "sitePath"))

ggtree::ggtree(bad_tree) + ggplot2::ggtitle("Do not use a tree like this")

# ---- chunk 4 ----
## ----add_alignment, message=FALSE---------------------------------------------
alignment_file <- system.file("extdata", "ZIKV.fasta", package = "sitePath")

options(list("cl.cores" = 1)) # Set this bigger than 1 to use multiprocessing

paths <- addMSA(tree, msaPath = alignment_file, msaFormat = "fasta")

# ---- chunk 5 ----
## ----sneakPeek_plot-----------------------------------------------------------
preassessment <- sneakPeek(paths, makePlot = TRUE)

# ---- chunk 6 ----
## ----get_lineagePath----------------------------------------------------------
paths <- lineagePath(preassessment, 18)
paths

# ---- chunk 7 ----
## ----plot_paths---------------------------------------------------------------
plot(paths)

# ---- chunk 8 ----
## ----min_entropy--------------------------------------------------------------
minEntropy <- sitesMinEntropy(paths)

# ---- chunk 9 ----
## ----find_fixations-----------------------------------------------------------
fixations <- fixationSites(minEntropy)
fixations

# ---- chunk 10 ----
## -----------------------------------------------------------------------------
allSites <- allSitesName(fixations)
allSites

# ---- chunk 11 ----
## ----get_sitePath-------------------------------------------------------------
sp <- extractSite(fixations, 139)

# ---- chunk 12 ----
## ----get_tipNames-------------------------------------------------------------
extractTips(fixations, 139)

# ---- chunk 13 ----
## ----plot_sitePath------------------------------------------------------------
plot(sp)
plotSingleSite(fixations, 139)

# ---- chunk 14 ----
## ----plot_fixations-----------------------------------------------------------
plot(fixations)
