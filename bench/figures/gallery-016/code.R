# gloss bench figure gallery-016
# source: 263-ggplot2-boxplot-parameters.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# Load ggplot2
library(ggplot2)
 
# The mpg dataset is natively available
#head(mpg)
 
# geom_boxplot proposes several arguments to custom appearance
ggplot(mpg, aes(x=class, y=hwy)) + 
    geom_boxplot(
        
        # custom boxes
        color="blue",
        fill="blue",
        alpha=0.2,
        
        # Notch?
        notch=TRUE,
        notchwidth = 0.8,
        
        # custom outliers
        outlier.colour="red",
        outlier.fill="red",
        outlier.size=3
    
    ) +
    xlab("")
# ---- chunk 3 ----
# Load ggplot2
library(ggplot2)
 
# The mpg dataset is natively available
#head(mpg)
 
# geom_boxplot proposes several arguments to custom appearance
ggplot(mpg, aes(x=class, y=hwy)) + 
    geom_boxplot(
        
        # custom boxes
        color="blue",
        fill="blue",
        alpha=0.2,
        
        # Notch?
        notch=TRUE,
        notchwidth = 0.8,
        
        # custom outliers
        outlier.colour="red",
        outlier.fill="red",
        outlier.size=3
    
    )
