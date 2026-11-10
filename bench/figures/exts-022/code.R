# gloss bench figure exts-022
# source: ggvolcano (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggvolcano)
# ---- chunk 1 ----
### Name: ggvolcano
### Title: Publication-ready volcano plots
### Aliases: ggvolcano

### ** Examples

data <- read.csv(system.file("extdata", "example.csv", package = "ggvolcano"))

ggvolcano(data,
  logFC_col = "log2FoldChange",
  pval_col = "pvalue",
  pval_cutoff = 10e-4,
  logFC_cutoff = 1.5,
  x_limits = c(-5.5, 5.5),
  y_limits = c(0, -log10(10e-12)),
  title = "Example Volcano plot",
  caption = "FC cutoff, 1.5; p-value cutoff, 10e-4",
  gridlines = list(major = TRUE, minor = TRUE),
  horizontal_line = 10e-8, # Draw horizontal line for p-value cutoff
  horizontal_line_aes = list(type = "dashed", color = "red", width = 0.5)
)
