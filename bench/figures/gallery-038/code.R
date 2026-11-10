# gloss bench figure gallery-038
# source: 175-choropleth-map-cartography-pkg.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set(warning = FALSE, message = FALSE)
# ---- chunk 2 ----
# Use the cartography library to do the choropleth map
library(cartography)

# Load data
data(nuts2006)

# Build a choropleth
choroLayer(spdf = nuts2.spdf, df = nuts2.df, var = "pop2008", legend.pos = "right")
title("Population in 2008")
