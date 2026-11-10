# gloss bench figure gallery-008
# source: 98-basic-scatterplot-matrix.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# Data: numeric variables of the native mtcars dataset
data <- mtcars[ , c(1,3:6)]
 
# Plot
plot(data , pch=20 , cex=1.5 , col="#69b3a2")
