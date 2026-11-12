# gloss bench figure tree-045
# source: cardelino (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----knitr-options, echo=FALSE, message=FALSE, warning=FALSE------------------
## To render an HTML version that works nicely with github and web pages, do:
## rmarkdown::render("vignettes/vignette-cloneid.Rmd", "all")
library(knitr)
opts_chunk$set(fig.align = 'center', fig.width = 6, fig.height = 5, dev = 'png',
    warning = FALSE, error = FALSE, message = FALSE)
library(ggplot2)
library(BiocStyle)
theme_set(theme_bw(12))

# ---- chunk 2 ----
## ----load-pkg-----------------------------------------------------------------
library(ggplot2)
library(cardelino)

# ---- chunk 3 ----
## ----read-vcf-data------------------------------------------------------------
vcf_file <- system.file("extdata", "cellSNP.cells.vcf.gz", 
                        package = "cardelino")
input_data <- load_cellSNP_vcf(vcf_file)

# ---- chunk 4 ----
## ----allele-frequency, , fig.height = 3, fig.width = 5------------------------
AF <- as.matrix(input_data$A / input_data$D)

p = pheatmap::pheatmap(AF, cluster_rows=FALSE, cluster_cols=FALSE,
                   show_rownames = TRUE, show_colnames = TRUE,
                   labels_row='77 cells', labels_col='112 SNVs',
                   angle_col=0, angle_row=0)

# ---- chunk 5 ----
## ----read-canopy-data---------------------------------------------------------
canopy_res <- readRDS(system.file("extdata", "canopy_results.coveraged.rds", 
                                  package = "cardelino"))
Config <- canopy_res$tree$Z

# ---- chunk 6 ----
## ----correct-variant-ids------------------------------------------------------
rownames(Config) <- gsub(":", "_", rownames(Config))

# ---- chunk 7 ----
## ----plot-tre-----------------------------------------------------------------
plot_tree(canopy_res$tree, orient = "v")
