# gloss bench figure exts-030
# source: ggstatsplot (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(ggstatsplot)
# ---- chunk 1 ----
### Name: ggcorrmat
### Title: Visualization of a correlation matrix
### Aliases: ggcorrmat

### ** Examples

set.seed(123)
ggcorrmat(iris)

# with data containing NAs (uses pairwise complete observations)
ggcorrmat(airquality)

# selecting specific variables
ggcorrmat(iris, cor.vars = c(Sepal.Length, Petal.Length, Petal.Width))
