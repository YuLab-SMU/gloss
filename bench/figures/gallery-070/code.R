# gloss bench figure gallery-070
# source: 238-custom-layout-axis-ggplot2.Rmd (gallery)
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
# ---- chunk 3 ----
# ---- chunk 4 ----
basic+
    xlab("mpg value") + 
    xlim(0,50)
# ---- chunk 5 ----
# ---- chunk 6 ----
# Left -> both axis are modified
basic + theme(axis.title = element_text( angle = 90, color="red", size=15, face=3)) # face = title location
# ---- chunk 7 ----
# Right -> only the x axis is modified
basic + theme(axis.title.x = element_text( angle = 90, color="red", size=15, face=3))
# ---- chunk 8 ----
# ---- chunk 9 ----
# ---- chunk 10 ----
basic + 
  theme(axis.text = element_text( 
    angle = 90, 
    color="blue", 
    size=15, 
    face=3)
  )
# ---- chunk 11 ----
# ---- chunk 12 ----
# chart 1: ticks
basic + theme(
   axis.ticks = element_line(size = 2, color="red") , 
   axis.ticks.length = unit(.5, "cm")
)
