# gloss bench figure tree-031
# source: ggtree::reexports (topic)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggtree)
# ---- chunk 1 ----
### Name: reexports
### Title: Objects exported from other packages
### Aliases: reexports %<+% td_filter td_mutate td_unnest %>% rtree
###   read.tree groupOTU groupClade nodeid nodelab MRCA collapse fortify
###   ggplot xlim theme ggsave aes geom_text geom_label geom_point
###   guide_legend scale_colour_manual scale_color_manual scale_fill_manual
###   scale_x_continuous margin arrow unit plot_list identify
### Keywords: internal

### ** Examples

nwk <- system.file("extdata", "sample.nwk", package="treeio")
tree <- read.tree(nwk)
p <- ggtree(tree)
dd <- data.frame(taxa=LETTERS[1:13],
                   place=c(rep("GZ", 5), rep("HK", 3), rep("CZ", 4), NA),
             value=round(abs(rnorm(13, mean=70, sd=10)), digits=1))
row.names(dd) <- NULL
p %<+% dd + geom_text(aes(color=place, label=label), hjust=-0.5)
