# gloss bench figure gallery-054
# source: package/geomtextpath.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
library(ggplot2)
library(geomtextpath)
library(hrbrthemes)

data(iris)
ggplot(iris, aes(x = Sepal.Length, colour = Species, label = Species)) +
  geom_textdensity(size = 6, fontface = 2, hjust = 0.2, vjust = 0.3) +
  theme(legend.position = "none") + theme_bw()
# ---- chunk 3 ----
# install.packages("geomtextpath") # [bench: install call removed]
# ---- chunk 4 ----
library(ggplot2)
library(geomtextpath)

t = seq(5, -1, length.out = 1000) * pi
spiral = data.frame(x    = sin(t) * 1:1000, 
                    y    = cos(t) * 1:1000,
                    text = paste("From elegant bar charts to mesmerizing scatterplots,",
                                 "crafting stunning visualizations in R is powerful,",
                                 "you can bring your data to life, revealing insights.")
                     )

ggplot(spiral, aes(x, y, label = text)) +
  geom_textpath(size = 5, vjust = 1, text_only = TRUE)
# ---- chunk 5 ----
ggplot(spiral, aes(x, y, label = text)) + 
  geom_labelpath(size = 5, fill = "#F6F6FF", hjust = 0.55)
# ---- chunk 6 ----
library(hrbrthemes)
data(iris)

ggplot(iris, aes(x = Sepal.Length, colour = Species, label = Species)) +
  geom_textdensity(size = 6, fontface = 2, vjust = -0.4, hjust = "ymid") +
  theme(legend.position = "none") + theme_bw()
# ---- chunk 7 ----
data(iris)

ggplot(iris, aes(x = Sepal.Length, y = Petal.Length, color = Species)) +
  geom_point() +
  geom_labelsmooth(aes(label = Species), fill = "black",
                method = "loess", formula = y ~ x,
                size = 4, linewidth = 1, boxlinewidth = 0.3) +
  theme_bw() + guides(color = 'none') # remove legend
# ---- chunk 8 ----
data(mtcars)

ggplot(mtcars, aes(mpg, disp)) + 
  geom_point() + 
  geom_texthline(yintercept = 200, label = "displacement threshold", 
                 hjust = 0.8, color = "red") +
  geom_textvline(xintercept = 20, label = "consumption threshold", hjust = 0.8,
                 linetype = 2, vjust = 1.3, color = "blue") +
  geom_textabline(slope = 15, intercept = -100, label = "partition line", 
                  color = "green3", hjust = 0.6, vjust = -0.2)
# ---- chunk 9 ----
df = data.frame(x = rnorm(n=100, mean=10),
                y = rnorm(n=100, mean=10))

ggplot(df, aes(x, y)) + 
  geom_labeldensity2d() + theme_bw()
