# gloss bench figure gallery-011
# source: 273-custom-your-scatterplot-ggplot2.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# library
library(ggplot2)
 
# Iris dataset is natively provided by R
#head(iris)
 
# use options!
ggplot(iris, aes(x=Sepal.Length, y=Sepal.Width)) + 
    geom_point(
        color="orange",
        fill="#69b3a2",
        shape=21,
        alpha=0.5,
        size=6,
        stroke = 2
        )
# ---- chunk 3 ----
# library
library(ggplot2)
 
# Iris dataset is natively provided by R
#head(iris)
 
# use options!
ggplot(iris, aes(x=Sepal.Length, y=Sepal.Width)) + 
    geom_point(
        color="orange",
        fill="#69b3a2",
        shape=21,
        alpha=0.5,
        size=6,
        stroke = 2
        )
# ---- chunk 4 ----
# library
library(ggplot2)
library(hrbrthemes)

# Iris dataset is natively provided by R
#head(iris)
 
# use options!
ggplot(iris, aes(x=Sepal.Length, y=Sepal.Width)) + 
    geom_point(
        color="black",
        fill="#69b3a2",
        shape=22,
        alpha=0.5,
        size=6,
        stroke = 1
        ) +
    theme_ipsum()
