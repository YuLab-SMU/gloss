# gloss bench figure heatmap-034
# source: barbieQ (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

# ---- chunk 2 ----
## ----install, eval=FALSE------------------------------------------------------
# ## You can install the released version of barbieQ like so:
# # if (!require("BiocManager", quietly = TRUE))
# # #     install.packages("BiocManager") # [bench: install call removed]
# #
# # # BiocManager::install("barbieQ") # [bench: install call removed]
# 
# ## Alternatively, you can install the development version of barbieQ from GitHub
# # devtools::install_github("Oshlack/barbieQ") # [bench: install call removed]

# ---- chunk 3 ----
## ----library------------------------------------------------------------------
suppressPackageStartupMessages({
  library(barbieQ)
  library(magrittr)
  library(tidyr)
  library(dplyr)
  library(ggplot2)
  library(circlize)
  library(logistf)
  library(igraph)
  library(data.table)
  library(ComplexHeatmap)
  library(limma)
  library(SummarizedExperiment)
  library(S4Vectors)
})
set.seed(2025)

# ---- chunk 4 ----
## ----data---------------------------------------------------------------------
data(monkeyHSPC, package = "barbieQ")

# ---- chunk 5 ----
## ----example, fig.width=8, fig.height=6---------------------------------------
## Passing `object`, `sampleMetadata` and `factorColors` for optional
exampleBBQ <- createBarbieQ(
  object = SummarizedExperiment::assay(monkeyHSPC), 
  sampleMetadata = SummarizedExperiment::colData(monkeyHSPC)$sampleMetadata
)

# ---- chunk 6 ----
## ----update metadata----------------------------------------------------------
updateSampleMetadata <- exampleBBQ$sampleMetadata %>% 
  as.data.frame() %>% 
  select(Celltype, Months) %>% 
  mutate(Phase = ifelse(Months < 6, "early", ifelse(Months >=55, "late", "mid"))) %>% 
  mutate(Celltype = gsub("(Gr).*", "\\1", Celltype))

SummarizedExperiment::colData(exampleBBQ)$sampleMetadata <- S4Vectors::DataFrame(updateSampleMetadata)

exampleBBQ$sampleMetadata

# ---- chunk 7 ----
## ----subset samples-----------------------------------------------------------
flag_sample <- exampleBBQ$sampleMetadata$Phase == "mid"
exampleBBQ <- exampleBBQ[, flag_sample]
exampleBBQ$sampleMetadata

# ---- chunk 8 ----
## ----tag top------------------------------------------------------------------
## Check out minimum group size.
table(exampleBBQ$sampleMetadata$Celltype)
## Tag top Barcodes.
exampleBBQ <- tagTopBarcodes(barbieQ = exampleBBQ, nSampleThreshold = 6)

# ---- chunk 9 ----
## ----tag top v1, fig.width=8, fig.height=6------------------------------------
## visualize contribution of top vs. bottom barcodes
plotBarcodePareto(barbieQ = exampleBBQ) |> plot()

# ---- chunk 10 ----
## ----tag top v2, fig.width=5, fig.height=3------------------------------------
## visualize collective contribution of top vs. bottom barcodes
plotBarcodeSankey(barbieQ = exampleBBQ) |> plot()

# ---- chunk 11 ----
## ----subset top barcodes------------------------------------------------------
flag_barcode <- SummarizedExperiment::rowData(exampleBBQ)$isTopBarcode$isTop
exampleBBQ <- exampleBBQ[flag_barcode,]

# ---- chunk 12 ----
## ----sample pair cor, fig.width=6, fig.height=4-------------------------------
## visualize sample pair wise correlation
plotSamplePairCorrelation(barbieQ = exampleBBQ) |> plot()
