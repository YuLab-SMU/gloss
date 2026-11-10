# gloss bench figure gallery-006
# source: 274-map-a-variable-to-ggplot2-scatterplot.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# load ggplot2
library(ggplot2)
library(hrbrthemes)

# mtcars dataset is natively available in R
# head(mtcars)
 
# A basic scatterplot with color depending on Species
ggplot(iris, aes(x=Sepal.Length, y=Sepal.Width, color=Species)) + 
    geom_point(size=6) +
    theme_ipsum()
# ---- chunk 3 ----
# Transparency
ggplot(iris, aes(x=Sepal.Length, y=Sepal.Width, alpha=Species)) + 
    geom_point(size=6, color="#69b3a2") +
    ggtitle("Transparency") +
    theme_ipsum()

# Shape
ggplot(iris, aes(x=Sepal.Length, y=Sepal.Width, shape=Species)) + 
    geom_point(size=6, color="lightblue") +
    ggtitle("Shape") +
    theme_ipsum()

# Size
ggplot(iris, aes(x=Sepal.Length, y=Sepal.Width, size=Petal.Width)) + 
    geom_point(color="darkred") +
    ggtitle("Size") +
    theme_ipsum()
# ---- chunk 4 ----
# Transparency
ggplot(iris, aes(x=Sepal.Length, y=Sepal.Width, alpha=Species)) + 
    geom_point(size=6, color="#69b3a2") +
    ggtitle("Transparency") +
    theme_ipsum()

# Shape
ggplot(iris, aes(x=Sepal.Length, y=Sepal.Width, shape=Species)) + 
    geom_point(size=6, color="lightblue") +
    ggtitle("Shape") +
    theme_ipsum()
