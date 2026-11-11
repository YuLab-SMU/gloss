# gloss bench figure tree-079
# source: miaViz (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
    collapse = TRUE,
    comment = "#>"
)
knitr::opts_chunk$set(dev = "png", dev.args = list(type = "cairo-png")) 

# ---- chunk 2 ----
## ----install, eval=FALSE------------------------------------------------------
# if (!requireNamespace("BiocManager", quietly = TRUE))
# #     install.packages("BiocManager") # [bench: install call removed]
# # BiocManager::install("miaViz") # [bench: install call removed]

# ---- chunk 3 ----
## ----setup, message=FALSE-----------------------------------------------------
library(miaViz)
library(scater)
data(GlobalPatterns, package = "mia")

# ---- chunk 4 ----
## -----------------------------------------------------------------------------
plotExpression(GlobalPatterns, features = "549322", assay.type = "counts")

# ---- chunk 5 ----
## -----------------------------------------------------------------------------
GlobalPatterns <- transformAssay(GlobalPatterns, method = "relabundance")

# ---- chunk 6 ----
## -----------------------------------------------------------------------------
plotAbundance(GlobalPatterns, rank = "Kingdom", assay.type = "relabundance")

# ---- chunk 7 ----
## -----------------------------------------------------------------------------
GlobalPatterns_king <- agglomerateByRank(GlobalPatterns, "Kingdom")
plotAbundance(GlobalPatterns_king, assay.type = "relabundance")

# ---- chunk 8 ----
## -----------------------------------------------------------------------------
prev_phylum <- getPrevalent(GlobalPatterns, rank = "Phylum", detection = 0.01)

# ---- chunk 9 ----
## -----------------------------------------------------------------------------
plotAbundance(
    GlobalPatterns[rowData(GlobalPatterns)$Phylum %in% prev_phylum],
    rank = "Phylum",
    assay.type = "relabundance")

# ---- chunk 10 ----
## -----------------------------------------------------------------------------
library(patchwork)
plots <- plotAbundance(
    GlobalPatterns[rowData(GlobalPatterns)$Phylum %in% prev_phylum],
    features = "SampleType",
    rank = "Phylum",
    assay.type = "relabundance")
plots$abundance / plots$SampleType + plot_layout(heights = c(9, 1))

# ---- chunk 11 ----
## -----------------------------------------------------------------------------
plotFeaturePrevalence(
    GlobalPatterns, rank = "Phylum", detections = c(0, 0.001, 0.01, 0.1, 0.2))

# ---- chunk 12 ----
## -----------------------------------------------------------------------------
plotPrevalentAbundance(GlobalPatterns, rank = "Family", colour_by = "Phylum") +
    scale_x_log10()

# ---- chunk 13 ----
## -----------------------------------------------------------------------------
plotPrevalence(
    GlobalPatterns, rank = "Phylum",
    detections = c(0.01, 0.1, 1, 2, 5, 10, 20)/100,
    prevalences = seq(0.1, 1, 0.1))

# ---- chunk 14 ----
## ----message=FALSE------------------------------------------------------------
library(scater)
library(mia)

# ---- chunk 15 ----
## -----------------------------------------------------------------------------
altExp(GlobalPatterns,"Genus") <- agglomerateByRank(GlobalPatterns,"Genus")
altExp(GlobalPatterns,"Genus") <- addPerFeatureQC(
    altExp(GlobalPatterns,"Genus"))
rowData(altExp(GlobalPatterns,"Genus"))$log_mean <- log(
    rowData(altExp(GlobalPatterns,"Genus"))$mean)
rowData(altExp(GlobalPatterns,"Genus"))$detected <- rowData(
    altExp(GlobalPatterns,"Genus"))$detected / 100
top_taxa <- getTop(
    altExp(GlobalPatterns,"Genus"),
    method="mean",
    top=100L,
    assay.type="counts")

# ---- chunk 16 ----
## ----plot1, fig.cap="Tree plot using ggtree with tip labels decorated by mean abundance (colour) and prevalence (size)"----
plotRowTree(
    altExp(GlobalPatterns,"Genus")[top_taxa,], tip_colour_by = "log_mean",
    tip_size_by = "detected")

# ---- chunk 17 ----
## ----plot2, fig.cap="Tree plot using ggtree with tip labels decorated by mean abundance (colour) and prevalence (size). Tip labels of the tree are shown as well."----
plotRowTree(
    altExp(GlobalPatterns,"Genus")[top_taxa,],
    tip_colour_by = "log_mean", tip_size_by = "detected", show_label = TRUE)

# ---- chunk 18 ----
## ----plot3, fig.cap="Tree plot using ggtree with tip labels decorated by mean abundance (colour) and prevalence (size). Selected node and tip labels are shown."----
labels <- c("Genus:Providencia", "Genus:Morganella", "0.961.60")
plotRowTree(
    altExp(GlobalPatterns,"Genus")[top_taxa,],
    tip_colour_by = "log_mean",
    tip_size_by = "detected",
    show_label = labels,
    layout="rectangular")
