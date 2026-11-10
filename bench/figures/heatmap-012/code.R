# gloss bench figure heatmap-012
# source: ComplexHeatmap::Extract.Heatmap (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ComplexHeatmap)
# ---- chunk 1 ----
### Name: [.Heatmap
### Title: Subset a Heatmap
### Aliases: Extract.Heatmap [.Heatmap

### ** Examples

m = matrix(rnorm(100), nrow = 10)
rownames(m) = letters[1:10]
colnames(m) = LETTERS[1:10]
ht = Heatmap(m)
ht[1:5, ]
ht[1:5]
