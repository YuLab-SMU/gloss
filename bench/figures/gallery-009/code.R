# gloss bench figure gallery-009
# source: line-chart-dual-Y-axis-ggplot2.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# Libraries
library(ggplot2)
library(dplyr)
library(patchwork) # To display 2 charts together
library(hrbrthemes)

# Build dummy data
data <- data.frame(
  day = as.Date("2019-01-01") + 0:99,
  temperature = runif(100) + seq(1,100)^2.5 / 10000,
  price = runif(100) + seq(100,1)^1.5 / 10
)

# Most basic line chart
p1 <- ggplot(data, aes(x=day, y=temperature)) +
  geom_line(color="#69b3a2", size=2) +
  ggtitle("Temperature: range 1-10") +
  theme_ipsum()
  
p2 <- ggplot(data, aes(x=day, y=price)) +
  geom_line(color="grey",size=2) +
  ggtitle("Price: range 1-100") +
  theme_ipsum()

# Display both charts side by side thanks to the patchwork package
p1 + p2
