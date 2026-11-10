# gloss bench figure bioc-001
# source: YAPSA (vignette)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
## ----loadStyle, warning=FALSE, echo=FALSE, message=FALSE, results="hide"------
library(BiocStyle)

# ---- chunk 2 ----
## ----packages, include=FALSE--------------------------------------------------
library(YAPSA)
library(Biostrings)
library(BSgenome.Hsapiens.UCSC.hg19)
library(knitr)
opts_chunk$set(echo=TRUE)
opts_chunk$set(fig.show='asis')

# ---- chunk 3 ----
## ----loadStoredSigData--------------------------------------------------------
data(sigs)
data(cutoffs)
data("lymphomaNature2013_mutCat_df")
current_cutoff_vector <- cutoffCosmicValid_abs_df[6,]

# ---- chunk 4 ----
## ----LCDwithCutoffs-----------------------------------------------------------
lymphoma_COSMIC_listsList <-
  LCD_complex_cutoff_combined(
      in_mutation_catalogue_df = lymphomaNature2013_mutCat_df,
      in_cutoff_vector = current_cutoff_vector, 
      in_signatures_df = AlexCosmicValid_sig_df, 
      in_sig_ind_df = AlexCosmicValid_sigInd_df)

# ---- chunk 5 ----
## ----subrgroupAnnotation------------------------------------------------------
data(lymphoma_PID)
colnames(lymphoma_PID_df) <- "SUBGROUP"
lymphoma_PID_df$PID <- rownames(lymphoma_PID_df)
COSMIC_subgroups_df <- 
  make_subgroups_df(lymphoma_PID_df,
                    lymphoma_COSMIC_listsList$cohort$exposures)

# ---- chunk 6 ----
## ----captionExposures, echo=FALSE---------------------------------------------
cap <- "Exposures to SNV mutational signatures"

# ---- chunk 7 ----
## ----exposuresCutoffs, warning=FALSE, fig.width=8, fig.height=6, fig.cap= cap----
exposures_barplot(
  in_exposures_df = lymphoma_COSMIC_listsList$cohort$exposures,
  in_signatures_ind_df = lymphoma_COSMIC_listsList$cohort$out_sig_ind_df,
  in_subgroups_df = COSMIC_subgroups_df)               
