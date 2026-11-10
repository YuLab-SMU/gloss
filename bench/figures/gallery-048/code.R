# gloss bench figure gallery-048
# source: 314-custom-circle-packing-with-several-levels.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# Libraries
library(ggraph)
library(igraph)
library(tidyverse)
library(viridis)
 
# We need a data frame giving a hierarchical structure. Let's consider the flare dataset:
edges <- flare$edges
vertices <- flare$vertices
mygraph <- graph_from_data_frame( edges, vertices=vertices )
 
# Control the size of each circle: (use the size column of the vertices data frame)
ggraph(mygraph, layout = 'circlepack', weight=size) + 
  geom_node_circle() +
  theme_void()
