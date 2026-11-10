# gloss bench figure exts-029
# source: ggpage (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggpage)
# ---- chunk 1 ----
### Name: ggpage_plot
### Title: Creates a visualization from the ggpage_build output
### Aliases: ggpage_plot

### ** Examples

## No test: 
library(dplyr)
library(stringr)
library(ggplot2)
library(tidytext)
library(ggpage)
# build and plot
## data.frame with full lines
ggpage_build(tinderbox) %>%
  ggpage_plot()
## vector with full lines
ggpage_build(book = tinderbox %>%
  pull(text)) %>%
  ggpage_plot()
## data.frame with single words
ggpage_build(tinderbox) %>%
  unnest_tokens(text, word) %>%
  ggpage_plot()
