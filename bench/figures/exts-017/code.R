# gloss bench figure exts-017
# source: tidyterra (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(tidyterra)
# ---- chunk 1 ----
### Name: geom_spatraster_rgb
### Title: Plot 'SpatRaster' objects as images
### Aliases: geom_spatraster_rgb

### ** Examples

## No test: 

# Tile of Castile and Leon (Spain) from OpenStreetMap
file_path <- system.file("extdata/cyl_tile.tif", package = "tidyterra")

library(terra)
tile <- rast(file_path)

library(ggplot2)

ggplot() +
  geom_spatraster_rgb(data = tile) +
  # You can use coord_sf
  coord_sf(crs = 3035)
