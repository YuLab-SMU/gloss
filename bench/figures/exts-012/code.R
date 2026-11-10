# gloss bench figure exts-012
# source: directlabels (examples)
# Frozen by bench/R/harvest.R: code up to the chosen figure; see meta.json.
# ---- setup ----
library(directlabels)
# ---- chunk 1 ----
### Name: prostate
### Title: Prostate Cancer Data
### Aliases: prostate
### Keywords: datasets

### ** Examples


str( prostate )
cor( prostate[,1:8] )
pairs( prostate[,1:9], col="violet" )
train <- subset( prostate, train==TRUE )[,1:9]
test  <- subset( prostate, train=FALSE )[,1:9]
