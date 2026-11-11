# gloss bench figure tree-058
# source: systemPipeTools (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----style, echo = FALSE, results = 'asis', eval=TRUE-------------------------
BiocStyle::markdown()
options(width = 80, max.print = 1000)
knitr::opts_chunk$set(
  eval = as.logical(Sys.getenv("KNITR_EVAL", "TRUE")),
  cache = as.logical(Sys.getenv("KNITR_CACHE", "TRUE")),
  tidy.opts = list(width.cutoff = 80), tidy = TRUE
)

# ---- chunk 2 ----
## ----setup, echo=FALSE, messages=FALSE, warnings=FALSE, eval=TRUE-------------
suppressPackageStartupMessages({
    library(systemPipeTools)
    library(systemPipeR)
})

# ---- chunk 3 ----
## ----install, eval=FALSE------------------------------------------------------
# if (!requireNamespace("BiocManager", quietly = TRUE))
# #   install.packages("BiocManager") # [bench: install call removed]
# # BiocManager::install("systemPipeTools") # [bench: install call removed]
# # BiocManager::install("systemPipeR") # [bench: install call removed]

# ---- chunk 4 ----
## ----documentation, eval=FALSE------------------------------------------------
# library("systemPipeTools")  # Loads the package
# library(help = "systemPipeTools")  # Lists package info
# vignette("systemPipeTools")  # Opens vignette

# ---- chunk 5 ----
## ----targets_counts, eval=TRUE------------------------------------------------
## Targets file
targetspath <- system.file("extdata", "targets.txt", package = "systemPipeR")
targets <- read.delim(targetspath, comment = "#")
cmp <- systemPipeR::readComp(file = targetspath, format = "matrix", 
                             delim = "-")
## Count table file
countMatrixPath <- system.file("extdata", "countDFeByg.xls",
                               package = "systemPipeR")
countMatrix <- read.delim(countMatrixPath, row.names = 1)
showDT(countMatrix)

# ---- chunk 6 ----
## ----exploreDDS, eval=TRUE, warning=FALSE-------------------------------------
exploredds <- exploreDDS(countMatrix, targets, cmp = cmp[[1]], preFilter = NULL, 
                         transformationMethod = "rlog")
exploredds

# ---- chunk 7 ----
## ----exploreDDSplot, eval=FALSE, warning=FALSE, message=FALSE-----------------
# exploreDDSplot(countMatrix, targets, cmp = cmp[[1]], preFilter = NULL,
#                samples = c("M12A", "M12A", "A12A", "A12A"),
#                scattermatrix = TRUE)

# ---- chunk 8 ----
## ----hclustplot, eval=TRUE----------------------------------------------------
hclustplot(exploredds, method = "spearman")
