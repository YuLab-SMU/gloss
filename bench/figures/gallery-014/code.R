# gloss bench figure gallery-014
# source: 362-scatter-plot-with-trend-line-and-labels.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# Install the packages if not already done
# # install.packages("ggplot2") # [bench: install call removed]
# # install.packages("geomtextpath") # [bench: install call removed]

# Load the package
library(ggplot2)
library(geomtextpath)
# ---- chunk 3 ----
data(iris)

ggplot(iris, aes(x = Sepal.Length, y = Sepal.Width)) +
  geom_point() +
  theme(legend.position = "none")
# ---- chunk 4 ----
library(hrbrthemes)
data(iris)

ggplot(iris, aes(x = Sepal.Length, y = Sepal.Width)) +
  geom_point() +
  geom_labelsmooth(aes(label = 'My Label'), fill = "white",
                method = "lm", formula = y ~ x,
                size = 6, linewidth = 2, boxlinewidth = 0.6) +
  theme_bw() + guides(color = 'none') # remove legend
# ---- chunk 5 ----
library(hrbrthemes)
data(iris)

ggplot(iris, aes(x = Sepal.Length, y = Petal.Length, color = Species)) +
  geom_point() +
  geom_labelsmooth(aes(label = Species), fill = "white",
                method = "lm", formula = y ~ x,
                size = 3, linewidth = 1, boxlinewidth = 0.4) +
  theme_bw() + guides(color = 'none') # remove legend
