# gloss bench figure gallery-068
# source: 374-grouped-beeswarm-with-ggbeeswarm.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE, fig.align='center')
# ---- chunk 2 ----
# # install.packages("ggbeeswarm") # [bench: install call removed]
library(ggbeeswarm)
library(ggplot2)
# ---- chunk 3 ----
data(iris)
# ---- chunk 4 ----
ggplot(iris,aes(x=Species, y=Sepal.Length)) +
  geom_beeswarm()
