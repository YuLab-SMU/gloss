# gloss bench figure bioc-014
# source: DifferentialRegulation (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----setup, echo=FALSE, results="hide"----------------------------------------
knitr::opts_chunk$set(tidy=FALSE, cache=TRUE,
                      dev="png",
                      message=TRUE, error=FALSE, warning=TRUE)

# ---- chunk 2 ----
## ----Bioconductor_installation, eval=FALSE------------------------------------
# if (!requireNamespace("BiocManager", quietly=TRUE))
# #   install.packages("BiocManager") # [bench: install call removed]
# # BiocManager::install("DifferentialRegulation") # [bench: install call removed]

# ---- chunk 3 ----
## ----vignettes, eval=FALSE----------------------------------------------------
# browseVignettes("DifferentialRegulation")

# ---- chunk 4 ----
## ----citation-----------------------------------------------------------------
citation("DifferentialRegulation")

# ---- chunk 5 ----
## ----load, message=FALSE------------------------------------------------------
library(DifferentialRegulation)

# ---- chunk 6 ----
## ----specify_data-dir---------------------------------------------------------
data_dir = system.file("extdata", package = "DifferentialRegulation")

# ---- chunk 7 ----
## ----specify_directories------------------------------------------------------
# specify samples ids:
sample_ids = paste0("organoid", c(1:3, 16:18))
# set directories of each sample input data (obtained via alevin-fry):
base_dir = file.path(data_dir, "alevin-fry", sample_ids)

# Note that alevin-fry needs to be run with `--use-mtx` option to store counts in a `quants_mat.mtx` file.
path_to_counts = file.path(base_dir,"/alevin/quants_mat.mtx")
path_to_cell_id = file.path(base_dir,"/alevin/quants_mat_rows.txt")
path_to_gene_id = file.path(base_dir,"/alevin/quants_mat_cols.txt")

# ---- chunk 8 ----
## ----specify_directories_EC---------------------------------------------------
path_to_EC_counts = file.path(base_dir,"/alevin/geqc_counts.mtx")
path_to_EC = file.path(base_dir,"/alevin/gene_eqclass.txt.gz")

# ---- chunk 9 ----
## ----load_USA_counts----------------------------------------------------------
sce = load_USA(path_to_counts,
               path_to_cell_id,
               path_to_gene_id,
               sample_ids)

sce

# ---- chunk 10 ----
## ----cell-type----------------------------------------------------------------
path_to_DF = file.path(data_dir,"DF_cell_types.txt")
DF_cell_types = read.csv(path_to_DF, sep = "\t", header = TRUE)
matches = match(colnames(sce), DF_cell_types$cell_id)
sce$cell_type = DF_cell_types$cell_type[matches]
table(sce$cell_type)

# ---- chunk 11 ----
## ----load_EC_counts-----------------------------------------------------------
EC_list = load_EC(path_to_EC_counts,
                  path_to_EC,
                  path_to_cell_id,
                  path_to_gene_id,
                  sample_ids)

# ---- chunk 12 ----
## ----samples_design-----------------------------------------------------------
design = data.frame(sample = sample_ids,
                    group = c( rep("3 mon", 3), rep("6 mon", 3) ))
design

# ---- chunk 13 ----
## ----compute_PB_counts--------------------------------------------------------
PB_counts = compute_PB_counts(sce = sce,
                              EC_list = EC_list,
                              design =  design,
                              sample_col_name = "sample",
                              group_col_name = "group",
                              sce_cluster_name = "cell_type")

# ---- chunk 14 ----
## ----rm_EC_list---------------------------------------------------------------
rm(EC_list)

# ---- chunk 15 ----
## ----EC-test------------------------------------------------------------------
# EC-based test:
set.seed(1609612)
results = DifferentialRegulation(PB_counts,
                                 n_cores = 2,
                                 traceplot = TRUE)

# ---- chunk 16 ----
## ----names-results------------------------------------------------------------
names(results)

# ---- chunk 17 ----
## ----visualize_gene_results---------------------------------------------------
head(results$Differential_results, 3)

# ---- chunk 18 ----
## ----sort_gene_results-UP-----------------------------------------------------
ordering_UP = order(results$Differential_results[,6], decreasing = TRUE)
head(results$Differential_results[ordering_UP,], 3)

# ---- chunk 19 ----
## ----sort_gene_results-DOWN---------------------------------------------------
ordering_DOWN = order(results$Differential_results[,6], decreasing = FALSE)
head(results$Differential_results[ordering_DOWN,], 3)

# ---- chunk 20 ----
## ----visualize_US_results-----------------------------------------------------
head(results$US_results, 3)

# ---- chunk 21 ----
## ----visualize_USA_results----------------------------------------------------
head(results$USA_results, 3)

# ---- chunk 22 ----
## ----visualize_convergence_results--------------------------------------------
results$Convergence_results

# ---- chunk 23 ----
## ----plot_pi------------------------------------------------------------------
plot_pi(results,
        type = "US",
        gene_id = results$Differential_results$Gene_id[1],
        cluster_id = results$Differential_results$Cluster_id[1])

plot_pi(results,
        type = "US",
        gene_id = results$Differential_results$Gene_id[2],
        cluster_id = results$Differential_results$Cluster_id[2])


# ---- chunk 24 ----
## ----plot_pi_USA--------------------------------------------------------------
plot_pi(results,
        type = "USA",
        gene_id = results$Differential_results$Gene_id[1],
        cluster_id = results$Differential_results$Cluster_id[1])

plot_pi(results,
        type = "USA",
        gene_id = results$Differential_results$Gene_id[2],
        cluster_id = results$Differential_results$Cluster_id[2])

# ---- chunk 25 ----
## ----plot_pi-traceplot--------------------------------------------------------
plot_traceplot(results,
               gene_id = results$Differential_results$Gene_id[1],
               cluster_id = results$Differential_results$Cluster_id[1])

plot_traceplot(results,
               gene_id = results$Differential_results$Gene_id[2],
               cluster_id = results$Differential_results$Cluster_id[2])

# ---- chunk 26 ----
## ----load-bulk, message=FALSE-------------------------------------------------
library(DifferentialRegulation)

# ---- chunk 27 ----
## ----specify_data-dir-bulk----------------------------------------------------
data_dir = system.file("extdata", package = "DifferentialRegulation")

# ---- chunk 28 ----
## ----specify_directories-bulk-------------------------------------------------
# specify samples ids:
sample_ids = paste0("sample", seq_len(6))

# US estimates:
quant_files = file.path(data_dir, "salmon", sample_ids, "quant.sf")
file.exists(quant_files)

# Equivalence classes:
equiv_classes_files = file.path(data_dir, "salmon", sample_ids, "aux_info/eq_classes.txt.gz")
file.exists(equiv_classes_files)

# ---- chunk 29 ----
## ----load_US_counts-bulk------------------------------------------------------
SE = load_bulk_US(quant_files,
                  sample_ids)

# ---- chunk 30 ----
## ----load_EC_counts-bulk------------------------------------------------------
EC_list = load_bulk_EC(path_to_eq_classes = equiv_classes_files,
                       n_cores = 2)

# ---- chunk 31 ----
## ----samples_design-bulk------------------------------------------------------
group_names = rep(c("A", "B"), each = 3)
design = data.frame(sample = sample_ids,
                    group = group_names)
design

# ---- chunk 32 ----
## ----EC-test-bulk-------------------------------------------------------------
# EC-based test:
set.seed(1609612)
results = DifferentialRegulation_bulk(SE = SE, 
                                      EC_list = EC_list,
                                      design = design,
                                      n_cores = 2,
                                      traceplot = TRUE)

# ---- chunk 33 ----
## ----names-results-bulk-------------------------------------------------------
names(results)

# ---- chunk 34 ----
## ----visualize_gene_results-bulk----------------------------------------------
head(results$Differential_results, 3)

# ---- chunk 35 ----
## ----sort_gene_results-UP-bulk------------------------------------------------
ordering_UP = order(results$Differential_results[,4], decreasing = TRUE)
head(results$Differential_results[ordering_UP,], 3)

# ---- chunk 36 ----
## ----sort_gene_results-DOWN-bulk----------------------------------------------
ordering_DOWN = order(results$Differential_results[,4], decreasing = FALSE)
head(results$Differential_results[ordering_DOWN,], 3)

# ---- chunk 37 ----
## ----visualize_convergence_results-bulk---------------------------------------
results$Convergence_results

# ---- chunk 38 ----
## ----plot_pi-bulk-------------------------------------------------------------
plot_bulk_pi(results,
             transcript_id = results$Differential_results$Transcript_id[1])

plot_bulk_pi(results,
             transcript_id = results$Differential_results$Transcript_id[2])

# ---- chunk 39 ----
## ----plot_pi-bulk-traceplot---------------------------------------------------
plot_bulk_traceplot(results,
                    transcript_id = results$Differential_results$Transcript_id[1])
