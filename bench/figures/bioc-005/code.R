# gloss bench figure bioc-005
# source: Voyager (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>", fig.align = "center"
)

# ---- chunk 2 ----
## ----eval=FALSE---------------------------------------------------------------
# # if (!requireNamespace("BiocManager")) install.packages("BiocManager") # [bench: install call removed]
# # BiocManager::install("Voyager") # [bench: install call removed]
# # Devel version
# # # install.packages("remotes") # [bench: install call removed]
# # remotes::install_github("pachterlab/Voyager") # [bench: install call removed]

# ---- chunk 3 ----
## ----message=FALSE------------------------------------------------------------
library(SFEData)
library(SpatialFeatureExperiment)
library(SpatialExperiment)
library(ggplot2)
library(Voyager)
library(scater)
library(scran)
library(pheatmap)

# ---- chunk 4 ----
## -----------------------------------------------------------------------------
if (!file.exists("tissue_lowres_5a.jpeg")) {
    download.file("file://data/tissue_lowres_5a.jpeg",
                  destfile = "tissue_lowres_5a.jpeg")
}

# ---- chunk 5 ----
## -----------------------------------------------------------------------------
knitr::include_graphics("tissue_lowres_5a.jpeg")

# ---- chunk 6 ----
## -----------------------------------------------------------------------------
sfe <- McKellarMuscleData()

# ---- chunk 7 ----
## -----------------------------------------------------------------------------
sfe <- addImg(sfe, imageSource = "tissue_lowres_5a.jpeg", sample_id = "Vis5A", 
              image_id = "lowres", scale_fct = 1024/22208)

# ---- chunk 8 ----
## -----------------------------------------------------------------------------
sfe <- mirrorImg(sfe, sample_id = "Vis5A", image_id = "lowres")

# ---- chunk 9 ----
## -----------------------------------------------------------------------------
# Only use spots in tissue here
sfe <- sfe[,colData(sfe)$in_tissue]
sfe <- logNormCounts(sfe)
sfe

# ---- chunk 10 ----
## -----------------------------------------------------------------------------
colGraph(sfe, "visium") <- findVisiumGraph(sfe)

# ---- chunk 11 ----
## -----------------------------------------------------------------------------
features_use <- c("Myh1", "Myh2")

# ---- chunk 12 ----
## -----------------------------------------------------------------------------
sfe <- runUnivariate(sfe, type = "moran", features = features_use, 
                     colGraphName = "visium", swap_rownames = "symbol")
# Look at the results
rowData(sfe)[rowData(sfe)$symbol %in% features_use,]

# ---- chunk 13 ----
## -----------------------------------------------------------------------------
sfe <- runUnivariate(sfe, type = "localG", features = features_use,
                     colGraphName = "visium", include_self = TRUE, 
                     swap_rownames = "symbol")
# Look at the results
head(localResults(sfe, name = "localG")[[1]])

# ---- chunk 14 ----
## -----------------------------------------------------------------------------
gs <- modelGeneVar(sfe)
hvgs <- getTopHVGs(gs, fdr.threshold = 0.01)

# ---- chunk 15 ----
## -----------------------------------------------------------------------------
res <- calculateBivariate(sfe, "lee", hvgs)

# ---- chunk 16 ----
## ----fig.width=6, fig.height=6------------------------------------------------
pheatmap(res, color = scales::viridis_pal()(256), cellwidth = 1, cellheight = 1,
         show_rownames = FALSE, show_colnames = FALSE)

# ---- chunk 17 ----
## -----------------------------------------------------------------------------
hvgs2 <- getTopHVGs(gs, n = 1000)
sfe <- runMultivariate(sfe, "multispati", colGraphName = "visium", subset_row = hvgs2,
                       nfposi = 10, nfnega = 10)

# ---- chunk 18 ----
## -----------------------------------------------------------------------------
plotSpatialFeature(sfe, c("nCounts", "Myh1"), colGeometryName = "spotPoly", 
                   annotGeometryName = "myofiber_simplified", 
                   aes_use = "color", linewidth = 0.5, fill = NA,
                   annot_aes = list(fill = "area"), swap_rownames = "symbol")
