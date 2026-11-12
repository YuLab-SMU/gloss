# gloss bench figure gallery-002
# source: package/ggbeeswarm.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE, fig.align='center')

data(iris)
iris <- do.call(rbind, replicate(4, iris, simplify = FALSE))
iris$Sepal.Length <- iris$Sepal.Length + rnorm(nrow(iris), 0, 0.2)
# ---- chunk 2 ----
library(ggplot2)
library(ggbeeswarm)

# Create a simple beeswarm plot
ggplot(iris, aes(x = Species, y = Sepal.Length, colour=Species)) +
  geom_beeswarm() +
  theme_minimal() +
  scale_color_manual(values = c("#00AFBB", "#E7B800", "#FC4E07"))
# ---- chunk 3 ----
# install.packages("ggbeeswarm") # [bench: install call removed]
# ---- chunk 4 ----
library(ggplot2)
library(ggbeeswarm)

ggplot(iris, aes(x = Species, y = Sepal.Length, colour=Species)) +
  geom_beeswarm()
# ---- chunk 5 ----
ggplot(iris, aes(x = Species, y = Sepal.Length, colour=Species)) +
  geom_beeswarm() +
  theme_minimal() +
  scale_color_manual(values = c("#00AFBB", "#E7B800", "#FC4E07"))
# ---- chunk 6 ----
ggplot(iris, aes(x = Species, y = Sepal.Length, colour=Species)) +
  geom_beeswarm(size=3) +
  theme_minimal()
# ---- chunk 7 ----
ggplot(iris, aes(x = Species, y = Sepal.Length, colour=Species)) +
  geom_beeswarm(method = "center") +
  theme_minimal()
