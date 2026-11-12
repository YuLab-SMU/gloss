# gloss bench figure tree-002
# source: scBubbletree (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----setup, include = FALSE, warning = FALSE----------------------------------
knitr::opts_chunk$set(comment = "#>", warning = FALSE, message = FALSE)

# ---- chunk 2 ----
## -----------------------------------------------------------------------------
library(scBubbletree)
library(ggplot2)
library(ggtree)
library(patchwork)

# ---- chunk 3 ----
## -----------------------------------------------------------------------------
# # This script can be used to generate data("d_ccl", package = "scBubbletree")
# 
# # create directory
# dir.create(path = "case_study/")
# 
# # download the data from:
# https://github.com/LuyiTian/sc_mixology/raw/master/data/
#   sincell_with_class_5cl.RData
# 
# # load the data
# load(file = "case_study/sincell_with_class_5cl.RData")
# 
# # we are only interested in the 10x data object 'sce_sc_10x_5cl_qc'
# d <- sce_sc_10x_5cl_qc
# 
# # remove the remaining objects (cleanup)
# rm(sc_Celseq2_5cl_p1, sc_Celseq2_5cl_p2, sc_Celseq2_5cl_p3, sce_sc_10x_5cl_qc)
# 
# # get the meta data for each cell
# meta <- colData(d)[,c("cell_line_demuxlet","non_mt_percent","total_features")]
# 
# # create Seurat object from the raw counts and append the meta data to it
# d <- Seurat::CreateSeuratObject(counts = d@assays$data$counts,
#                                 project = '')
# 
# # check if all cells are matched between d and meta
# # table(rownames(d@meta.data) == meta@rownames)
# d@meta.data <- cbind(d@meta.data, meta@listData)
# 
# # cell type predictions are provided as part of the meta data
# table(d@meta.data$cell_line)
# 
# # select 5,000 most variable genes
# d <- Seurat::FindVariableFeatures(object = d,
#                                   selection.method = "vst",
#                                   nfeatures = 5000)
# 
# # Preprocessing with Seurat: SCT transformation + PCA
# d <- SCTransform(object = d,
#                  variable.features.n = 5000)
# d <- RunPCA(object = d,
#             npcs = 50,
#             features = VariableFeatures(object = d))
# 
# # perform UMAP + t-SNE
# d <- RunUMAP(d, dims = 1:15)
# d <- RunTSNE(d, dims = 1:15)
# 
# # save the preprocessed data
# save(d, file = "case_study/d.RData")
# 
# # save the PCA matrix 'A', meta data 'm' and
# # marker genes matrix 'e'
# d <- get(load(file ="case_study/d.RData"))
# A <- d@reductions$pca@cell.embeddings[, 1:15]
# m <- d@meta.data
# e <- t(as.matrix(d@assays$SCT@data[
#   rownames(d@assays$SCT@data) %in%
#     c("ALDH1A1",
#       "PIP4K2C",
#       "SLPI",
#       "CT45A2",
#       "CD74"), ]))
# 
# d_ccl <- list(A = A, m = m, e = e)
# save(d_ccl, file = "data/d_ccl.RData")

# ---- chunk 4 ----
## -----------------------------------------------------------------------------
# Load the data
data("d_ccl", package = "scBubbletree")

# ---- chunk 5 ----
## -----------------------------------------------------------------------------
# Extract the 15-dimensional PCA matrix A
# A has n=cells as rows, f=15 features as columns (e.g. from PCA)
A <- d_ccl$A
dim(A)

# ---- chunk 6 ----
## -----------------------------------------------------------------------------
# Extract the meta-data. For each cell this data contains some 
# additional information. Inspect this data now!
m <- d_ccl$m
colnames(m)

# ---- chunk 7 ----
## -----------------------------------------------------------------------------
# Extract the normalized expressions of five marker genes. Rows
# are cells.
e <- d_ccl$e
colnames(e)

# ---- chunk 8 ----
## -----------------------------------------------------------------------------
b_r <- get_r(B_gap = 5,
             rs = 10^seq(from = -4, to = 0.5, by = 0.5),
             x = A,
             n_start = 10,
             iter_max = 50,
             algorithm = "original",
             knn_k = 50,
             cores = 1)

# ---- chunk 9 ----
## ----fig.width=4, fig.height=3------------------------------------------------
ggplot(data = b_r$gap_stats_summary)+
  geom_line(aes(x = r, y = gap_mean))+
  geom_point(aes(x = r, y = gap_mean), size = 1)+
  geom_errorbar(aes(x = r, y = gap_mean, ymin = L95, ymax = H95), width = 0.1)+
  ylab(label = "Gap")+
  xlab(label = "r")+
  geom_vline(xintercept = 0.003, col = "gray", linetype = "dashed")+
  scale_x_log10()+
  annotation_logticks(base = 10, sides = "b")

# ---- chunk 10 ----
## ----fig.width=4, fig.height=3------------------------------------------------
ggplot(data = b_r$gap_stats_summary)+
  geom_line(aes(x = k, y = gap_mean))+
  geom_point(aes(x = k, y = gap_mean), size = 1)+
  geom_errorbar(aes(x = k, y = gap_mean, ymin = L95, ymax = H95), width = 0.1)+
  geom_vline(xintercept = 5, col = "gray", linetype = "dashed")+
  ylab(label = "Gap")+
  xlab(label = "k'")

# ---- chunk 11 ----
## ----fig.width=4, fig.height=3, fig.align='center'----------------------------
ggplot(data = b_r$gap_stats_summary)+
  geom_point(aes(x = r, y = k), size = 1)+
  xlab(label = "r")+
  ylab(label = "k'")+
  scale_x_log10()+
  annotation_logticks(base = 10, sides = "b")+
  theme_bw()

# ---- chunk 12 ----
## -----------------------------------------------------------------------------
knitr::kable(x = b_r$gap_stats_summary[b_r$gap_stats_summary$k == 5, ],
             digits = 4, row.names = FALSE)

# ---- chunk 13 ----
## -----------------------------------------------------------------------------
b_k <- get_k(B_gap = 5,
             ks = 1:10, 
             x = A,
             n_start = 50,
             iter_max = 200,
             kmeans_algorithm = "MacQueen",
             cores = 1)

# ---- chunk 14 ----
## ----fig.width=4, fig.height=3------------------------------------------------
ggplot(data = b_k$gap_stats_summary)+
  geom_line(aes(x = k, y = gap_mean))+
  geom_point(aes(x = k, y = gap_mean), size = 1)+
  geom_errorbar(aes(x = k, y = gap_mean, ymin = L95, ymax = H95), width = 0.1)+
  ylab(label = "Gap")+
  geom_vline(xintercept = 5, col = "gray", linetype = "dashed")

# ---- chunk 15 ----
## -----------------------------------------------------------------------------
l <- get_bubbletree_graph(x = A,
                          r = 0.1,
                          algorithm = "original",
                          n_start = 20,
                          iter_max = 100,
                          knn_k = 50,
                          cores = 1,
                          B = 300,
                          N_eff = 200,
                          round_digits = 1,
                          show_simple_count = FALSE)

#  See the help `?get_bubbletree_graph` to learn about the input parameters.

# ---- chunk 16 ----
## ----fig.width=4, fig.height=3, fig.align='center'----------------------------
l$tree

# ---- chunk 17 ----
## -----------------------------------------------------------------------------
knitr::kable(l$tree_meta, digits = 2, row.names = FALSE)

# ---- chunk 18 ----
## -----------------------------------------------------------------------------
k <- get_bubbletree_kmeans(x = A,
                           k = 5,
                           cores = 1,
                           B = 300,
                           N_eff = 200,
                           round_digits = 1,
                           show_simple_count = FALSE,
                           kmeans_algorithm = "MacQueen")

# ---- chunk 19 ----
## ----fig.width=6, fig.height=3, fig.align='center'----------------------------
l$tree|k$tree

# ---- chunk 20 ----
## ----fig.width=7, fig.height=7------------------------------------------------
cp <- compare_bubbletrees(btd_1 = l, 
                          btd_2 = k,
                          ratio_heatmap = 0.6,
                          tile_bw = F,
                          tile_text_size = 3)
cp$comparison

# ---- chunk 21 ----
## ----fig.width=7, fig.height=4, fig.align='center'----------------------------
w1 <- get_cat_tiles(btd = l,
                    f = m$cell_line_demuxlet,
                    integrate_vertical = TRUE,
                    round_digits = 1,
                    x_axis_name = 'Cell line',
                    rotate_x_axis_labels = TRUE,
                    tile_text_size = 2.75)

(l$tree|w1$plot)+
  patchwork::plot_layout(widths = c(1, 1))

# ---- chunk 22 ----
## ----fig.width=7, fig.height=4, fig.align='center'----------------------------
w2 <- get_cat_tiles(btd = l,
                    f = m$cell_line_demuxlet,
                    integrate_vertical = FALSE,
                    round_digits = 1,
                    x_axis_name = 'Cell line',
                    rotate_x_axis_labels = TRUE,
                    tile_text_size = 2.75)

(l$tree|w2$plot)+patchwork::plot_layout(widths = c(1, 1))

# ---- chunk 23 ----
## ----fig.width=9, fig.height=4, fig.align='center'----------------------------
(l$tree|w1$plot|w2$plot)+
  patchwork::plot_layout(widths = c(1, 2, 2))+
  patchwork::plot_annotation(tag_levels = "A")

# ---- chunk 24 ----
## -----------------------------------------------------------------------------
# gini
get_gini(labels = m$cell_line_demuxlet, 
         clusters = l$cluster)$gi

# ---- chunk 25 ----
## -----------------------------------------------------------------------------
gini_boot <- get_gini_k(labels = m$cell_line_demuxlet, obj = b_r)

# ---- chunk 26 ----
## ----fig.width=4, fig.height=3, fig.align='center'----------------------------
g1 <- ggplot(data = gini_boot$wgi_summary)+
  geom_point(aes(x = k, y = wgi), size = 1)+
  ylab(label = "WGI")+
  ylim(c(0, 1))

g1

# ---- chunk 27 ----
## ----fig.width=8, fig.height=4, fig.align='center'----------------------------
w3 <- get_num_tiles(btd = l,
                    fs = e,
                    summary_function = "mean",
                    x_axis_name = 'Gene expression',
                    rotate_x_axis_labels = TRUE,
                    round_digits = 1,
                    tile_text_size = 2.75)

(l$tree|w3$plot)+patchwork::plot_layout(widths = c(1, 1))

# ---- chunk 28 ----
## ----fig.width=10, fig.height=4, fig.align='center'---------------------------
w4 <- get_num_violins(btd = l,
                      fs = e,
                      x_axis_name = 'Gene expression',
                      rotate_x_axis_labels = TRUE)

(l$tree|w3$plot|w4$plot)+
  patchwork::plot_layout(widths = c(1.5, 2, 2.5))+
  patchwork::plot_annotation(tag_levels = 'A')

# ---- chunk 29 ----
## ----fig.width=9, fig.height=4, fig.align='center'----------------------------
w_mt_dist <- get_num_violins(btd = l,
                             fs = 1-m$non_mt_percent,
                             x_axis_name = 'MT [%]',
                             rotate_x_axis_labels = TRUE)

w_umi_dist <- get_num_violins(btd = l,
                              fs = m$nCount_RNA/1000,
                              x_axis_name = 'RNA count (in thousands)',
                              rotate_x_axis_labels = TRUE)

w_gene_dist <- get_num_violins(btd = l,
                               fs = m$nFeature_RNA,
                               x_axis_name = 'Gene count',
                               rotate_x_axis_labels = TRUE)


(l$tree|w_mt_dist$plot|w_umi_dist$plot|w_gene_dist$plot)+
  patchwork::plot_layout(widths = c(1, 1, 1, 1))+
  patchwork::plot_annotation(tag_levels = 'A')

# ---- chunk 30 ----
## ----fig.width=6, fig.height=4, fig.align='center'----------------------------
pam_k5 <- cluster::pam(x = A, k = 5, metric = "euclidean")

dummy_k5_pam <- get_bubbletree_dummy(x = A,
                                     cs = pam_k5$clustering,
                                     B = 200,
                                     N_eff = 200,
                                     cores = 2,
                                     round_digits = 1)

dummy_k5_pam$tree|
  get_cat_tiles(btd = dummy_k5_pam, 
                f = m$cell_line_demuxlet,
                integrate_vertical = TRUE,
                round_digits = 1,
                tile_text_size = 2.75,
                x_axis_name = 'Cell line',
                rotate_x_axis_labels = TRUE)$plot

# ---- chunk 31 ----
## ----fig.width=6, fig.height=4, fig.align='center'----------------------------
# e.g. matrix from CellChat
cc_mat <- matrix(data = runif(n = 25, min = 0, max = 0.5),
                 nrow = 5, ncol = 5)
colnames(cc_mat) <- 0:4
rownames(cc_mat) <- 0:4
diag(cc_mat) <- 1

cc <- reshape2::melt(cc_mat)
cc$Var1 <- factor(x = cc$Var1, levels = rev(l$tree_meta$label))
cc$Var2 <- factor(x = cc$Var2, levels = rev(l$tree_meta$label))
colnames(cc) <- c("x", "y", "cc")

g_cc <- ggplot()+
  geom_tile(data = cc, aes(x = x, y = y, fill = cc), col = "white")+
  scale_fill_distiller(palette = "Spectral")+
  xlab(label = "Cluster x")+
  ylab(label = "Cluster y")

# ---- chunk 32 ----
## ----fig.width=6, fig.height=3, fig.align='center'----------------------------
l$tree|g_cc
