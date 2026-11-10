# gloss bench figure gallery-001
# source: package/viridis.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set(
  warning=FALSE,
  message=FALSE,
  fig.align='center'
)
# ---- chunk 2 ----
library(viridis)
library(ggplot2)
ggplot(data.frame(x = rnorm(10000), y = rnorm(10000)), aes(x = x, y = y)) +
  geom_hex() +
  scale_fill_viridis(option='C') +
  theme_minimal()
