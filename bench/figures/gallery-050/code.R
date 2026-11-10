# gloss bench figure gallery-050
# source: 354-highlight-specific-elements-in-line-chart.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set( warning=FALSE, message=FALSE)
# ---- chunk 2 ----
# dataset with 3 lines named "a", "b" and "c"
set.seed(1)
period = 100
df = data.frame(Date = seq(as.Date("2020-01-01"),
                           by = "day",
                           length.out = period), 
                Value = c(cumsum(rnorm(period)),
                          cumsum(rnorm(period)),
                          cumsum(rnorm(period))),
                Type = c(rep("a", period),
                         rep("b", period),
                         rep("c", period)))
# ---- chunk 3 ----
# Install the packages if not already done
# # install.packages("ggplot2") # [bench: install call removed]
# # install.packages("gghighlight") # [bench: install call removed]

# Load the package
library(ggplot2)
library(gghighlight)
# ---- chunk 4 ----
ggplot(df) +
  geom_line(aes(Date, Value, colour = Type))
