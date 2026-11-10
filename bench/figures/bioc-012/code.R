# gloss bench figure bioc-012
# source: wiggleplotr (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----include=FALSE------------------------------------------------------------
#This block gets rid of the import messages
library("wiggleplotr")
library("GenomicRanges")
library("dplyr")
library("biomaRt")
library("GenomicFeatures")
library("ensembldb")
library("EnsDb.Hsapiens.v86")
library("org.Hs.eg.db")
library("TxDb.Hsapiens.UCSC.hg38.knownGene")

# ---- chunk 2 ----
## ----eval = FALSE-------------------------------------------------------------
# if (!requireNamespace("BiocManager", quietly=TRUE))
# #     install.packages("BiocManager") # [bench: install call removed]
# # BiocManager::install("wiggleplotr") # [bench: install call removed]

# ---- chunk 3 ----
## -----------------------------------------------------------------------------
library("wiggleplotr")
library("dplyr")
library("GenomicRanges")
library("GenomicFeatures")
library("biomaRt")

# ---- chunk 4 ----
## -----------------------------------------------------------------------------
ncoa7_metadata
names(ncoa7_exons)
names(ncoa7_cdss)

# ---- chunk 5 ----
## -----------------------------------------------------------------------------
plotTranscripts(ncoa7_exons, ncoa7_cdss, ncoa7_metadata, rescale_introns = FALSE)

# ---- chunk 6 ----
## -----------------------------------------------------------------------------
plotTranscripts(ncoa7_exons, ncoa7_cdss, ncoa7_metadata, rescale_introns = TRUE)

# ---- chunk 7 ----
## -----------------------------------------------------------------------------
plotTranscripts(ncoa7_exons, rescale_introns = TRUE)

# ---- chunk 8 ----
## -----------------------------------------------------------------------------
sample_data = dplyr::data_frame(
  sample_id = c("aipt_A", "aipt_C", "bima_A", "bima_C"), 
  condition = factor(c("Naive", "LPS", "Naive", "LPS"), levels = c("Naive", "LPS")), 
  scaling_factor = 1)
sample_data = sample_data %>%
  dplyr::mutate(bigWig = system.file("extdata", paste0(sample_id, ".str2.bw"), 
                                     package = "wiggleplotr"))
as.data.frame(sample_data)

# ---- chunk 9 ----
## -----------------------------------------------------------------------------
track_data = dplyr::mutate(sample_data, track_id = condition, colour_group = condition)

# ---- chunk 10 ----
## -----------------------------------------------------------------------------
selected_transcripts = c("ENST00000438495", "ENST00000392477") #Plot only two transcripts of the gens
plotCoverage(ncoa7_exons[selected_transcripts], ncoa7_cdss[selected_transcripts], 
             ncoa7_metadata, track_data,
             heights = c(2,1), fill_palette = getGenotypePalette())
