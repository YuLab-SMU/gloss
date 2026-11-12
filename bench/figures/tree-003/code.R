# gloss bench figure tree-003
# source: cogeqc (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
    collapse = TRUE,
    comment = "#>",
    crop = NULL,
    dpi = 100
)

# ---- chunk 2 ----
## ----installation, eval=FALSE-------------------------------------------------
# if(!requireNamespace('BiocManager', quietly = TRUE))
# #   install.packages('BiocManager') # [bench: install call removed]
# # BiocManager::install("cogeqc") # [bench: install call removed]

# ---- chunk 3 ----
## ----load_package, message=FALSE----------------------------------------------
# Load package after installation
library(cogeqc)

# ---- chunk 4 ----
## ----data_description---------------------------------------------------------
# Orthogroups for Arabidopsis thaliana and Brassica oleraceae
data(og)
head(og)

# Interpro domain annotations
data(interpro_ath)
data(interpro_bol)

head(interpro_ath)
head(interpro_bol)

# ---- chunk 5 ----
## ----read_orthogroups_demo----------------------------------------------------
# Path to the Orthogroups.tsv file created by OrthoFinder
og_file <- system.file("extdata", "Orthogroups.tsv.gz", package = "cogeqc") 

# Read and parse file
orthogroups <- read_orthogroups(og_file)
head(orthogroups)

# ---- chunk 6 ----
## ----assess_og----------------------------------------------------------------
# Create a list of annotation data frames
annotation <- list(Ath = interpro_ath, Bol = interpro_bol)
str(annotation) # This is what the list must look like

og_assessment <- assess_orthogroups(og, annotation)
head(og_assessment)

# ---- chunk 7 ----
## ----mean_h-------------------------------------------------------------------
mean(og_assessment$Mean_score)

# ---- chunk 8 ----
## ----ref-based_og_assessment--------------------------------------------------
set.seed(123)

# Subset the top 5000 rows for demonstration purposes
og_subset <- og[1:5000, ]
ref <- og_subset

# Shuffle 100 genes to simulate a test set
idx_shuffle <- sample(seq_len(nrow(og_subset)), 100, replace = FALSE)
test <- og_subset
test$Gene[idx_shuffle] <- sample(
  test$Gene[idx_shuffle], size = length(idx_shuffle), replace = FALSE
)

# Compare test set to reference set
comparison <- compare_orthogroups(ref, test)
head(comparison)

# Calculating percentage of preservation
preserved <- sum(comparison$Preserved) / length(comparison$Preserved)
preserved

# ---- chunk 9 ----
## -----------------------------------------------------------------------------
stats_dir <- system.file("extdata", package = "cogeqc")
ortho_stats <- read_orthofinder_stats(stats_dir)
ortho_stats

# ---- chunk 10 ----
## ----plot_species_tree--------------------------------------------------------
data(tree)
plot_species_tree(tree)

# ---- chunk 11 ----
## ----plot_species_tree_with_dups----------------------------------------------
plot_species_tree(tree, stats_list = ortho_stats)
