# gloss bench figure exts-011
# source: ggalign (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggalign)
# ---- chunk 1 ----
### Name: circle_layout
### Title: Arrange plots in a circular layout
### Aliases: circle_layout circle_discrete circle_continuous

### ** Examples

set.seed(123)

small_mat <- matrix(rnorm(56), nrow = 7)
rownames(small_mat) <- paste0("row", seq_len(nrow(small_mat)))
colnames(small_mat) <- paste0("column", seq_len(ncol(small_mat)))

# circle_layout
# same for circle_discrete()
circle_layout(small_mat) +
    ggalign() +
    geom_tile(aes(y = .column_index, fill = value)) +
    scale_fill_viridis_c() +
    align_dendro(aes(color = branch), k = 3L) +
    scale_color_brewer(palette = "Dark2")

# same for circle_continuous()
circle_layout(mpg, limits = continuous_limits(c(3, 5))) +
    ggalign(mapping = aes(displ, hwy, colour = class)) +
    geom_point(size = 2) +
    ggalign(mapping = aes(displ, hwy, colour = class)) +
    geom_point(size = 2) &
    scale_color_brewer(palette = "Dark2") &
    theme_bw()
