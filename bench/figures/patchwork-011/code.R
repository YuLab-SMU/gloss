# gloss bench figure patchwork-011
# source: package/sf.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set(
  warning=FALSE,
  message=FALSE,
  fig.align='center'
)
# ---- chunk 2 ----
library(sf)
nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
plot(nc[1])
# ---- chunk 3 ----
# install.packages("sf") # [bench: install call removed]
# ---- chunk 4 ----
library(sf)
nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
plot(st_geometry(nc), col = "lightblue", border = "black", lwd = 1.2, main = "North Carolina")
# ---- chunk 5 ----
library(sf)
library(ggplot2)

# Read the shapefile
nc = st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)

# Create the plot using ggplot2
ggplot() +
  geom_sf(data = nc, aes(fill = AREA)) +
  scale_fill_viridis_c() +
  ggtitle('Choropleth Map of North Carolina') +
  theme_minimal()
# ---- chunk 6 ----
library(maps)
library(sf)
library(ggplot2)
library(patchwork)

# create a map of the USA
usa = st_as_sf(map('usa', plot = FALSE, fill = TRUE))
laea = st_crs("+proj=laea +lat_0=30 +lon_0=-95") # Lambert equal area projection
usa2 <- st_transform(usa, laea)

# create ggplot objects with graticules
p1 = ggplot(data = usa) + 
  geom_sf() + 
  theme_minimal()

p2 = ggplot(data = usa2) + 
  geom_sf() + 
  theme_minimal()

# combine plots with patchwork
p1 + p2
