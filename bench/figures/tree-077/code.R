# gloss bench figure tree-077
# source: crumblr (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----setup, echo=FALSE, results="hide"------------------------------------------------------------
knitr::opts_chunk$set(
  tidy = FALSE,
  cache = TRUE,
  echo = TRUE,
  dev = c("png", "pdf"),
  package.startup.message = FALSE,
  message = FALSE,
  error = FALSE,
  warning = FALSE
)

options(width = 100)

# ---- chunk 2 ----
## ----install, eval=FALSE--------------------------------------------------------------------------
# # 1) Make sure Bioconductor is installed
# if (!require("BiocManager", quietly = TRUE)) {
# #   install.packages("BiocManager") # [bench: install call removed]
# }
# 
# # 2) Install crumblr and dependencies:
# # From Bioconductor
# # BiocManager::install("crumblr") # [bench: install call removed]

# ---- chunk 3 ----
## ----crumblr--------------------------------------------------------------------------------------
library(crumblr)

# Load cell counts, clustering and metadata
# from Kang, et al. (2018) https://doi.org/10.1038/nbt.4042
data(IFNCellCounts)

# Apply crumblr transformation
# cobj is an EList object compatable with limma workflow
# cobj$E stores transformed values
# cobj$weights stores precision weights
#    corresponding to the regularized inverse variance
cobj <- crumblr(df_cellCounts)

# ---- chunk 4 ----
## ----vp, fig.height=4, fig.width=6----------------------------------------------------------------
library(variancePartition)

# Partition variance into components for Subject (i.e. ind)
#   and stimulation status, and residual variation
form <- ~ (1 | ind) + (1 | StimStatus)
vp <- fitExtractVarPartModel(cobj, form, info)

# Plot variance fractions
fig.vp <- plotPercentBars(vp)
fig.vp

# ---- chunk 5 ----
## ----pca, fig.height=5, fig.width=5---------------------------------------------------------------
library(ggplot2)

# Perform PCA
# use crumblr::standardize() to get values with
# approximately equal sampling variance,
# which is a key property for downstream PCA and clustering analysis.
pca <- prcomp(t(standardize(cobj)))

# merge with metadata
df_pca <- merge(pca$x, info, by = "row.names")

# Plot PCA
#   color by Subject
# 	shape by Stimulated vs unstimulated
ggplot(df_pca, aes(PC1, PC2, color = as.character(ind), shape = StimStatus)) +
  geom_point(size = 3) +
  theme_classic() +
  theme(aspect.ratio = 1) +
  scale_color_discrete(name = "Subject") +
  xlab("PC1") +
  ylab("PC2")

# ---- chunk 6 ----
## ----hclust---------------------------------------------------------------------------------------
heatmap(cobj$E)

# ---- chunk 7 ----
## ----dream----------------------------------------------------------------------------------------
# Use variancePartition workflow to analyze each cell type
# Perform regression on each cell type separately
#  then use eBayes to shrink residual variance
# Also compatible with limma::lmFit()
fit <- dream(cobj, ~ StimStatus + ind, info)
fit <- eBayes(fit)

# Extract results for each cell type
topTable(fit, coef = "StimStatusstim", number = Inf)

# ---- chunk 8 ----
## ----treeTest-------------------------------------------------------------------------------------
# Perform multivariate test across the hierarchy
res <- treeTest(fit, cobj, hcl, coef = "StimStatusstim")

# Plot hierarchy and testing results
plotTreeTest(res)
