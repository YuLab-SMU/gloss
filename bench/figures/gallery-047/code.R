# gloss bench figure gallery-047
# source: package/hrbrthemes.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
library(ggplot2)
library(hrbrthemes)
ggplot(mtcars, aes(x=mpg, y=disp)) + geom_point() + theme_ipsum()
# ---- chunk 3 ----
# install.packages("hrbrthemes") # [bench: install call removed]
library(hrbrthemes)
library(ggplot2)
# ---- chunk 4 ----
ggplot(mtcars, aes(x=mpg, y=disp)) + geom_point() + theme_ipsum()
# ---- chunk 5 ----
ggplot(mtcars, aes(x=mpg, y=disp)) + geom_point() + theme_modern_rc()
