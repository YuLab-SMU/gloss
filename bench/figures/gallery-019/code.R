# gloss bench figure gallery-019
# source: 373-basic-beeswarm-with-ggbeeswarm.Rmd (gallery)
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
iris <- do.call(rbind, replicate(4, iris, simplify = FALSE))
iris$Sepal.Length <- iris$Sepal.Length + rnorm(nrow(iris), 0, 0.2)
# ---- chunk 5 ----
ggplot(iris,aes(y=Sepal.Length,x='')) +
  geom_beeswarm()
# ---- chunk 6 ----
ggplot(iris,aes(x=Sepal.Length,y='')) +
  geom_beeswarm()
# ---- chunk 7 ----
ggplot(iris,aes(y=Sepal.Length,x='')) +
  geom_beeswarm(color='blue') +
  theme_minimal()
# ---- chunk 8 ----
ggplot(iris,aes(y=Sepal.Length,x='')) +
  geom_beeswarm(method='center')
