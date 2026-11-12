# gloss bench figure heatmap-036
# source: ComplexHeatmap::anno_block (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ComplexHeatmap)
# ---- chunk 1 ----
### Name: anno_block
### Title: Block annotation
### Aliases: anno_block

### ** Examples

Heatmap(matrix(rnorm(100), 10), 
    top_annotation = HeatmapAnnotation(foo = anno_block(gp = gpar(fill = 2:4),
        labels = c("group1", "group2", "group3"), labels_gp = gpar(col = "white"))),
    column_km = 3,
    left_annotation = rowAnnotation(foo = anno_block(gp = gpar(fill = 2:4),
        labels = c("group1", "group2", "group3"), labels_gp = gpar(col = "white"))),
    row_km = 3)

# =============  set the panel_fun argument ==============
col = c("1" = "red", "2" = "blue", "A" = "green", "B" = "orange")
Heatmap(matrix(rnorm(100), 10), row_km = 2, row_split = sample(c("A", "B"), 10, replace = TRUE)) + 
rowAnnotation(foo = anno_block(
	panel_fun = function(index, levels) {
		grid.rect(gp = gpar(fill = col[levels[2]], col = "black"))
		grid.text(paste(levels, collapse = ","), 0.5, 0.5, rot = 90,
			gp = gpar(col = col[levels[1]]))
	}
))

labels = c("1" = "one", "2" = "two", "A" = "Group_A", "B" = "Group_B")
Heatmap(matrix(rnorm(100), 10), row_km = 2, row_split = sample(c("A", "B"), 10, replace = TRUE)) + 
rowAnnotation(foo = anno_block(panel_fun = function(index, levels) {
	grid.rect(gp = gpar(fill = col[levels[2]], col = "black"))
	grid.text(paste(labels[levels], collapse = ","), 0.5, 0.5, rot = 90,
		gp = gpar(col = col[levels[1]]))
}))

Heatmap(matrix(rnorm(100), 10), row_km = 2, row_split = sample(c("A", "B"), 10, replace = TRUE)) + 
rowAnnotation(foo = anno_block(
	panel_fun = function(index, levels) {
		grid.rect(gp = gpar(fill = col[levels[2]], col = "black"))
		txt = paste(levels, collapse = ",")
		txt = paste0(txt, "\n", length(index), " rows")
		grid.text(txt, 0.5, 0.5, rot = 0,
			gp = gpar(col = col[levels[1]]))
	},
	width = unit(3, "cm")
))

# =========== set align_to ################
col = c("foo" = "red", "bar" = "blue")
Heatmap(matrix(rnorm(100), 10), cluster_rows = FALSE) +
rowAnnotation(foo = anno_block(
	align_to = list(foo = 1:4, bar = 6:10),
	panel_fun = function(index, nm) {
		grid.rect(gp = gpar(fill = col[nm]))
		grid.text(nm, 0.5, 0.5)
	},
	width = unit(2, "cm"))
)
