# gloss bench figure heatmap-008
# source: ComplexHeatmap::decorate_annotation (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ComplexHeatmap)
# ---- chunk 1 ----
### Name: decorate_annotation
### Title: Decorate Heatmap Annotation
### Aliases: decorate_annotation

### ** Examples

set.seed(123)
ha1 = HeatmapAnnotation(df = data.frame(type = rep(letters[1:2], 5)))
ha2 = rowAnnotation(point = anno_points(runif(10), which = "row"))
Heatmap(matrix(rnorm(100), 10), name = "mat", km = 2,
    top_annotation = ha1) + ha2
