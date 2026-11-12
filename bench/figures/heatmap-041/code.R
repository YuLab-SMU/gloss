# gloss bench figure heatmap-041
# source: ComplexHeatmap::attach_annotation-Heatmap-method (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ComplexHeatmap)
# ---- chunk 1 ----
### Name: attach_annotation-Heatmap-method
### Title: Attach heatmap annotations to the heatmap
### Aliases: attach_annotation,Heatmap-method attach_annotation

### ** Examples

m = matrix(rnorm(100), 10)
ht = Heatmap(m)
ha = HeatmapAnnotation(foo = 1:10)
ht = attach_annotation(ht, ha)
ht
ha2 = HeatmapAnnotation(bar = letters[1:10])
ht = attach_annotation(ht, ha2)
ht
