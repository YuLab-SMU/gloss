# gloss bench figure gallery-015
# source: 2d-density-plot-with-ggplot2.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# Library
library(tidyverse)
 
# Data
a <- data.frame( x=rnorm(20000, 10, 1.9), y=rnorm(20000, 10, 1.2) )
b <- data.frame( x=rnorm(20000, 14.5, 1.9), y=rnorm(20000, 14.5, 1.9) )
c <- data.frame( x=rnorm(20000, 9.5, 1.9), y=rnorm(20000, 15.5, 1.9) )
data <- rbind(a,b,c)
 
 
# Basic scatterplot
ggplot(data, aes(x=x, y=y) ) +
  geom_point()
# ---- chunk 3 ----
# ---- chunk 4 ----
# 2d histogram with default option
ggplot(data, aes(x=x, y=y) ) +
  geom_bin2d() +
  theme_bw()
 
# Bin size control + color palette
ggplot(data, aes(x=x, y=y) ) +
  geom_bin2d(bins = 70) +
  scale_fill_continuous(type = "viridis") +
  theme_bw()
# ---- chunk 5 ----
# ---- chunk 6 ----
# Hexbin chart with default option
ggplot(data, aes(x=x, y=y) ) +
  geom_hex() +
  theme_bw()
 
# Bin size control + color palette
ggplot(data, aes(x=x, y=y) ) +
  geom_hex(bins = 70) +
  scale_fill_continuous(type = "viridis") +
  theme_bw()
# ---- chunk 7 ----
# ---- chunk 8 ----
# Show the contour only
ggplot(data, aes(x=x, y=y) ) +
  geom_density_2d()
 
# Show the area only
ggplot(data, aes(x=x, y=y) ) +
  stat_density_2d(aes(fill = ..level..), geom = "polygon")
 
# Area + contour
ggplot(data, aes(x=x, y=y) ) +
  stat_density_2d(aes(fill = ..level..), geom = "polygon", colour="white")
 
# Using raster
ggplot(data, aes(x=x, y=y) ) +
  stat_density_2d(aes(fill = ..density..), geom = "raster", contour = FALSE) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  theme(
    legend.position='none'
  )
# ---- chunk 9 ----
# ---- chunk 10 ----
# Call the palette with a number
ggplot(data, aes(x=x, y=y) ) +
  stat_density_2d(aes(fill = ..density..), geom = "raster", contour = FALSE) +
  scale_fill_distiller(palette=4, direction=-1) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  theme(
    legend.position='none'
  )
 
# The direction argument allows to reverse the palette
ggplot(data, aes(x=x, y=y) ) +
  stat_density_2d(aes(fill = ..density..), geom = "raster", contour = FALSE) +
  scale_fill_distiller(palette=4, direction=1) +
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  theme(
    legend.position='none'
  )
