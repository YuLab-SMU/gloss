# gloss bench figure gallery-067
# source: 27-levelplot-with-lattice.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# Load the lattice package
library("lattice")
 
# Dummy data
x <- seq(1,10, length.out=20)
y <- seq(1,10, length.out=20)
data <- expand.grid(X=x, Y=y)
data$Z <- runif(400, 0, 5)

## Try it out
levelplot(Z ~ X*Y, data=data  ,xlab="X",
          main="")
# ---- chunk 3 ----
# ---- chunk 4 ----
# Load the library
library("lattice")
 
# Dummy data
data <- matrix(runif(100, 0, 5) , 10 , 10)
colnames(data) <- letters[c(1:10)]
rownames(data) <- paste( rep("row",10) , c(1:10) , sep=" ")
 
# plot it flipping the axis
levelplot(data)
# ---- chunk 5 ----
# ---- chunk 6 ----
# Load the library
library("lattice")
 
# Dummy data
data <- matrix(runif(100, 0, 5) , 10 , 10)
colnames(data) <- letters[c(1:10)]
rownames(data) <- paste( rep("row",10) , c(1:10) , sep=" ")
 
# plot it flipping the axis
levelplot( t(data[c(nrow(data):1) , ]),
           col.regions=heat.colors(100))
# ---- chunk 7 ----
# ---- chunk 8 ----
# Lattice package
require(lattice)

# The volcano dataset is provided, it looks like that:
#head(volcano)

# 1: native palette from R
levelplot(volcano, col.regions = terrain.colors(100)) # try cm.colors() or terrain.colors()

# 2: Rcolorbrewer palette
library(RColorBrewer)
coul <- colorRampPalette(brewer.pal(8, "PiYG"))(25)
levelplot(volcano, col.regions = coul) # try cm.colors() or terrain.colors()

# 3: Viridis
library(viridisLite)
coul <- viridis(100)
