# gloss bench figure gallery-064
# source: 240-custom-layout-background-ggplot2.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# Load ggplot2
library(ggplot2)

# Very basic chart
basic <- ggplot( mtcars , aes(x=mpg, y=wt)) +
  geom_point()
basic
