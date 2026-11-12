# gloss bench figure tree-083
# source: treeclimbR (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
    collapse = TRUE,
    comment = "#>", 
    eval = TRUE,
    crop = NULL
)

# ---- chunk 2 ----
## ----install-pkg--------------------------------------------------------------
# if (!require("BiocManager", quietly = TRUE))
# #     install.packages("BiocManager") # [bench: install call removed]
# 
# # BiocManager::install("treeclimbR") # [bench: install call removed]

# ---- chunk 3 ----
## ----setup--------------------------------------------------------------------
suppressPackageStartupMessages({
    library(TreeSummarizedExperiment)
    library(treeclimbR)
    library(ggtree)
    library(dplyr)
    library(ggplot2)
})

# ---- chunk 4 ----
## ----da-load-and-visualize-data-----------------------------------------------
## Read data
da_lse <- readRDS(system.file("extdata", "da_sim_100_30_18de.rds", 
                              package = "treeclimbR"))
da_lse

## Generate tree visualization where true signal leaves are colored orange
## ...Find internal nodes in the subtrees where all leaves are differentially 
##    abundant. These will be colored orange.
nds <- joinNode(tree = rowTree(da_lse), 
                node = rownames(da_lse)[rowData(da_lse)$Signal])
br <- unlist(findDescendant(tree = rowTree(da_lse), node = nds,
                            only.leaf = FALSE, self.include = TRUE))
df_color <- data.frame(node = showNode(tree = rowTree(da_lse), 
                                       only.leaf = FALSE)) |>
    mutate(signal = ifelse(node %in% br, "yes", "no"))
## ...Generate tree
da_fig_tree <- ggtree(tr = rowTree(da_lse), layout = "rectangular", 
                      branch.length = "none", 
                      aes(color = signal)) %<+% df_color +
    scale_color_manual(values = c(no = "grey", yes = "orange"))
## ...Zoom into the subtree defined by a particular node. In this case, we 
##    know that all true signal leaves were sampled from the subtree defined 
##    by a particular node (stored in metadata(da_lse)$parentNodeForSignal).
da_fig_tree <- scaleClade(da_fig_tree, 
                          node = metadata(da_lse)$parentNodeForSignal, 
                          scale = 4)

## Extract count matrix and scale each row to [0, 1]
count <- assay(da_lse, "counts")
scale_count <- t(apply(count, 1, FUN = function(x) {
    xx <- x
    rx <- (max(xx) - min(xx))
    (xx - min(xx))/max(rx, 1)
}))
rownames(scale_count) <- rownames(count)
colnames(scale_count) <- colnames(count)

## Plot tree and heatmap of scaled counts
## ...Generate sample annotation
vv <- gsub(pattern = "_.*", "", colnames(count))
names(vv) <- colnames(scale_count)
anno_c <- structure(vv, names = vv)
TreeHeatmap(tree = rowTree(da_lse), tree_fig = da_fig_tree, 
            hm_data = scale_count, legend_title_hm = "Scaled\ncount",
            column_split = vv, rel_width = 0.6,
            tree_hm_gap = 0.3,
            column_split_label = anno_c) +
    scale_fill_viridis_c(option = "B") +
    scale_y_continuous(expand = c(0, 10))

# ---- chunk 5 ----
## ----da-aggregate-------------------------------------------------------------
## Get a list of all node IDs
all_node <- showNode(tree = rowTree(da_lse), only.leaf = FALSE)

## Calculate counts for internal nodes
da_tse <- aggTSE(x = da_lse, rowLevel = all_node, rowFun = sum)
da_tse

# ---- chunk 6 ----
## ----da-run-edger-------------------------------------------------------------
## Run differential analysis
da_res <- runDA(da_tse, assay = "counts", option = "glmQL", 
                design = model.matrix(~ group, data = colData(da_tse)), 
                contrast = c(0, 1), filter_min_count = 0, 
                filter_min_prop = 0, filter_min_total_count = 15)

# ---- chunk 7 ----
## ----da-runda-res-------------------------------------------------------------
names(da_res)
class(da_res$edgeR_results)

## Nodes with too low total count
da_res$nodes_drop

# ---- chunk 8 ----
## ----da-node-results----------------------------------------------------------
da_tbl <- nodeResult(da_res, n = Inf, type = "DA")
dim(da_tbl)
head(da_tbl)

# ---- chunk 9 ----
## ----da-get-cand--------------------------------------------------------------
## Get candidates
da_cand <- getCand(tree = rowTree(da_tse), score_data = da_tbl, 
                   node_column = "node", p_column = "PValue",
                   threshold = 0.05, sign_column = "logFC", message = FALSE)

# ---- chunk 10 ----
## ----da-plot-cand-------------------------------------------------------------
## All candidates
names(da_cand$candidate_list)

## Nodes contained in the candidate corresponding to t = 0.03
## This is a mix of leaves and internal nodes
(da_cand_0.03 <- da_cand$candidate_list[["0.03"]])

## Visualize candidate
da_fig_tree +
    geom_point2(aes(subset = (node %in% da_cand_0.03)), 
                color = "navy", size = 0.5) +
    labs(title = "t = 0.03") +
    theme(legend.position = "none",
          plot.title = element_text(color = "navy", size = 7, 
                                    hjust = 0.5, vjust = -0.08))

# ---- chunk 11 ----
## ----da-eval-cand-------------------------------------------------------------
## Evaluate candidates
da_best <- evalCand(tree = rowTree(da_tse), levels = da_cand$candidate_list, 
                    score_data = da_tbl, node_column = "node",
                    p_column = "PValue", sign_column = "logFC")

# ---- chunk 12 ----
## ----da-info-cand-------------------------------------------------------------
infoCand(object = da_best)

# ---- chunk 13 ----
## ----da-topnodes--------------------------------------------------------------
da_out <- topNodes(object = da_best, n = Inf, p_value = 0.05)

# ---- chunk 14 ----
## ----da-plot-significant------------------------------------------------------
da_fig_tree +
    geom_point2(aes(subset = node %in% da_out$node),
                color = "red")

# ---- chunk 15 ----
## ----da-fdr-tpr---------------------------------------------------------------
fdr(rowTree(da_tse), truth = rownames(da_lse)[rowData(da_lse)$Signal], 
    found = da_out$node, only.leaf = TRUE)

tpr(rowTree(da_tse), truth = rownames(da_lse)[rowData(da_lse)$Signal], 
    found = da_out$node, only.leaf = TRUE)

# ---- chunk 16 ----
## ----ds-load-and-visualize-data-----------------------------------------------
ds_tse <- readRDS(system.file("extdata", "ds_sim_20_500_8de.rds", 
                              package = "treeclimbR"))
ds_tse

## Assignment of cells to high-resolution clusters, samples and conditions
head(colData(ds_tse))

## Tree providing the successive aggregation of the high-resolution clusters
## into more coarse-grained ones
## Node numbers are indicated in blue, node labels in orange
ggtree(colTree(ds_tse)) +
    geom_text2(aes(label = node), color = "darkblue",
               hjust = -0.5, vjust = 0.7) +
    geom_text2(aes(label = label), color = "darkorange",
               hjust = -0.1, vjust = -0.7)
