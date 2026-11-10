# gloss bench figure gallery-017
# source: 264-control-ggplot2-boxplot-colors.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# library
library(ggplot2)

# The mtcars dataset is natively available in R
#head(mpg)
 
# Top Left: Set a unique color with fill, colour, and alpha
ggplot(mpg, aes(x=class, y=hwy)) + 
    geom_boxplot(color="red", fill="orange", alpha=0.2) +
    xlab("") + 
    theme(plot.margin=unit(c(2,2,2,2),"cm"))
 
# Top Right: Set a different color for each group with default color palette
ggplot(mpg, aes(x=class, y=hwy, fill=class)) + 
    geom_boxplot() +
    theme(legend.position="none") +
    xlab("") + 
    theme(plot.margin=unit(c(2,2,2,2),"cm"))
