# gloss bench figure heatmap-026
# source: ComplexHeatmap::anno_summary (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ComplexHeatmap)
# ---- chunk 1 ----
### Name: anno_summary
### Title: Summary Annotation
### Aliases: anno_summary

### ** Examples

ha = HeatmapAnnotation(summary = anno_summary(height = unit(4, "cm")))
v = sample(letters[1:2], 50, replace = TRUE)
split = sample(letters[1:2], 50, replace = TRUE)
Heatmap(v, top_annotation = ha, width = unit(1, "cm"), split = split)
