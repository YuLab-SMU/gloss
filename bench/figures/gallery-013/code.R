# gloss bench figure gallery-013
# source: a-smooth-transition-between-chloropleth-and-cartogram.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set(warning = FALSE, message = FALSE, dpi = 300, dev = "ragg_png")
# ---- chunk 2 ----
# Load libraries
library(dplyr) # data wrangling
library(cartogram) # for the cartogram
library(ggplot2) # to realize the plots
library(transformr) # needed in order to make gganimate works with sf
library(gganimate) # To realize the animation
library(sf) # read shapefiles
# ---- chunk 3 ----
# Get the shape file of Africa, see how on
# https://r-graph-gallery.com/168-load-a-shape-file-into-r.html

# I stored the data on a DATA folder and read it from there
wrld_simpl <- read_sf("data/TM_WORLD_BORDERS_SIMPL-0.3.shp")
afr <- wrld_simpl[wrld_simpl$REGION == 2, ]

# We can visualize the region's boundaries with the plot function
plot(st_geometry(afr))
