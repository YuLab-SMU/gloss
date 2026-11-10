# gloss bench figure exts-014
# source: plotROC (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(plotROC)
# ---- chunk 1 ----
### Name: geom_rocci
### Title: Confidence regions for the ROC curve
### Aliases: geom_rocci GeomRocci
### Keywords: datasets

### ** Examples


D.ex <- rbinom(50, 1, .5)
rocdata <- data.frame(D = c(D.ex, D.ex), 
                   M = c(rnorm(50, mean = D.ex, sd = .4), rnorm(50, mean = D.ex, sd = 1)), 
                   Z = c(rep("A", 50), rep("B", 50)))

ggplot(rocdata, aes(m = M, d = D)) + geom_roc() + geom_rocci()
ggplot(rocdata, aes(m = M, d = D, color = Z)) + geom_roc() + geom_rocci()
ggplot(rocdata, aes(m = M, d = D, color = Z)) + geom_roc() + geom_rocci(sig.level = .01)
