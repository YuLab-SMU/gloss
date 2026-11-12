# gloss bench figure gallery-059
# source: package/gghighlight.Rmd (gallery)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- chunk 1 ----
knitr::opts_chunk$set(warning = FALSE, message = FALSE)
# ---- chunk 2 ----
library(ggplot2)
library(gghighlight)

set.seed(123)
period <- 365
df <- data.frame(
  Date = seq(as.Date("2020-01-01"),
    by = "day",
    length.out = period
  ),
  Value = c(
    cumsum(rnorm(period)),
    cumsum(rnorm(period)),
    cumsum(rnorm(period))
  ),
  Type = c(
    rep("a", period),
    rep("b", period),
    rep("c", period)
  )
)

ggplot(df) +
  geom_line(aes(Date, Value, colour = Type)) +
  gghighlight(max(Value) > 15)
