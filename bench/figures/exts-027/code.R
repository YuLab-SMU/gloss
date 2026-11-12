# gloss bench figure exts-027
# source: hrbrthemes (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(hrbrthemes)
# ---- chunk 1 ----
### Name: scale_fill_flexoki_light_spectrum
### Title: Distiller Fill Scale Across All Flexoki Light Colors
### Aliases: scale_fill_flexoki_light_spectrum

### ** Examples

library(ggplot2)
ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
  geom_tile() +
  scale_fill_flexoki_light_spectrum()
