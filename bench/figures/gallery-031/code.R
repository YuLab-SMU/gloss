# gloss bench figure gallery-031
# source: line-chart-ggplot2.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# Libraries
library(ggplot2)

# create data
xValue <- 1:10
yValue <- cumsum(rnorm(10))
data <- data.frame(xValue,yValue)

# Plot
ggplot(data, aes(x=xValue, y=yValue)) +
  geom_line()
# ---- chunk 3 ----
# ---- chunk 4 ----
# Libraries
library(ggplot2)
library(hrbrthemes)

# create data
xValue <- 1:10
yValue <- cumsum(rnorm(10))
data <- data.frame(xValue,yValue)

# Plot
ggplot(data, aes(x=xValue, y=yValue)) +
  geom_line( color="#69b3a2", size=2, alpha=0.9, linetype=2) +
  theme_ipsum() +
  ggtitle("Evolution of something")
